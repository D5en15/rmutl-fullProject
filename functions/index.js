const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

const APP_EMAIL = "nonteerapong8@gmail.com";
const APP_PASSWORD = "gpyg ofrp vzsx zfwx";

const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: { user: APP_EMAIL, pass: APP_PASSWORD },
});
exports.sendOtpEmail = functions.https.onCall(async (data, context) => {
 const email = data?.email || data?.data?.email;
  const code = data?.code || data?.data?.code;

  if (!email || !code) {
    console.error("❌ Missing email or code. Received:", data);
    throw new functions.https.HttpsError("invalid-argument", "Missing email or code.");
  }

  try {
    await transporter.sendMail({
      from: `"RMUTL App" <${APP_EMAIL}>`,
      to: email,
      subject: "Your OTP Code",
      html: `
        <div style="font-family:Arial,sans-serif;padding:16px;">
          <h2>Your OTP Code</h2>
          <p>Your verification code is:</p>
          <h1 style="color:#4CAF50;font-size:24px;">${code}</h1>
          <p>This code will expire in 10 minutes.</p>
        </div>
      `,
    });

    // ส่งสำเร็จ → return result
    return { success: true };
  } catch (ex) {
    console.error("❌ Failed to send email:", ex);
    throw new functions.https.HttpsError("unknown", ex.message || String(ex));
  }
});

