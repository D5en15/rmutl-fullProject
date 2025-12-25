const {onRequest} = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const {calculateAndPersist} = require("./cal");

// HTTP endpoint to recompute metrics for all users based on current enrollments.
exports.recalculateAllMetrics = onRequest(async (req, res) => {
  if (req.method === "OPTIONS") {
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");
    return res.status(204).send("");
  }
  if (req.method !== "POST") {
    return res.status(405).json({ error: "Method not allowed" });
  }

  try {
    const db = admin.firestore();
    const usersSnap = await db.collection("user").get();

    let processed = 0;
    let skipped = 0;

    for (const doc of usersSnap.docs) {
      const data = doc.data() || {};
      const uid = data.user_id || data.user_code || doc.id;
      if (!uid) {
        skipped += 1;
        continue;
      }

      try {
        await calculateAndPersist({ userId: uid });
        processed += 1;
      } catch (e) {
        console.error(`recalculateAllMetrics failed for user_id ${uid}:`, e);
        skipped += 1;
      }
    }

    return res.json({
      success: true,
      processed,
      skipped,
      total: usersSnap.size,
    });
  } catch (err) {
    console.error("recalculateAllMetrics error:", err);
    return res.status(500).json({ error: err.message || "Unknown error" });
  }
});
