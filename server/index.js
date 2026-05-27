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

// Dues amounts in GHS
const DUES = { admin: 30, member: 20 };

const rushpay = axios.create({
  baseURL: RUSHPAY_BASE_URL,
  headers: {
    "X-API-Key": RUSHPAY_API_KEY,
    "Content-Type": "application/json",
  },
});

// ── Helper: safe Firestore doc ID (no slashes or spaces) ─────────────────
const safeSemesterId = (uid, semester) =>
  `${uid}_${semester.replace(/\//g, "-").replace(/ /g, "_")}`;

// ── Health check ──────────────────────────────────────────────────────────
app.get("/", (req, res) => res.json({ status: "Asempa backend running" }));

// ── POST /create-payment ──────────────────────────────────────────────────
app.post("/create-payment", async (req, res) => {
  try {
    const { uid, semester } = req.body;
    if (!uid || !semester) {
      return res
        .status(400)
        .json({ success: false, message: "uid and semester required" });
    }

    // Get user info from Firestore
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      return res
        .status(404)
        .json({ success: false, message: "User not found" });
    }
    const user = userDoc.data();
    const isAdmin = user.isAdmin === true;
    const amount = isAdmin ? DUES.admin : DUES.member;

    // Create payment on RushPay
    const response = await rushpay.post("/payments/create", {
      amount,
      currency: "GHS",
      description: `Asempa Choir Dues — ${semester}`,
      customer_email: user.email,
      customer_name: user.fullName,
      metadata: {
        uid,
        semester,
        role: isAdmin ? "admin" : "member",
      },
    });

    // Log full response so we can see the exact field names
    console.log("RushPay create-payment response:", JSON.stringify(response.data, null, 2));

    // Try common field paths — adjust once we see the logs
    const payment = response.data?.data ?? response.data;
    const paymentReference =
      payment?.payment_reference ??
      payment?.reference ??
      payment?.id ??
      payment?.paymentReference ??
      null;

    if (!paymentReference) {
      console.error("Could not find payment reference in response:", response.data);
      return res
        .status(500)
        .json({ success: false, message: "Could not get payment reference from RushPay" });
    }

    // Save pending payment to Firestore
    await db.collection("dues_payments").add({
      uid,
      semester,
      amount,
      role: isAdmin ? "admin" : "member",
      paymentReference,
      status: "pending",
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    return res.json({
      success: true,
      paymentReference,
      amount,
    });
  } catch (err) {
    console.error("create-payment error:", err.response?.data ?? err.message);
    return res
      .status(500)
      .json({ success: false, message: "Payment creation failed" });
  }
});

// ── POST /widget-session ──────────────────────────────────────────────────
app.post("/widget-session", async (req, res) => {
  try {
    const { paymentReference } = req.body;
    if (!paymentReference) {
      return res
        .status(400)
        .json({ success: false, message: "paymentReference required" });
    }

    const response = await rushpay.post("/payments/widget-session", {
      payment_reference: paymentReference,
    });

    const token = response.data?.data?.widget_session_token;
    return res.json({ success: true, widgetSessionToken: token });
  } catch (err) {
    console.error("widget-session error:", err.response?.data ?? err.message);
    return res
      .status(500)
      .json({ success: false, message: "Widget session failed" });
  }
});

// ── GET /verify/:reference ────────────────────────────────────────────────
app.get("/verify/:reference", async (req, res) => {
  try {
    const { reference } = req.params;
    const response = await rushpay.get(
      `/payments/verify?payment_reference=${reference}`
    );
    const payment = response.data?.data ?? response.data;
    return res.json({
      success: true,
      status: payment.status,
      amount: payment.amount,
    });
  } catch (err) {
    console.error("verify error:", err.response?.data ?? err.message);
    return res
      .status(500)
      .json({ success: false, message: "Verification failed" });
  }
});

// ── POST /webhook ─────────────────────────────────────────────────────────
app.post("/webhook", async (req, res) => {
  try {
    // Verify signature
    const signature = req.headers["x-rushpay-signature"];
    if (!signature || signature !== RUSHPAY_WEBHOOK_SECRET) {
      return res
        .status(401)
        .json({ success: false, message: "Invalid signature" });
    }

    const event = req.body;
    if (event.event !== "payment.completed") {
      return res.json({ success: true, message: "Event ignored" });
    }

    const { payment_reference, amount, metadata } = event.data;
    const { uid, semester } = metadata ?? {};

    if (!uid || !semester) {
      return res
        .status(400)
        .json({ success: false, message: "Missing metadata" });
    }

    // Find the pending payment doc
    const paymentsSnap = await db
      .collection("dues_payments")
      .where("paymentReference", "==", payment_reference)
      .limit(1)
      .get();

    if (paymentsSnap.empty) {
      return res
        .status(404)
        .json({ success: false, message: "Payment record not found" });
    }

    const paymentDoc = paymentsSnap.docs[0];

    // Mark payment as completed
    await paymentDoc.ref.update({
      status: "completed",
      paidAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user's dues tracker — use safe doc ID (no slashes/spaces)
    const duesRef = db.collection("dues").doc(safeSemesterId(uid, semester));
    const duesDoc = await duesRef.get();

    const previousPaid = duesDoc.exists ? duesDoc.data().amountPaid ?? 0 : 0;
    const newTotal = previousPaid + amount;

    const userDoc = await db.collection("users").doc(uid).get();
    const isAdmin = userDoc.data()?.isAdmin === true;
    const required = isAdmin ? DUES.admin : DUES.member;

    await duesRef.set(
      {
        uid,
        semester,
        amountPaid: newTotal,
        amountRequired: required,
        isPaid: newTotal >= required,
        lastPaymentAt: admin.firestore.FieldValue.serverTimestamp(),
        role: isAdmin ? "admin" : "member",
        fullName: userDoc.data()?.fullName ?? "",
        voicePart: userDoc.data()?.voicePart ?? "",
      },
      { merge: true }
    );

    console.log(
      `✅ Dues credited: uid=${uid} semester=${semester} amount=${amount}`
    );
    return res.json({ success: true });
  } catch (err) {
    console.error("webhook error:", err.message);
    return res
      .status(500)
      .json({ success: false, message: "Webhook processing failed" });
  }
});

// ── GET /dues-summary/:semester ───────────────────────────────────────────
app.get("/dues-summary/:semester", async (req, res) => {
  try {
    const { semester } = req.params;
    const snap = await db
      .collection("dues")
      .where("semester", "==", semester)
      .get();

    const records = snap.docs.map((d) => d.data());
    const totalCollected = records.reduce(
      (sum, r) => sum + (r.amountPaid ?? 0),
      0
    );
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
    return res
      .status(500)
      .json({ success: false, message: "Failed to fetch summary" });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () =>
  console.log(`Asempa backend running on port ${PORT}`)
);