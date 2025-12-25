const {onRequest} = require("firebase-functions/v2/https");
const nodemailer = require("nodemailer");

const MAIL_USER = "nonteerapong8@gmail.com";
const MAIL_PASS = "aljq qkag vfjz ofdr";

const mailTransporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: MAIL_USER,
    pass: MAIL_PASS,
  },
});

exports.sendOtpEmail = onRequest(async (req, res) => {
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  let payload = req.body || {};
  if (typeof payload === "string") {
    try {
      payload = JSON.parse(payload || "{}");
    } catch (err) {
      console.error("Invalid OTP payload:", err);
      return res.status(400).json({ error: "Invalid JSON payload." });
    }
  }

  const email = payload.email;
  const code = payload.code;

  if (!email || !code) {
    return res.status(400).json({ error: "Email and OTP code are required." });
  }

  if (!MAIL_USER || !MAIL_PASS) {
    return res.status(500).json({ error: "Mail service not configured." });
  }

  const mailOptions = {
    from: `RMUTL OTP <${MAIL_USER}>`,
    to: email,
    subject: "Your RMUTL OTP Code",
    text: `Your verification code is ${code}. This code will expire in 10 minutes.`,
    html: `<p>Hello,</p>
      <p>Your verification code is <strong>${code}</strong>.</p>
      <p>This code will expire in 10 minutes.</p>
      <p>RMUTL Full Project</p>`,
  };

  try {
    await mailTransporter.sendMail(mailOptions);
    return res.json({ success: true });
  } catch (err) {
    console.error("Failed to send OTP email:", err);
    return res.status(500).json({ error: "Failed to send OTP email." });
  }
});
