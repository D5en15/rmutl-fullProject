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
  res.set("Access-Control-Allow-Origin", "*");
  res.set("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  res.set("Access-Control-Allow-Headers", "Content-Type");

  if (req.method === "OPTIONS") {
    return res.status(204).send("");
  }

  try {
    const email = req.body.email;
    if (!email) {
      return res.status(400).json({ error: "Email required" });
    }

    // ✅ หา user จาก email
    const userSnap = await admin.firestore()
      .collection("user")
      .where("user_email", "==", email)
      .limit(1)
      .get();

    if (userSnap.empty) {
      return res.status(404).json({ error: "User not found" });
    }
    const userId = userSnap.docs[0].data().user_id;

    // ✅ enrollment ทั้งหมดของ user
    const enrollSnap = await admin.firestore()
      .collection("enrollment")
      .where("user_id", "==", userId)
      .get();

    if (enrollSnap.empty) {
      return res.json({
        gpa: 0,
        gpaBySemester: {},
        subploScores: {},
        ploScores: {},
        careerScores: {}
      });
    }

    let totalPoints = 0, totalCredits = 0;
    const semPoints = {}, semCredits = {};
    const rawSubplo = {};   // เก็บคะแนน subplo_id ต่อวิชา
    const finalSkills = {}; // เก็บคะแนน skill code จริง
    const ploScores = {}, careerScores = {};

    // ✅ loop enrollment
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

        // ✅ เก็บคะแนนใน rawSubplo
        if (subploId) {
          if (!rawSubplo[subploId]) rawSubplo[subploId] = { points: 0, credits: 0 };
          rawSubplo[subploId].points += point * credits;
          rawSubplo[subploId].credits += credits;
        }
      }
    }

    // ✅ GPA
    const gpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
    const gpaBySemester = {};
    Object.keys(semPoints).forEach(sem => {
      const pts = semPoints[sem];
      const crd = semCredits[sem];
      gpaBySemester[sem] = crd > 0 ? pts / crd : 0;
    });

    // ✅ ดึง subplo description มา map
    const subploDocs = await admin.firestore().collection("subplo").get();
    const subploMap = {};
    subploDocs.forEach(doc => {
      const d = doc.data();
      subploMap[d.subplo_id] = d.subplo_description || "";
    });

    // ✅ ดึง plo description มา map
    const ploDocs = await admin.firestore().collection("plo").get();
    const ploMap = {};
    ploDocs.forEach(doc => {
      const d = doc.data();
      ploMap[d.plo_id.toUpperCase()] = d.plo_description || "";
    });

    // ✅ คำนวณคะแนนแยกเป็น skill เดี่ยว
    Object.keys(rawSubplo).forEach(key => {
      const { points, credits } = rawSubplo[key];
      const avg = credits > 0 ? points / credits : 0;

      const skills = key.split(",");
      skills.forEach(skill => {
        skill = skill.trim();
        if (!skill) return;
        if (!finalSkills[skill]) finalSkills[skill] = { total: 0, count: 0 };
        finalSkills[skill].total += avg;
        finalSkills[skill].count += 1;
      });
    });

    // ✅ Normalize skills → subploScores (มี description)
    const subploScores = {};
    Object.keys(finalSkills).forEach(skill => {
      const { total, count } = finalSkills[skill];
      const avg = count > 0 ? total / count : 0;
      subploScores[skill] = {
        score: avg,
        description: subploMap[skill] || skill
      };
    });

    // ✅ รวมเป็น PLO
    Object.keys(subploScores).forEach(skillCode => {
      const score = subploScores[skillCode].score;
      if (score > 0) {
        const ploId = "PLO" + skillCode[0];
        if (!ploScores[ploId]) ploScores[ploId] = { total: 0, count: 0 };
        ploScores[ploId].total += score;
        ploScores[ploId].count += 1;
      }
    });

    // ✅ Normalize PLO (มี description)
    Object.keys(ploScores).forEach(p => {
      const { total, count } = ploScores[p];
      const avg = count > 0 ? total / count : 0;
      ploScores[p] = {
        score: avg,
        description: ploMap[p.toUpperCase()] || p
      };
    });

    return res.json({
      gpa,
      gpaBySemester,
      subploScores,  // ✅ {"1A": {score:3.25, description:"..."}, ...}
      ploScores,     // ✅ {"PLO1": {score:3.6, description:"..."}, ...}
      careerScores,
    });

  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message });
  }
});