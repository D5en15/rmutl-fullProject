const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

function gradeToPoint(grade) {
    switch (grade) {
        case "A": return 4.0;
        case "B+": return 3.5;
        case "B": return 3.0;
        case "C+": return 2.5;
        case "C": return 2.0;
        case "D+": return 1.5;
        case "D": return 1.0;
        case "F": return 0.0;
        default: return -1;
    }
}

exports.calculateStudentMetrics = functions.https.onRequest(async (req, res) => {
    // ✅ ตอบ CORS ทุกครั้ง
    res.set("Access-Control-Allow-Origin", "*");
    res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.set("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
        // ✅ Preflight (OPTIONS) ต้องตอบ 204 เสมอ
        return res.status(204).send("");
    }

    try {
        const email = req.body.email;
        if (!email) {
            return res.status(400).json({ error: "Email required" });
        }

        const userSnap = await admin.firestore()
            .collection("user")
            .where("user_email", "==", email)
            .limit(1)
            .get();

        if (userSnap.empty) {
            return res.status(404).json({ error: "User not found" });
        }
        const userId = userSnap.docs[0].data().user_id;

        const enrollSnap = await admin.firestore()
            .collection("enrollment")
            .where("user_id", "==", userId)
            .get();

        if (enrollSnap.empty) {
            return res.json({ gpa: 0, gpaBySemester: {}, subploScores: {}, ploScores: {}, careerScores: {} });
        }

        let totalPoints = 0, totalCredits = 0;
        const semPoints = {}, semCredits = {};
        const subploScores = {}, ploScores = {}, careerScores = {};

        for (const e of enrollSnap.docs) {
            const enroll = e.data();
            const grade = enroll.enrollment_grade || "";
            const semester = enroll.enrollment_semester || "Unknown";
            const subjectId = enroll.subject_id;

            const subjDoc = await admin.firestore().collection("subject").doc(subjectId).get();
            if (!subjDoc.exists) continue;

            const subj = subjDoc.data();
            const creditsText = (subj.subject_credits || "0").toString().split("(")[0];
            const credits = parseFloat(creditsText) || 0;
            const subploId = subj.subplo_id;

            const point = gradeToPoint(grade);
            if (point >= 0) {
                totalPoints += point * credits;
                totalCredits += credits;

                semPoints[semester] = (semPoints[semester] || 0) + (point * credits);
                semCredits[semester] = (semCredits[semester] || 0) + credits;

                if (subploId) {
                    if (!subploScores[subploId]) subploScores[subploId] = { points: 0, credits: 0 };
                    subploScores[subploId].points += point * credits;
                    subploScores[subploId].credits += credits;
                }
            }
        }

        const gpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
        const gpaBySemester = {};
        Object.keys(semPoints).forEach(sem => {
            const pts = semPoints[sem];
            const crd = semCredits[sem];
            gpaBySemester[sem] = crd > 0 ? pts / crd : 0;
        });

        Object.keys(subploScores).forEach(s => {
            const { points, credits } = subploScores[s];
            subploScores[s] = credits > 0 ? points / credits : 0;
        });

        return res.json({
            gpa,
            gpaBySemester,
            subploScores,
            ploScores,
            careerScores,
        });

    } catch (err) {
        console.error(err);
        return res.status(500).json({ error: err.message });
    }
});