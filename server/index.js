const express = require("express");
const axios = require("axios");
const cors = require("cors");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());
app.use(cors());

// ── Firebase Admin ────────────────────────────────────────────────────────
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

// ── RushPay config ────────────────────────────────────────────────────────
const RUSHPAY_API_KEY        = process.env.RUSHPAY_API_KEY;
const RUSHPAY_BASE_URL       = "https://api.rushpay.cash/v1";
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

    const response = await rushpay.post("/payments/create", {
      amount, currency: "GHS",
      description: `Asempa Choir Dues — ${semester}`,
      customer_email: user.email,
      customer_name: user.name ?? user.fullName ?? "Member",
      callback_url: `${SERVER_URL}/payment-success`,
      metadata: { uid, semester, role: isAdmin ? "admin" : "member" },
    });

    console.log("RushPay create-payment response:", JSON.stringify(response.data, null, 2));

    const payment = response.data?.data ?? response.data;
    const paymentReference = payment?.payment_reference ?? payment?.reference ?? payment?.id;

    if (!paymentReference)
      return res.status(500).json({ success: false, message: "Could not get payment reference" });

    await db.collection("dues_payments").add({
      uid, semester, amount, role: isAdmin ? "admin" : "member",
      paymentReference, status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
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
    const sessionRes = await rushpay.post("/payments/widget-session", {
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
  <link rel="stylesheet" href="https://api.rushpay.cash/widget/payment-widget.css">
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
  <script>window.RUSHPAY_API_BASE = 'https://api.rushpay.cash/v1';</script>
  <script src="https://api.rushpay.cash/widget/payment-widget.js"></script>
  <script>
    RushPay.init({
      widgetSessionToken: '${widgetSessionToken}',
      paymentReference: '${reference}',
      callbackUrl: '${SERVER_URL}/payment-success',
      description: 'Asempa Choir Dues'
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
    const response = await rushpay.get(`/payments/verify?payment_reference=${reference}`);
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

app.post("/donations/campaign", async (req, res) => {
  try {
    const { name, description, targetAmount, deadline, createdBy } = req.body;
    if (!name || !targetAmount || !createdBy)
      return res.status(400).json({ success: false, message: "name, targetAmount, createdBy required" });

    const ref = await db.collection("donation_campaigns").add({
      name, description: description ?? "", targetAmount,
      deadline: deadline ?? null, amountRaised: 0, donorCount: 0,
      isActive: true, createdBy,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, campaignId: ref.id });
  } catch (err) {
    console.error("donations/campaign error:", err.message);
    return res.status(500).json({ success: false, message: "Campaign creation failed" });
  }
});

app.patch("/donations/campaign/:id", async (req, res) => {
  try {
    await db.collection("donation_campaigns").doc(req.params.id).update(req.body);
    return res.json({ success: true });
  } catch (err) {
    console.error("donations/campaign patch error:", err.message);
    return res.status(500).json({ success: false, message: "Update failed" });
  }
});

// ── POST /donations/pay ───────────────────────────────────────────────────
// Creates a RushPay payment for a donation campaign
app.post("/donations/pay", async (req, res) => {
  try {
    const { uid, campaignId, amount } = req.body;
    if (!uid || !campaignId || !amount || amount < 1)
      return res.status(400).json({ success: false, message: "uid, campaignId, amount required" });

    const userDoc     = await db.collection("users").doc(uid).get();
    const campaignDoc = await db.collection("donation_campaigns").doc(campaignId).get();
    if (!userDoc.exists)
      return res.status(404).json({ success: false, message: "User not found" });
    if (!campaignDoc.exists)
      return res.status(404).json({ success: false, message: "Campaign not found" });

    const user     = userDoc.data();
    const campaign = campaignDoc.data();

    const response = await rushpay.post("/payments/create", {
      amount, currency: "GHS",
      description: `Donation — ${campaign.name}`,
      customer_email: user.email,
      customer_name: user.name ?? user.fullName ?? "Member",
      callback_url: `${SERVER_URL}/donation-success`,
      metadata: { uid, campaignId, type: "donation", amount },
    });

    console.log("RushPay donation response:", JSON.stringify(response.data, null, 2));

    const payment = response.data?.data ?? response.data;
    const paymentReference = payment?.payment_reference ?? payment?.reference ?? payment?.id;

    if (!paymentReference)
      return res.status(500).json({ success: false, message: "Could not get payment reference" });

    await db.collection("donation_pending").add({
      uid, campaignId, amount, paymentReference, status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference, amount });
  } catch (err) {
    console.error("donations/pay error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Donation payment creation failed" });
  }
});

// ── GET /donations/checkout/:reference ───────────────────────────────────
app.get("/donations/checkout/:reference", async (req, res) => {
  try {
    const { reference } = req.params;
    const sessionRes = await rushpay.post("/payments/widget-session", {
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
  <link rel="stylesheet" href="https://api.rushpay.cash/widget/payment-widget.css">
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
  <script>window.RUSHPAY_API_BASE = 'https://api.rushpay.cash/v1';</script>
  <script src="https://api.rushpay.cash/widget/payment-widget.js"></script>
  <script>
    RushPay.init({
      widgetSessionToken: '${widgetSessionToken}',
      paymentReference: '${reference}',
      callbackUrl: '${SERVER_URL}/donation-success',
      description: 'Asempa Choir Donation'
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
// WEBHOOK
// ══════════════════════════════════════════════════════════════════════════

app.post("/webhook", async (req, res) => {
  try {
    const signature = req.headers["x-rushpay-signature"];
    console.log("📩 Webhook received");
    console.log("   Signature header:", signature);
    console.log("   Body:", JSON.stringify(req.body));

    if (!signature) {
      console.warn("⚠️  No signature header — proceeding anyway for debug");
    } else if (signature !== RUSHPAY_WEBHOOK_SECRET) {
      console.warn("⚠️  Signature mismatch — expected:", RUSHPAY_WEBHOOK_SECRET, "got:", signature);
    }

    const event = req.body;
    if (event.event !== "payment.completed") {
      console.log("ℹ️  Event ignored:", event.event);
      return res.json({ success: true, message: "Event ignored" });
    }

    const { payment_reference, amount, metadata } = event.data;
    const { uid, type, semester, campaignId } = metadata ?? {};
    if (!uid) return res.status(400).json({ success: false, message: "Missing uid" });

    // ── Donation ──────────────────────────────────────────────────────────
    if (type === "donation") {
      if (!campaignId) return res.status(400).json({ success: false, message: "Missing campaignId" });

      const pendingSnap = await db.collection("donation_pending")
        .where("paymentReference", "==", payment_reference).limit(1).get();
      if (!pendingSnap.empty)
        await pendingSnap.docs[0].ref.update({
          status: "completed",
          completedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

      const campaignRef = db.collection("donation_campaigns").doc(campaignId);
      const userDoc     = await db.collection("users").doc(uid).get();
      const userData    = userDoc.data();
      const userName    = userData?.name ?? userData?.fullName ?? "";

      await db.runTransaction(async (t) => {
        const campaignDoc = await t.get(campaignRef);
        if (!campaignDoc.exists) throw new Error("Campaign not found");

        t.update(campaignRef, {
          amountRaised: admin.firestore.FieldValue.increment(amount),
          donorCount:   admin.firestore.FieldValue.increment(1),
        });

        const donationRef = db.collection("donations").doc();
        t.set(donationRef, {
          uid, campaignId, amount,
          name:             userName,
          voicePart:        userData?.voicePart ?? "",
          paymentReference: payment_reference,
          donatedAt:        admin.firestore.FieldValue.serverTimestamp(),
        });
      });

      console.log(`🙏 Donation recorded: uid=${uid} campaign=${campaignId} amount=${amount}`);
      return res.json({ success: true });
    }

    // ── Dues direct payment ───────────────────────────────────────────────
    if (!semester) return res.status(400).json({ success: false, message: "Missing semester" });

    const paymentsSnap = await db.collection("dues_payments")
      .where("paymentReference", "==", payment_reference).limit(1).get();
    if (!paymentsSnap.empty)
      await paymentsSnap.docs[0].ref.update({
        status: "completed",
        paidAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    const duesRef  = db.collection("dues").doc(safeSemesterId(uid, semester));
    const duesDoc  = await duesRef.get();
    const previousPaid = duesDoc.exists ? duesDoc.data().amountPaid ?? 0 : 0;
    const newTotal = previousPaid + amount;
    const userDoc  = await db.collection("users").doc(uid).get();
    const userData = userDoc.data();
    const isAdmin  = userData?.isAdmin === true;
    const required = isAdmin ? DUES.admin : DUES.member;
    const userName = userData?.name ?? userData?.fullName ?? "";

    await duesRef.set({
      uid, semester, amountPaid: newTotal, amountRequired: required,
      isPaid: newTotal >= required,
      lastPaymentAt: admin.firestore.FieldValue.serverTimestamp(),
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