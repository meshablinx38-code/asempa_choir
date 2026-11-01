const crypto = require("node:crypto");
const express = require("express");
const axios = require("axios");
const cors = require("cors");
const admin = require("firebase-admin");
const cron = require("node-cron");

const app = express();
app.use(express.json());
app.use(cors());

// ── Firebase Admin ────────────────────────────────────────────────────────
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();
const { FieldValue, Timestamp } = admin.firestore;

// ── RushPay config (V2) ───────────────────────────────────────────────────
const RUSHPAY_API_KEY        = process.env.RUSHPAY_API_KEY;
const RUSHPAY_BASE_URL       = "https://core.rushpay.cash";
const RUSHPAY_API_BASE       = "https://core.rushpay.cash"; // used by the browser widget (it appends /api/v1/merchant/... itself)
const RUSHPAY_WEBHOOK_SECRET = process.env.RUSHPAY_WEBHOOK_SECRET;
const SERVER_URL = process.env.SERVER_URL || "https://asempachoir-production.up.railway.app";

const DUES = { admin: 30, member: 20 };

const rushpay = axios.create({
  baseURL: RUSHPAY_BASE_URL,
  headers: { "X-API-Key": RUSHPAY_API_KEY, "Content-Type": "application/json" },
});

// ── Helpers ───────────────────────────────────────────────────────────────
const safeSemesterId = (uid, semester) =>
  `${uid}_${semester.replace(/\//g, "-").replace(/ /g, "_")}`;

// Format amount as a string with 2 decimals (RushPay V2 expects amount as a string)
const fmtAmount = (n) => Number(n).toFixed(2);

// Works for Firestore Timestamps AND the ISO strings older campaigns were saved with.
// A deadline saved at exactly 00:00:00 is treated as the END of that day.
const toDateSafe = (v) => {
  if (!v) return null;
  const d = typeof v.toDate === "function" ? v.toDate() : new Date(v);
  if (isNaN(d.getTime())) return null;
  if (d.getUTCHours() === 0 && d.getUTCMinutes() === 0 && d.getUTCSeconds() === 0) {
    d.setUTCHours(23, 59, 59, 0);
  }
  return d;
};

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

// ── Health check ──────────────────────────────────────────────────────────
app.get("/", (req, res) => res.json({ status: "Asempa backend running" }));

// ══════════════════════════════════════════════════════════════════════════
// DUES — Direct RushPay checkout
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

    const response = await rushpay.post("/api/v1/merchant/payments/create", {
      amount: fmtAmount(amount),
      description: `Asempa Choir Dues — ${semester}`,
      callback_url: `${SERVER_URL}/payment-success`,
      metadata: {
        uid,
        semester,
        role: isAdmin ? "admin" : "member",
        customer_email: user.email,
        customer_name: user.name ?? user.fullName ?? "Member",
      },
    });

    console.log("RushPay create-payment response:", JSON.stringify(response.data, null, 2));

    const payment = response.data?.data ?? response.data;
    const paymentReference = payment?.payment_reference ?? payment?.reference ?? payment?.id;

    if (!paymentReference)
      return res.status(500).json({ success: false, message: "Could not get payment reference" });

    await db.collection("dues_payments").add({
      uid, semester, amount, role: isAdmin ? "admin" : "member",
      paymentReference, status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference, amount });
  } catch (err) {
    console.error("create-payment error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Payment creation failed" });
  }
});

app.get("/checkout/:reference", async (req, res) => {
  try {
    const { reference } = req.params;
    const sessionRes = await rushpay.post("/api/v1/merchant/payments/widget-session", {
      payment_reference: reference,
    });
    const widgetSessionToken = sessionRes.data?.data?.widget_session_token;
    if (!widgetSessionToken)
      return res.status(500).send("Could not create widget session");

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Asempa Choir — Pay Dues</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5; min-height: 100vh; display: flex;
      flex-direction: column; align-items: center; padding: 20px; }
    .header { text-align: center; margin-bottom: 24px; }
    .header h1 { font-size: 22px; color: #1a1a2e; font-weight: 700; }
    .header p { font-size: 14px; color: #666; margin-top: 4px; }
    #rushpay-payment-widget { width: 100%; max-width: 480px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🎵 Asempa Choir</h1>
    <p>Secure dues payment powered by RushPay</p>
  </div>
  <div id="rushpay-payment-widget"></div>
  <script src="https://core.rushpay.cash/widget/payment-widget-v2.js"></script>
  <script>
    RushPayV2.init({
      apiBase: "${RUSHPAY_API_BASE}",
      containerId: "rushpay-payment-widget",
      paymentReference: '${reference}',
      widgetSessionToken: '${widgetSessionToken}',
      callbackUrl: '${SERVER_URL}/payment-success'
    });
  </script>
</body>
</html>`;
    res.setHeader("Content-Type", "text/html");
    return res.send(html);
  } catch (err) {
    console.error("checkout error:", err.response?.data ?? err.message);
    return res.status(500).send("Checkout failed. Please try again.");
  }
});

app.get("/payment-success", (req, res) => {
  res.send(`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Payment Successful</title>
<style>body{font-family:-apple-system,sans-serif;background:#f5f5f5;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:20px}.card{background:white;border-radius:20px;padding:40px;box-shadow:0 4px 20px rgba(0,0,0,.08);max-width:400px;width:100%}.icon{font-size:64px;margin-bottom:16px}h1{color:#00C853;font-size:24px;margin-bottom:8px}p{color:#666;font-size:15px;line-height:1.5}.note{margin-top:20px;font-size:13px;color:#999}</style>
</head><body><div class="card"><div class="icon">✅</div>
<h1>Payment Successful!</h1>
<p>Your dues have been received. Your record will be updated shortly.</p>
<p class="note">You can close this tab and return to the Asempa app.</p>
</div></body></html>`);
});

app.get("/verify/:reference", async (req, res) => {
  try {
    const { reference } = req.params;
    const response = await rushpay.get(`/api/v1/merchant/payments/status?payment_reference=${reference}`);
    const payment = response.data?.data ?? response.data;
    return res.json({ success: true, status: payment.status, amount: payment.amount });
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

    const response = await rushpay.post("/api/v1/merchant/payments/create", {
      amount: fmtAmount(amount),
      description: `Donation — ${campaign.name}`,
      callback_url: `${SERVER_URL}/donation-success`,
      metadata: {
        uid,
        campaignId,
        type: "donation",
        amount,
        customer_email: user.email,
        customer_name: user.name ?? user.fullName ?? "Member",
      },
    });

    console.log("RushPay donation response:", JSON.stringify(response.data, null, 2));

    const payment = response.data?.data ?? response.data;
    const paymentReference = payment?.payment_reference ?? payment?.reference ?? payment?.id;

    if (!paymentReference)
      return res.status(500).json({ success: false, message: "Could not get payment reference" });

    await db.collection("donation_pending").add({
      uid, campaignId, amount, paymentReference, status: "pending",
      createdAt: FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference, amount });
  } catch (err) {
    console.error("donations/pay error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Donation payment creation failed" });
  }
});

app.get("/donations/checkout/:reference", async (req, res) => {
  try {
    const { reference } = req.params;
    const sessionRes = await rushpay.post("/api/v1/merchant/payments/widget-session", {
      payment_reference: reference,
    });
    const widgetSessionToken = sessionRes.data?.data?.widget_session_token;
    if (!widgetSessionToken)
      return res.status(500).send("Could not create widget session");

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Asempa Choir — Donate</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5; min-height: 100vh; display: flex;
      flex-direction: column; align-items: center; padding: 20px; }
    .header { text-align: center; margin-bottom: 24px; }
    .header h1 { font-size: 22px; color: #1a1a2e; font-weight: 700; }
    .header p { font-size: 14px; color: #666; margin-top: 4px; }
    #rushpay-payment-widget { width: 100%; max-width: 480px; }
  </style>
</head>
<body>
  <div class="header">
    <h1>🎵 Asempa Choir</h1>
    <p>Thank you for your generosity</p>
  </div>
  <div id="rushpay-payment-widget"></div>
  <script src="https://core.rushpay.cash/widget/payment-widget-v2.js"></script>
  <script>
    RushPayV2.init({
      apiBase: "${RUSHPAY_API_BASE}",
      containerId: "rushpay-payment-widget",
      paymentReference: '${reference}',
      widgetSessionToken: '${widgetSessionToken}',
      callbackUrl: '${SERVER_URL}/donation-success'
    });
  </script>
</body>
</html>`;
    res.setHeader("Content-Type", "text/html");
    return res.send(html);
  } catch (err) {
    console.error("donations checkout error:", err.response?.data ?? err.message);
    return res.status(500).send("Checkout failed. Please try again.");
  }
});

app.get("/donation-success", (req, res) => {
  res.send(`<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Donation Successful</title>
<style>body{font-family:-apple-system,sans-serif;background:#f5f5f5;display:flex;align-items:center;justify-content:center;min-height:100vh;text-align:center;padding:20px}.card{background:white;border-radius:20px;padding:40px;box-shadow:0 4px 20px rgba(0,0,0,.08);max-width:400px;width:100%}.icon{font-size:64px;margin-bottom:16px}h1{color:#E91E63;font-size:24px;margin-bottom:8px}p{color:#666;font-size:15px;line-height:1.5}.note{margin-top:20px;font-size:13px;color:#999}</style>
</head><body><div class="card"><div class="icon">🙏</div>
<h1>Thank You!</h1>
<p>Your donation has been received. God bless you for your generosity.</p>
<p class="note">You can close this tab and return to the Asempa app.</p>
</div></body></html>`);
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

  // Your webhook writes a `donations` record only after a successful payment,
  // so every record here is a real donation.
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
const DAY_MS = 24 * 60 * 60 * 1000;
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

// Every day at 09:00 Accra time
cron.schedule("0 9 * * *", () => {
  runDailyReminders().catch((e) => console.error("Daily reminders error:", e.message));
}, { timezone: "Africa/Accra" });

// Optional: lets an external scheduler trigger it if Railway ever sleeps the service.
// Set CRON_SECRET in Railway variables, then POST with header x-cron-secret.
app.post("/donations/cron/run", async (req, res) => {
  if (!process.env.CRON_SECRET || req.headers["x-cron-secret"] !== process.env.CRON_SECRET)
    return res.status(403).json({ success: false });
  await runDailyReminders();
  return res.json({ success: true });
});

// ══════════════════════════════════════════════════════════════════════════
// WEBHOOK
// ══════════════════════════════════════════════════════════════════════════

app.post("/webhook", async (req, res) => {
  try {
    const signature = req.headers["x-rushpay-signature"];
    console.log("📩 Webhook received");
    console.log("   Signature header:", signature);
    console.log("   Body:", JSON.stringify(req.body));

    if (!signature) {
      console.warn("⚠️  No signature header — rejecting");
      return res.status(401).json({ success: false, message: "No signature" });
    }

    const rawBody = JSON.stringify(req.body);
    const expected = crypto
      .createHmac("sha256", RUSHPAY_WEBHOOK_SECRET)
      .update(rawBody)
      .digest("hex");

    const sigBuf = Buffer.from(signature);
    const expBuf = Buffer.from(expected);
    if (sigBuf.length !== expBuf.length || !crypto.timingSafeEqual(sigBuf, expBuf)) {
      console.warn("⚠️  Signature mismatch — expected:", expected, "got:", signature);
      return res.status(401).json({ success: false, message: "Invalid signature" });
    }

    console.log("✅ Signature verified");

    const event = req.body;
    if (event.event !== "payment.completed") {
      console.log("ℹ️  Event ignored:", event.event);
      return res.json({ success: true, message: "Event ignored" });
    }

    const { payment_reference, amount } = event.data;

    // ── Look up by reference — don't rely on metadata ─────────────────
    const [donationSnap, duesSnap] = await Promise.all([
      db.collection("donation_pending")
        .where("paymentReference", "==", payment_reference).limit(1).get(),
      db.collection("dues_payments")
        .where("paymentReference", "==", payment_reference).limit(1).get(),
    ]);

    if (donationSnap.empty && duesSnap.empty) {
      console.warn("⚠️  No pending record found for:", payment_reference);
      return res.status(400).json({ success: false, message: "Unknown payment reference" });
    }

    const isDonation = !donationSnap.empty;
    const pendingDoc = isDonation ? donationSnap.docs[0] : duesSnap.docs[0];

    // Webhooks can be delivered more than once — never count a payment twice
    if (pendingDoc.data().status === "completed") {
      console.log("ℹ️  Already processed:", payment_reference);
      return res.json({ success: true, message: "Already processed" });
    }

    const { uid, campaignId, semester } = pendingDoc.data();

    // Mark pending as completed
    await pendingDoc.ref.update({
      status: "completed",
      completedAt: FieldValue.serverTimestamp(),
    });

    // ── Donation ──────────────────────────────────────────────────────
    if (isDonation) {
      const campaignRef = db.collection("donation_campaigns").doc(campaignId);
      const userDoc     = await db.collection("users").doc(uid).get();
      const userData    = userDoc.data();
      const userName    = userData?.name ?? userData?.fullName ?? "";

      await db.runTransaction(async (t) => {
        const campaignDoc = await t.get(campaignRef);
        if (!campaignDoc.exists) throw new Error("Campaign not found");

        t.update(campaignRef, {
          amountRaised: FieldValue.increment(amount),
          donorCount:   FieldValue.increment(1),
        });

        t.set(db.collection("donations").doc(), {
          uid, campaignId, amount,
          name:             userName,
          voicePart:        userData?.voicePart ?? "",
          paymentReference: payment_reference,
          donatedAt:        FieldValue.serverTimestamp(),
        });
      });

      console.log(`🙏 Donation recorded: uid=${uid} campaign=${campaignId} amount=${amount}`);
      return res.json({ success: true });
    }

    // ── Dues ──────────────────────────────────────────────────────────
    const duesRef      = db.collection("dues").doc(safeSemesterId(uid, semester));
    const duesDoc      = await duesRef.get();
    const previousPaid = duesDoc.exists ? duesDoc.data().amountPaid ?? 0 : 0;
    const newTotal     = previousPaid + amount;
    const userDoc      = await db.collection("users").doc(uid).get();
    const userData     = userDoc.data();
    const isAdmin      = userData?.isAdmin === true;
    const userName     = userData?.name ?? userData?.fullName ?? "";

    await duesRef.set({
      uid, semester, amountPaid: newTotal,
      amountRequired: isAdmin ? DUES.admin : DUES.member,
      isPaid: newTotal >= (isAdmin ? DUES.admin : DUES.member),
      lastPaymentAt: FieldValue.serverTimestamp(),
      role:      isAdmin ? "admin" : "member",
      name:      userName,
      voicePart: userData?.voicePart ?? "",
    }, { merge: true });

    console.log(`✅ Dues credited: uid=${uid} semester=${semester} amount=${amount}`);
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