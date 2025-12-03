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

// แปลงคะแนนเฉลี่ย 0–4 -> 0–1 โดยถือว่า C = 0, A = 1
function normalizeGrade(avgPoint) {
  const norm = (avgPoint - 2.0) / 2.0; // 2 -> 0, 4 -> 1
  return Math.max(0, Math.min(1, norm));
}

// ✅ สูตรใหม่: ใช้ผลคูณของเกรด (0–1) กับ coverage (0–1) เป็นเปอร์เซ็นต์
//   - ถ้าเรียนวิชาน้อย (coverage ต่ำ) คะแนนจะยังไม่สูง แม้เกรดดี
//   - ถ้าเรียนครบ + เกรดดี คะแนนจึงจะสูง
function combineGradeAndCoverage(gradeNorm, coverage) {
  const g = Math.max(0, Math.min(1, gradeNorm || 0));
  const c = Math.max(0, Math.min(1, coverage || 0));
  const score01 = g * c; // ผลคูณเพื่อให้ทั้งสองอย่างสำคัญเท่ากัน
  return Math.round(score01 * 100);
}

// Cloud Function: คำนวณ GPA + SubPLO + PLO + Career
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

    // 1) หา user จาก email
    const userSnap = await admin
      .firestore()
      .collection("user")
      .where("user_email", "==", email)
      .limit(1)
      .get();

    if (userSnap.empty) {
      return res.status(404).json({ error: "User not found" });
    }
    const userId = userSnap.docs[0].data().user_id;

    // 2) preload รายวิชาทั้งหลักสูตร เพื่อรู้ "เพดานหน่วยกิต" ของแต่ละ SubPLO / PLO
    const subjectSnap = await admin.firestore().collection("subject").get();

    const subjectsMap = {};        // doc.id -> data
    const subploMaxCredits = {};   // "1A"  -> total possible credits ในหลักสูตร
    const ploMaxCredits = {};      // "PLO1" -> total possible credits ในหลักสูตร

    subjectSnap.forEach((doc) => {
      const subj = doc.data();
      subjectsMap[doc.id] = subj;

      const creditsText = (subj.subject_credits || "0").toString().split("(")[0];
      const credits = parseFloat(creditsText) || 0;
      const subploString = (subj.subplo_id || "").toString();

      const skills = subploString
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s.length > 0);

      if (credits <= 0 || skills.length === 0) return;

      const share = credits / skills.length;
      for (const skill of skills) {
        // SubPLO
        if (!subploMaxCredits[skill]) subploMaxCredits[skill] = 0;
        subploMaxCredits[skill] += share;

        // PLO จากตัวแรกของ skill เช่น "1A" -> "PLO1"
        const ploId = "PLO" + skill[0];
        if (!ploMaxCredits[ploId]) ploMaxCredits[ploId] = 0;
        ploMaxCredits[ploId] += share;
      }
    });

    // 3) enrollment ของ user
    const enrollSnap = await admin
      .firestore()
      .collection("enrollment")
      .where("user_id", "==", userId)
      .get();

    if (enrollSnap.empty) {
      return res.json({
        gpa: 0,
        gpaBySemester: {},
        subploScores: {},
        ploScores: {},
        careerScores: [],
      });
    }

    // ตัวแปรหลัก
    let totalPoints = 0;
    let totalCredits = 0;
    const semPoints = {};
    const semCredits = {};

    const subploStats = {}; // { '1A': { points, credits } }
    const ploStats = {};    // { 'PLO1': { points, credits } }

    // 4) loop enrollment ทีละวิชา
    for (const e of enrollSnap.docs) {
      const enroll = e.data();
      const grade = enroll.enrollment_grade || "";
      const semester = enroll.enrollment_semester || "Unknown";
      const subjectId = enroll.subject_id;

      if (!subjectId) continue;

      const subj = subjectsMap[subjectId];
      if (!subj) continue;

      const creditsText = (subj.subject_credits || "0").toString().split("(")[0];
      const credits = parseFloat(creditsText) || 0;
      const subploString = (subj.subplo_id || "").toString();

      const point = gradeToPoint(grade);
      if (point < 0 || credits <= 0) continue;

      // GPA รวม + ตามเทอม (ถ่วงด้วยหน่วยกิต)
      totalPoints += point * credits;
      totalCredits += credits;
      semPoints[semester] = (semPoints[semester] || 0) + point * credits;
      semCredits[semester] = (semCredits[semester] || 0) + credits;

      // แจกเครดิตของวิชาเข้า SubPLO และ PLO
      const skills = subploString
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s.length > 0);

      if (skills.length === 0) continue;

      const share = credits / skills.length;

      for (const skill of skills) {
        // SubPLO level
        if (!subploStats[skill]) {
          subploStats[skill] = { points: 0, credits: 0 };
        }
        subploStats[skill].points += point * share;
        subploStats[skill].credits += share;

        // PLO level
        const ploId = "PLO" + skill[0]; // "1A" -> "PLO1"
        if (!ploStats[ploId]) {
          ploStats[ploId] = { points: 0, credits: 0 };
        }
        ploStats[ploId].points += point * share;
        ploStats[ploId].credits += share;
      }
    }

    // 5) GPA รวมและรายเทอม
    const gpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
    const gpaBySemester = {};
    Object.keys(semPoints).forEach((sem) => {
      const pts = semPoints[sem];
      const crd = semCredits[sem] || 0;
      gpaBySemester[sem] = crd > 0 ? pts / crd : 0;
    });

    // 6) โหลดคำอธิบาย SubPLO / PLO
    const subploDocs = await admin.firestore().collection("subplo").get();
    const subploMap = {}; // "1A" -> description
    subploDocs.forEach((doc) => {
      const d = doc.data();
      if (!d.subplo_id) return;
      subploMap[d.subplo_id.toString().trim()] = d.subplo_description || "";
    });

    const ploDocs = await admin.firestore().collection("plo").get();
    const ploMap = {}; // "PLO1" -> description
    ploDocs.forEach((doc) => {
      const d = doc.data();
      if (!d.plo_id) return;
      ploMap[d.plo_id.toString().toUpperCase()] = d.plo_description || "";
    });

    // 7) คำนวณคะแนน SubPLO (เกรดเฉลี่ย + coverage)
    const subploScores = {};
    Object.keys(subploStats).forEach((skill) => {
      const { points, credits } = subploStats[skill];
      const avg = credits > 0 ? points / credits : 0; // 0–4 (เกรดเฉลี่ยดิบ)

      const gradeNorm = normalizeGrade(avg);      // 0–1
      const maxCredits = subploMaxCredits[skill] || credits || 0;
      const coverage = maxCredits > 0 ? Math.min(1, credits / maxCredits) : 0; // 0–1

      const percent = combineGradeAndCoverage(gradeNorm, coverage); // 0–100 ถ่วงเกรด+coverage
      const weight01 = percent / 100;          // 0–1
      const weightedScore = weight01 * 4;      // 0–4 เอาไว้เผื่อ UI ใช้ score/4*100

      subploScores[skill] = {
        rawScore: avg,              // ⭐ เกรดเฉลี่ยดิบ 0–4
        score: weightedScore,       // ⭐ 0–4 แต่ถ่วงด้วย coverage แล้ว
        percent,                    // 0–100 ใช้โชว์ Skill strengths
        gradeNorm,                  // 0–1
        coverage,                   // 0–1
        credits,                    // หน่วยกิตที่เรียนแล้วใน SubPLO นี้
        maxCredits,                 // หน่วยกิตสูงสุดตามหลักสูตร
        description: subploMap[skill] || skill,
      };
    });

    // 8) คำนวณคะแนน PLO (เกรดเฉลี่ย + coverage)
    const ploScores = {};
    Object.keys(ploStats).forEach((ploId) => {
      const { points, credits } = ploStats[ploId];
      const avg = credits > 0 ? points / credits : 0; // 0–4 ดิบ

      const gradeNorm = normalizeGrade(avg);
      const maxCredits = ploMaxCredits[ploId] || credits || 0;
      const coverage = maxCredits > 0 ? Math.min(1, credits / maxCredits) : 0;

      const percent = combineGradeAndCoverage(gradeNorm, coverage);
      const weight01 = percent / 100;
      const weightedScore = weight01 * 4;

      const key = ploId.toUpperCase();
      ploScores[key] = {
        rawScore: avg,          // ดิบ 0–4
        score: weightedScore,   // 0–4 ถ่วงเกรด+coverage
        percent,
        gradeNorm,
        coverage,
        credits,
        maxCredits,
        description: ploMap[key] || key,
      };
    });

    // 9) career mapping – ใช้ PLO rawScore + coverage รวมกัน
    const careerDocs = await admin.firestore().collection("career").get();
    const careerScores = [];

    careerDocs.forEach((doc) => {
      const d = doc.data();
      const careerId = d.career_id;
      if (!careerId) return;

      const relatedPLO = Array.isArray(d.plo_id)
        ? d.plo_id
        : d.plo_id
        ? [d.plo_id]
        : [];

      let sumPoints = 0;   // รวม (rawScore ของ PLO * หน่วยกิตของ PLO)
      let sumCredits = 0;  // รวมหน่วยกิตของ PLO ที่เกี่ยวข้อง
      let maxCredits = 0;  // รวม maxCredits ของ PLO ที่เกี่ยวข้อง

      relatedPLO.forEach((pid) => {
        if (!pid) return;
        const ploKey = pid.toString().toUpperCase();
        const plo = ploScores[ploKey];
        const ploMax = ploMaxCredits[ploKey] || (plo ? plo.maxCredits : 0) || 0;

        if (!plo || !plo.credits) return;

        const raw = plo.rawScore != null ? plo.rawScore : plo.score; // เผื่อเคสเก่า

        sumPoints += raw * plo.credits;
        sumCredits += plo.credits;
        maxCredits += ploMax;
      });

      const avg = sumCredits > 0 ? sumPoints / sumCredits : 0; // 0–4 (ดิบ)
      const gradeNorm = normalizeGrade(avg);
      const coverage = maxCredits > 0 ? Math.min(1, sumCredits / maxCredits) : 0;
      const percent = combineGradeAndCoverage(gradeNorm, coverage);

      careerScores.push({
        career_id: careerId,
        thname: d.career_thname || "",
        enname: d.career_enname || "",
        rawScore: avg,      // 0–4 ดิบของสายอาชีพ
        percent,            // 0–100 ถ่วงด้วย coverage
        gradeNorm,          // 0–1
        coverage,           // 0–1
        credits: sumCredits,
        maxCredits,
      });
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
    return res.status(500).json({ error: err.message || "Unknown error" });
  }
});
