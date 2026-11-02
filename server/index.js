const crypto = require("node:crypto");
const express = require("express");
const axios = require("axios");
const cors = require("cors");
const admin = require("firebase-admin");
const cron = require("node-cron");

const app = express();
app.use(cors());
// Keep the raw bytes: Paystack signs the RAW body, not re-serialised JSON.
app.use(
  express.json({
    verify: (req, _res, buf) => {
      req.rawBody = buf;
    },
  })
);

// ── Firebase Admin ────────────────────────────────────────────────────────
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

// ── Paystack config ───────────────────────────────────────────────────────
const PAYSTACK_SECRET_KEY = process.env.PAYSTACK_SECRET_KEY;
// Render sets RENDER_EXTERNAL_URL automatically; SERVER_URL overrides it.
const SERVER_URL = (process.env.SERVER_URL || process.env.RENDER_EXTERNAL_URL || "").replace(/\/$/, "");

const DUES = { admin: 30, member: 20 };

const paystack = axios.create({
  baseURL: "https://api.paystack.co",
  headers: {
    Authorization: `Bearer ${PAYSTACK_SECRET_KEY}`,
    "Content-Type": "application/json",
  },
  timeout: 20000,
});

// ── Helpers ───────────────────────────────────────────────────────────────
const safeSemesterId = (uid, semester) =>
  `${uid}_${semester.replace(/\//g, "-").replace(/ /g, "_")}`;

const DAY_MS = 24 * 60 * 60 * 1000;
const newReference = (prefix) =>
  `${prefix}-${Date.now()}-${crypto.randomBytes(5).toString("hex")}`;

// Works for Firestore Timestamps AND ISO strings. A deadline saved at exactly
// 00:00:00 is treated as the END of that day.
const toDateSafe = (v) => {
  if (!v) return null;
  const d = typeof v.toDate === "function" ? v.toDate() : new Date(v);
  if (isNaN(d.getTime())) return null;
  if (d.getUTCHours() === 0 && d.getUTCMinutes() === 0 && d.getUTCSeconds() === 0) {
    d.setUTCHours(23, 59, 59, 0);
  }
  return d;
};

/** Start a Paystack checkout. Amount is in GHS; Paystack wants pesewas. */
async function initPaystack({ email, amountGhs, reference, callbackUrl, metadata }) {
  const r = await paystack.post("/transaction/initialize", {
    email,
    amount: Math.round(Number(amountGhs) * 100),
    currency: "GHS",
    reference,
    callback_url: callbackUrl,
    channels: ["mobile_money", "card"],
    metadata,
  });
  const data = r.data?.data;
  if (!r.data?.status || !data?.authorization_url)
    throw new Error(r.data?.message || "Paystack did not return a checkout link");
  return data; // { authorization_url, access_code, reference }
}

// ── Admin guard: the app sends the Firebase ID token with admin requests ──
async function requireAdmin(req, res, next) {
  try {
    const header = req.headers.authorization || "";
    const token = header.startsWith("Bearer ") ? header.slice(7) : null;
    if (!token) return res.status(401).json({ success: false, message: "Not signed in" });

    const decoded = await admin.auth().verifyIdToken(token);
    const snap = await db.collection("users").doc(decoded.uid).get();
    const u = snap.data() || {};
    if (!(u.isAdmin === true || u.role === "admin"))
      return res.status(403).json({ success: false, message: "Admins only" });

    req.adminUid = decoded.uid;
    next();
  } catch (err) {
    console.error("requireAdmin error:", err.message);
    return res.status(401).json({ success: false, message: "Invalid session" });
  }
}

// ── Health check (also used by the keep-awake pinger) ─────────────────────
app.get("/", (req, res) => res.json({ status: "Asempa backend running" }));

// ══════════════════════════════════════════════════════════════════════════
// SHARED: checkout redirect, payment processing, verification
// ══════════════════════════════════════════════════════════════════════════

// The app opens /checkout/:ref or /donations/checkout/:ref in the browser.
// We look up the Paystack link we stored and send the user there.
async function redirectToCheckout(req, res) {
  try {
    const { reference } = req.params;
    const [donationSnap, duesSnap] = await Promise.all([
      db.collection("donation_pending").where("paymentReference", "==", reference).limit(1).get(),
      db.collection("dues_payments").where("paymentReference", "==", reference).limit(1).get(),
    ]);
    const doc = !donationSnap.empty ? donationSnap.docs[0] : !duesSnap.empty ? duesSnap.docs[0] : null;
    const url = doc?.data()?.authorizationUrl;
    if (!url) return res.status(404).send("Payment link not found. Please try again.");
    return res.redirect(url);
  } catch (err) {
    console.error("checkout redirect error:", err.message);
    return res.status(500).send("Checkout failed. Please try again.");
  }
}
app.get("/checkout/:reference", redirectToCheckout);
app.get("/donations/checkout/:reference", redirectToCheckout);

/**
 * Credit a successful payment exactly once. Safe to call from the webhook,
 * the verify endpoint, the success page and the reconcile job.
 */
async function processPaidReference(reference, paidAmount) {
  const [donationSnap, duesSnap] = await Promise.all([
    db.collection("donation_pending").where("paymentReference", "==", reference).limit(1).get(),
    db.collection("dues_payments").where("paymentReference", "==", reference).limit(1).get(),
  ]);

  if (donationSnap.empty && duesSnap.empty) return { unknown: true };

  const isDonation = !donationSnap.empty;
  const pendingDoc = isDonation ? donationSnap.docs[0] : duesSnap.docs[0];

  // Atomically claim it, so webhook + verify racing can never double-count.
  const claimed = await db.runTransaction(async (t) => {
    const snap = await t.get(pendingDoc.ref);
    if (snap.data().status === "completed") return false;
    t.update(pendingDoc.ref, {
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (!claimed) return { already: true };

  try {
    const { uid, campaignId, semester } = pendingDoc.data();
    const userDoc  = await db.collection("users").doc(uid).get();
    const userData = userDoc.data() || {};
    const userName = userData.name ?? userData.fullName ?? "";

    // ── Donation ────────────────────────────────────────────────────
    if (isDonation) {
      const campaignRef = db.collection("donation_campaigns").doc(campaignId);
      await db.runTransaction(async (t) => {
        const campaignDoc = await t.get(campaignRef);
        if (!campaignDoc.exists) throw new Error("Campaign not found");

        t.update(campaignRef, {
          amountRaised: FieldValue.increment(paidAmount),
          donorCount:   FieldValue.increment(1),
        });
        t.set(db.collection("donations").doc(), {
          uid, campaignId,
          amount:           paidAmount,
          name:             userName,
          voicePart:        userData.voicePart ?? "",
          paymentReference: reference,
          donatedAt:        FieldValue.serverTimestamp(),
        });
      });
      console.log(`🙏 Donation recorded: uid=${uid} campaign=${campaignId} amount=${paidAmount}`);
      return { processed: true, type: "donation" };
    }

    // ── Dues ────────────────────────────────────────────────────────
    const isAdmin      = userData.isAdmin === true;
    const required     = isAdmin ? DUES.admin : DUES.member;
    const duesRef      = db.collection("dues").doc(safeSemesterId(uid, semester));
    const duesDoc      = await duesRef.get();
    const previousPaid = duesDoc.exists ? duesDoc.data().amountPaid ?? 0 : 0;
    const newTotal     = previousPaid + paidAmount;

    await duesRef.set({
      uid, semester, amountPaid: newTotal,
      amountRequired: required,
      isPaid: newTotal >= required,
      lastPaymentAt: FieldValue.serverTimestamp(),
      role:      isAdmin ? "admin" : "member",
      name:      userName,
      voicePart: userData.voicePart ?? "",
    }, { merge: true });

    console.log(`✅ Dues credited: uid=${uid} semester=${semester} amount=${paidAmount}`);
    return { processed: true, type: "dues" };
  } catch (err) {
    // Crediting failed: release the claim so a retry can try again.
    await pendingDoc.ref.update({ status: "pending" }).catch(() => {});
    throw err;
  }
}

/** Ask Paystack for the truth about a reference, and credit it if paid. */
async function verifyAndProcess(reference) {
  const r = await paystack.get(`/transaction/verify/${encodeURIComponent(reference)}`);
  const tx = r.data?.data;
  if (!tx) return { status: "unknown" };

  const amount = (tx.amount ?? 0) / 100;
  if (tx.status !== "success") return { status: tx.status, amount };
  if (tx.currency && tx.currency !== "GHS") return { status: "wrong-currency", amount };

  const result = await processPaidReference(reference, amount);
  return { status: "success", amount, ...result };
}

// ══════════════════════════════════════════════════════════════════════════
// DUES
// ══════════════════════════════════════════════════════════════════════════

app.post("/create-payment", async (req, res) => {
  try {
    const { uid, semester } = req.body;
    if (!uid || !semester)
      return res.status(400).json({ success: false, message: "uid and semester required" });

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists)
      return res.status(404).json({ success: false, message: "User not found" });

    const user    = userDoc.data();
    const isAdmin = user.isAdmin === true;
    const amount  = isAdmin ? DUES.admin : DUES.member;
    const reference = newReference("DUES");

    const tx = await initPaystack({
      email: user.email || `${uid}@asempachoir.app`,
      amountGhs: amount,
      reference,
      callbackUrl: `${SERVER_URL}/payment-success`,
      metadata: {
        uid, semester, type: "dues",
        role: isAdmin ? "admin" : "member",
        customer_name: user.name ?? user.fullName ?? "Member",
      },
    });

    await db.collection("dues_payments").add({
      uid, semester, amount, role: isAdmin ? "admin" : "member",
      paymentReference: reference,
      authorizationUrl: tx.authorization_url,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference: reference, amount });
  } catch (err) {
    console.error("create-payment error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Payment creation failed" });
  }
});

const successPage = ({ icon, title, colour, text }) => `<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>${title}</title>
<style>body{font-family:-apple-system,sans-serif;background:#f5f5f5;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:20px}.card{background:white;border-radius:20px;padding:40px;box-shadow:0 4px 20px rgba(0,0,0,.08);max-width:400px;width:100%}.icon{font-size:64px;margin-bottom:16px}h1{color:${colour};font-size:24px;margin-bottom:8px}p{color:#666;font-size:15px;line-height:1.5}.note{margin-top:20px;font-size:13px;color:#999}</style>
</head><body><div class="card"><div class="icon">${icon}</div>
<h1>${title}</h1>
<p>${text}</p>
<p class="note">You can close this tab and return to the Asempa app.</p>
</div></body></html>`;

// Paystack sends the user back here with ?reference=... — we double-check the
// payment right away, so the app updates even if the webhook is late.
app.get("/payment-success", async (req, res) => {
  const ref = req.query.reference || req.query.trxref;
  if (ref) await verifyAndProcess(String(ref)).catch((e) => console.error("success verify:", e.message));
  res.send(successPage({
    icon: "✅", title: "Payment Successful!", colour: "#00C853",
    text: "Your dues have been received. Your record will be updated shortly.",
  }));
});

app.get("/donation-success", async (req, res) => {
  const ref = req.query.reference || req.query.trxref;
  if (ref) await verifyAndProcess(String(ref)).catch((e) => console.error("success verify:", e.message));
  res.send(successPage({
    icon: "🙏", title: "Thank You!", colour: "#E91E63",
    text: "Your donation has been received. God bless you for your generosity.",
  }));
});

app.get("/verify/:reference", async (req, res) => {
  try {
    const result = await verifyAndProcess(req.params.reference);
    return res.json({ success: true, status: result.status, amount: result.amount });
  } catch (err) {
    console.error("verify error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Verification failed" });
  }
});

// ══════════════════════════════════════════════════════════════════════════
// DONATION CAMPAIGN ENDPOINTS
// ══════════════════════════════════════════════════════════════════════════

// Create campaign (admin only)
app.post("/donations/campaign", requireAdmin, async (req, res) => {
  try {
    const { name, description, targetAmount, deadline, isActive } = req.body;
    const target = Number(targetAmount);
    if (!name || !target || target < 1)
      return res.status(400).json({ success: false, message: "name and a valid targetAmount required" });

    const deadlineDate = deadline ? new Date(deadline) : null;
    if (deadlineDate && isNaN(deadlineDate.getTime()))
      return res.status(400).json({ success: false, message: "Invalid deadline" });

    const ref = await db.collection("donation_campaigns").add({
      name,
      description: description ?? "",
      targetAmount: target,
      deadline: deadlineDate ? Timestamp.fromDate(deadlineDate) : null,
      amountRaised: 0,
      donorCount: 0,
      isActive: isActive !== false,
      remindersSent: [],
      createdBy: req.adminUid,
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, campaignId: ref.id });
  } catch (err) {
    console.error("donations/campaign error:", err.message);
    return res.status(500).json({ success: false, message: "Campaign creation failed" });
  }
});

// Edit campaign (admin only) — only whitelisted fields can change
app.patch("/donations/campaign/:id", requireAdmin, async (req, res) => {
  try {
    const update = {};
    for (const k of ["name", "description", "targetAmount", "isActive", "deadline"]) {
      if (k in req.body) update[k] = req.body[k];
    }

    if ("targetAmount" in update) {
      update.targetAmount = Number(update.targetAmount);
      if (!(update.targetAmount >= 1))
        return res.status(400).json({ success: false, message: "Invalid targetAmount" });
    }
    if ("deadline" in update) {
      if (update.deadline) {
        const d = new Date(update.deadline);
        if (isNaN(d.getTime()))
          return res.status(400).json({ success: false, message: "Invalid deadline" });
        update.deadline = Timestamp.fromDate(d);
      } else {
        update.deadline = null;
      }
      update.remindersSent = []; // new deadline -> reminder schedule restarts
    }
    if (Object.keys(update).length === 0)
      return res.status(400).json({ success: false, message: "Nothing to update" });

    update.updatedAt = FieldValue.serverTimestamp();
    await db.collection("donation_campaigns").doc(req.params.id).update(update);
    return res.json({ success: true });
  } catch (err) {
    console.error("donations/campaign patch error:", err.message);
    return res.status(500).json({ success: false, message: "Update failed" });
  }
});

// Delete campaign (admin only). Donation records are kept for your accounts.
app.delete("/donations/campaign/:id", requireAdmin, async (req, res) => {
  try {
    await db.collection("donation_campaigns").doc(req.params.id).delete();
    return res.json({ success: true });
  } catch (err) {
    console.error("donations/campaign delete error:", err.message);
    return res.status(500).json({ success: false, message: "Delete failed" });
  }
});

// Manual "Remind" button (admin only)
app.post("/donations/campaign/:id/remind", requireAdmin, async (req, res) => {
  try {
    const doc = await db.collection("donation_campaigns").doc(req.params.id).get();
    if (!doc.exists)
      return res.status(404).json({ success: false, message: "Campaign not found" });
    const sent = await remindCampaign(doc);
    return res.json({ success: true, sent });
  } catch (err) {
    console.error("donations remind error:", err.message);
    return res.status(500).json({ success: false, message: "Could not send reminders" });
  }
});

// Member starts a donation
app.post("/donations/pay", async (req, res) => {
  try {
    const { uid, campaignId } = req.body;
    const amount = Number(req.body.amount);
    if (!uid || !campaignId || !Number.isFinite(amount) || amount < 1 || amount > 10000)
      return res.status(400).json({ success: false, message: "uid, campaignId and an amount between 1 and 10,000 required" });

    const userDoc     = await db.collection("users").doc(uid).get();
    const campaignDoc = await db.collection("donation_campaigns").doc(campaignId).get();
    if (!userDoc.exists)
      return res.status(404).json({ success: false, message: "User not found" });
    if (!campaignDoc.exists)
      return res.status(404).json({ success: false, message: "Campaign not found" });

    const user     = userDoc.data();
    const campaign = campaignDoc.data();

    // Enforce closed / ended campaigns on the server too
    if (campaign.isActive === false)
      return res.status(400).json({ success: false, message: "This campaign is closed" });
    const deadline = toDateSafe(campaign.deadline);
    if (deadline && new Date() > deadline)
      return res.status(400).json({ success: false, message: "This campaign has ended" });

    const reference = newReference("DON");
    const tx = await initPaystack({
      email: user.email || `${uid}@asempachoir.app`,
      amountGhs: amount,
      reference,
      callbackUrl: `${SERVER_URL}/donation-success`,
      metadata: {
        uid, campaignId, type: "donation",
        campaign_name: campaign.name,
        customer_name: user.name ?? user.fullName ?? "Member",
      },
    });

    await db.collection("donation_pending").add({
      uid, campaignId, amount,
      paymentReference: reference,
      authorizationUrl: tx.authorization_url,
      status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference: reference, amount });
  } catch (err) {
    console.error("donations/pay error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Donation payment creation failed" });
  }
});

// ══════════════════════════════════════════════════════════════════════════
// DONATION REMINDERS
// ══════════════════════════════════════════════════════════════════════════

const money = (n) => "GHS " + Math.round(n).toLocaleString("en-US");

function reminderMessage(c, daysLeft) {
  const progress = `${money(c.amountRaised || 0)} of ${money(c.targetAmount || 0)} raised.`;
  if (daysLeft === 0) return { title: `⏰ Last day: ${c.name}`, body: `Ends tonight! ${progress} Tap to give.` };
  if (daysLeft === 1) return { title: `⏳ 1 day left: ${c.name}`, body: `Ends tomorrow. ${progress}` };
  if (daysLeft == null) return { title: `💝 ${c.name}`, body: `${progress} Every gift counts.` };
  return { title: `⏳ ${daysLeft} days left: ${c.name}`, body: `${progress} Every gift counts.` };
}

/** Push to every approved, active member who has NOT donated to this campaign. */
async function remindCampaign(campaignDoc, daysLeft = null) {
  const c = campaignDoc.data();

  // `donations` records are only written after a successful payment.
  const donationsSnap = await db.collection("donations")
    .where("campaignId", "==", campaignDoc.id).get();
  const donated = new Set(donationsSnap.docs.map((d) => d.data().uid));

  const usersSnap = await db.collection("users").where("isApproved", "==", true).get();
  const tokens = [];
  usersSnap.forEach((u) => {
    const d = u.data();
    if (d.isActive === false) return;   // deactivated member
    if (donated.has(u.id)) return;      // already gave -> skip
    if (d.fcmToken) tokens.push(d.fcmToken);
  });
  if (!tokens.length) return 0;

  const { title, body } = reminderMessage(c, daysLeft);
  let sent = 0;
  for (let i = 0; i < tokens.length; i += 500) {
    const r = await admin.messaging().sendEachForMulticast({
      tokens: tokens.slice(i, i + 500),
      notification: { title, body },
      data: { route: "/donations", campaignId: campaignDoc.id },
    });
    sent += r.successCount;
  }
  console.log(`🔔 Reminder "${c.name}" sent to ${sent}/${tokens.length}`);
  return sent;
}

// Remind 7, 3 and 1 days before the deadline, and on the last day.
const REMINDER_STAGES = [7, 3, 1, 0];
// Accra is UTC+0 all year, so UTC day maths matches local days.
const startOfDayUTC = (d) => Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate());

async function runDailyReminders() {
  const snap = await db.collection("donation_campaigns").where("isActive", "==", true).get();
  for (const doc of snap.docs) {
    const c = doc.data();
    const deadline = toDateSafe(c.deadline);
    if (!deadline || new Date() > deadline) continue;

    const daysLeft = Math.round((startOfDayUTC(deadline) - startOfDayUTC(new Date())) / DAY_MS);
    if (!REMINDER_STAGES.includes(daysLeft)) continue;
    if ((c.remindersSent || []).includes(daysLeft)) continue; // stage already sent

    try {
      await remindCampaign(doc, daysLeft);
      await doc.ref.update({ remindersSent: FieldValue.arrayUnion(daysLeft) });
    } catch (err) {
      console.error("Reminder failed for", doc.id, err.message);
    }
  }
}

/** Safety net: re-check recent pending payments in case a webhook was missed. */
async function reconcilePending() {
  const cutoff = Date.now() - 3 * DAY_MS;
  let checked = 0;
  for (const col of ["donation_pending", "dues_payments"]) {
    const snap = await db.collection(col).where("status", "==", "pending").limit(200).get();
    for (const doc of snap.docs) {
      const created = doc.data().createdAt?.toMillis?.() ?? 0;
      if (created < cutoff) continue;
      try {
        await verifyAndProcess(doc.data().paymentReference);
        checked++;
      } catch (err) {
        console.error("Reconcile failed for", doc.data().paymentReference, err.response?.data?.message ?? err.message);
      }
    }
  }
  return checked;
}

async function runDailyJobs() {
  await runDailyReminders();
  return reconcilePending();
}

// Every day at 09:00 Accra time (works while the server is awake)
cron.schedule("0 9 * * *", () => {
  runDailyJobs().catch((e) => console.error("Daily jobs error:", e.message));
}, { timezone: "Africa/Accra" });

// For an external scheduler (cron-job.org). Set CRON_SECRET in Render,
// then POST here with header  x-cron-secret: <your secret>
app.post("/donations/cron/run", async (req, res) => {
  if (!process.env.CRON_SECRET || req.headers["x-cron-secret"] !== process.env.CRON_SECRET)
    return res.status(403).json({ success: false });
  try {
    const checked = await runDailyJobs();
    return res.json({ success: true, reconciled: checked });
  } catch (err) {
    console.error("cron/run error:", err.message);
    return res.status(500).json({ success: false });
  }
});

// ══════════════════════════════════════════════════════════════════════════
// PAYSTACK WEBHOOK
//   Dashboard → Settings → API Keys & Webhooks → set the Webhook URL to
//   https://<your-render-url>/webhook
// ══════════════════════════════════════════════════════════════════════════

app.post("/webhook", async (req, res) => {
  try {
    const signature = req.headers["x-paystack-signature"];
    if (!signature || !req.rawBody)
      return res.status(401).json({ success: false, message: "No signature" });

    // Paystack signs the RAW body with HMAC-SHA512 using your secret key
    const expected = crypto
      .createHmac("sha512", PAYSTACK_SECRET_KEY)
      .update(req.rawBody)
      .digest("hex");

    const sigBuf = Buffer.from(String(signature));
    const expBuf = Buffer.from(expected);
    if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
      console.warn("⚠️  Webhook signature mismatch");
      return res.status(401).json({ success: false, message: "Invalid signature" });
    }

    const event = req.body;
    if (event.event !== "charge.success") {
      return res.json({ success: true, message: "Event ignored" });
    }

    const data = event.data || {};
    if (data.status !== "success" || (data.currency && data.currency !== "GHS"))
      return res.json({ success: true, message: "Not a successful GHS payment" });

    const result = await processPaidReference(data.reference, (data.amount ?? 0) / 100);
    if (result.unknown) {
      console.warn("ℹ️  Webhook for unknown reference:", data.reference);
      return res.json({ success: true, message: "Unknown reference" }); // 200 so Paystack stops retrying
    }
    return res.json({ success: true });
  } catch (err) {
    console.error("webhook error:", err.message);
    return res.status(500).json({ success: false, message: "Webhook processing failed" });
  }
});

// ══════════════════════════════════════════════════════════════════════════
// DUES SUMMARY
// ══════════════════════════════════════════════════════════════════════════

app.get("/dues-summary/:semester", async (req, res) => {
  try {
    const { semester } = req.params;
    const snap = await db.collection("dues").where("semester", "==", semester).get();
    const records = snap.docs.map((d) => d.data());
    const totalCollected = records.reduce((sum, r) => sum + (r.amountPaid ?? 0), 0);
    const paidCount = records.filter((r) => r.isPaid).length;
    return res.json({ success: true, totalCollected, paidCount, unpaidCount: records.length - paidCount, records });
  } catch (err) {
    console.error("dues-summary error:", err.message);
    return res.status(500).json({ success: false, message: "Failed to fetch summary" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Asempa backend running on port ${PORT}`));