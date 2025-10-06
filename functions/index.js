const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// 🟦 Gmail App Password (เปิดในบัญชี Gmail)
const APP_EMAIL = "nonteerapong8@gmail.com";
const APP_PASSWORD = "xhzb frsc niit aeih"; // App password จาก Google

// 🟩 ตั้งค่า mail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: APP_EMAIL,
    pass: APP_PASSWORD,
  },
});

// ✅ ฟังก์ชันส่ง OTP (Cloud Function แบบ callable)
exports.sendOtpEmail = functions
  .region("us-central1") // ต้องตรงกับ region ที่ Flutter เรียกใช้
  .https.onCall(async (data, context) => {
    // 🟦 Log ตรวจสอบค่าที่ Flutter ส่งมา
    console.log("📩 Received data from client:", JSON.stringify(data));

    // 🔹 ตรวจสอบค่า email และ code
    const email = data?.email;
    const code = data?.code;

    if (!email || !code) {
      console.error("❌ Missing email or code. Received:", data);
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing email or code."
      );
    }

    // 🔹 ตั้งค่าเนื้อหาอีเมล
    const mailOptions = {
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
    };

    try {
      await transporter.sendMail(mailOptions);
      console.log(`✅ OTP sent successfully to ${email}`);
      return { success: true };
    } catch (error) {
      console.error("❌ Error sending email:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to send email: " + error.message
      );
    }
  });