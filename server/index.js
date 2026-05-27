const express = require("express");
const axios = require("axios");
const cors = require("cors");
const admin = require("firebase-admin");

const app = express();
app.use(express.json());
app.use(cors());

// ── Firebase Admin ────────────────────────────────────────────────────────
const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});
const db = admin.firestore();

// ── RushPay config ────────────────────────────────────────────────────────
const RUSHPAY_API_KEY = process.env.RUSHPAY_API_KEY;
const RUSHPAY_BASE_URL = "https://api.rushpay.cash/v1";
const RUSHPAY_WEBHOOK_SECRET = process.env.RUSHPAY_WEBHOOK_SECRET;
const SERVER_URL = process.env.SERVER_URL || "https://asempachoir-production.up.railway.app";

const DUES = { admin: 30, member: 20 };

const rushpay = axios.create({
  baseURL: RUSHPAY_BASE_URL,
  headers: {
    "X-API-Key": RUSHPAY_API_KEY,
    "Content-Type": "application/json",
  },
});

// ── Helper: safe Firestore doc ID ─────────────────────────────────────────
const safeSemesterId = (uid, semester) =>
  `${uid}_${semester.replace(/\//g, "-").replace(/ /g, "_")}`;

// ── Health check ──────────────────────────────────────────────────────────
app.get("/", (req, res) => res.json({ status: "Asempa backend running" }));

// ── POST /create-payment ──────────────────────────────────────────────────
app.post("/create-payment", async (req, res) => {
  try {
    const { uid, semester } = req.body;
    if (!uid || !semester)
      return res.status(400).json({ success: false, message: "uid and semester required" });

    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists)
      return res.status(404).json({ success: false, message: "User not found" });

    const user = userDoc.data();
    const isAdmin = user.isAdmin === true;
    const amount = isAdmin ? DUES.admin : DUES.member;

    const response = await rushpay.post("/payments/create", {
      amount,
      currency: "GHS",
      description: `Asempa Choir Dues — ${semester}`,
      customer_email: user.email,
      customer_name: user.fullName,
      callback_url: `${SERVER_URL}/payment-success`,
      metadata: { uid, semester, role: isAdmin ? "admin" : "member" },
    });

    console.log("RushPay create-payment response:", JSON.stringify(response.data, null, 2));

    const payment = response.data?.data ?? response.data;
    const paymentReference = payment?.payment_reference ?? payment?.reference ?? payment?.id;

    if (!paymentReference) {
      console.error("No payment reference in response:", response.data);
      return res.status(500).json({ success: false, message: "Could not get payment reference" });
    }

    await db.collection("dues_payments").add({
      uid,
      semester,
      amount,
      role: isAdmin ? "admin" : "member",
      paymentReference,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({ success: true, paymentReference, amount });
  } catch (err) {
    console.error("create-payment error:", err.response?.data ?? err.message);
    return res.status(500).json({ success: false, message: "Payment creation failed" });
  }
});

// ── GET /checkout/:reference ──────────────────────────────────────────────
// Flutter opens this page in the browser — embeds the RushPay widget
app.get("/checkout/:reference", async (req, res) => {
  try {
    const { reference } = req.params;

    // Create widget session server-side (API key never exposed to browser)
    const sessionRes = await rushpay.post("/payments/widget-session", {
      payment_reference: reference,
    });

    console.log("Widget session response:", JSON.stringify(sessionRes.data, null, 2));

    const widgetSessionToken = sessionRes.data?.data?.widget_session_token;

    if (!widgetSessionToken) {
      return res.status(500).send("Could not create widget session");
    }

    const html = `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Asempa Choir — Pay Dues</title>
  <link rel="stylesheet" href="https://api.rushpay.cash/widget/payment-widget.css">
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5;
      min-height: 100vh;
      display: flex;
      flex-direction: column;
      align-items: center;
      padding: 20px;
    }
    .header {
      text-align: center;
      margin-bottom: 24px;
    }
    .header h1 { font-size: 22px; color: #1a1a2e; font-weight: 700; }
    .header p  { font-size: 14px; color: #666; margin-top: 4px; }
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

// ── GET /payment-success ──────────────────────────────────────────────────
app.get("/payment-success", (req, res) => {
  res.send(`<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Payment Successful</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
      background: #f5f5f5; display: flex; align-items: center;
      justify-content: center; min-height: 100vh; text-align: center; padding: 20px;
    }
    .card {
      background: white; border-radius: 20px; padding: 40px;
      box-shadow: 0 4px 20px rgba(0,0,0,0.08); max-width: 400px; width: 100%;
    }
    .icon { font-size: 64px; margin-bottom: 16px; }
    h1 { color: #00C853; font-size: 24px; margin-bottom: 8px; }
    p  { color: #666; font-size: 15px; line-height: 1.5; }
    .note { margin-top: 20px; font-size: 13px; color: #999; }
  </style>
</head>
<body>
  <div class="card">
    <div class="icon">✅</div>
    <h1>Payment Successful!</h1>
    <p>Your dues have been received. Your balance will be updated shortly.</p>
    <p class="note">You can close this tab and return to the Asempa app.</p>
  </div>
</body>
</html>`);
});

// ── GET /verify/:reference ────────────────────────────────────────────────
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

// ── POST /webhook ─────────────────────────────────────────────────────────
app.post("/webhook", async (req, res) => {
  try {
    const signature = req.headers["x-rushpay-signature"];
    if (!signature || signature !== RUSHPAY_WEBHOOK_SECRET)
      return res.status(401).json({ success: false, message: "Invalid signature" });

    const event = req.body;
    if (event.event !== "payment.completed")
      return res.json({ success: true, message: "Event ignored" });

    const { payment_reference, amount, metadata } = event.data;
    const { uid, semester } = metadata ?? {};

    if (!uid || !semester)
      return res.status(400).json({ success: false, message: "Missing metadata" });

    const paymentsSnap = await db
      .collection("dues_payments")
      .where("paymentReference", "==", payment_reference)
      .limit(1)
      .get();

    if (paymentsSnap.empty)
      return res.status(404).json({ success: false, message: "Payment record not found" });

    await paymentsSnap.docs[0].ref.update({
      status: "completed",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    const duesRef = db.collection("dues").doc(safeSemesterId(uid, semester));
    const duesDoc = await duesRef.get();
    const previousPaid = duesDoc.exists ? duesDoc.data().amountPaid ?? 0 : 0;
    const newTotal = previousPaid + amount;

    const userDoc = await db.collection("users").doc(uid).get();
    const isAdmin = userDoc.data()?.isAdmin === true;
    const required = isAdmin ? DUES.admin : DUES.member;

    await duesRef.set({
      uid,
      semester,
      amountPaid: newTotal,
      amountRequired: required,
      isPaid: newTotal >= required,
      lastPaymentAt: admin.firestore.FieldValue.serverTimestamp(),
      role: isAdmin ? "admin" : "member",
      fullName: userDoc.data()?.fullName ?? "",
      voicePart: userDoc.data()?.voicePart ?? "",
    }, { merge: true });

    console.log(`✅ Dues credited: uid=${uid} semester=${semester} amount=${amount}`);
    return res.json({ success: true });
  } catch (err) {
    console.error("webhook error:", err.message);
    return res.status(500).json({ success: false, message: "Webhook processing failed" });
  }
});

// ── GET /dues-summary/:semester ───────────────────────────────────────────
app.get("/dues-summary/:semester", async (req, res) => {
  try {
    const { semester } = req.params;
    const snap = await db.collection("dues").where("semester", "==", semester).get();
    const records = snap.docs.map((d) => d.data());
    const totalCollected = records.reduce((sum, r) => sum + (r.amountPaid ?? 0), 0);
    const paidCount = records.filter((r) => r.isPaid).length;
    return res.json({
      success: true,
      totalCollected,
      paidCount,
      unpaidCount: records.length - paidCount,
      records,
    });
  } catch (err) {
    console.error("dues-summary error:", err.message);
    return res.status(500).json({ success: false, message: "Failed to fetch summary" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Asempa backend running on port ${PORT}`));