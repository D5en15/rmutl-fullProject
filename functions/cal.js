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

// ✅ ใช้ "เกรด" + "coverage" แบบถ่วงน้ำหนัก (เน้นเกรด 60% coverage 40%)
function combineGradeAndCoverage(gradeNorm, coverage) {
  const g = Math.max(0, Math.min(1, gradeNorm || 0));
  const c = Math.max(0, Math.min(1, coverage || 0));
  const score01 = 0.6 * g + 0.4 * c; // 0..1
  return Math.round(score01 * 100);  // 0..100
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
        careerScores: []
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

      const percent = combineGradeAndCoverage(gradeNorm, coverage); // 0–100
      const weight01 = percent / 100;          // 0–1
      const weightedScore = weight01 * 4;      // 0–4

      subploScores[skill] = {
        rawScore: avg,
        score: weightedScore,
        percent,                    // 0–100 ใช้โชว์ Skill strengths
        gradeNorm,                  // 0–1
        coverage,                   // 0–1
        credits,                    // หน่วยกิตที่เรียนแล้ว
        maxCredits,                 // หน่วยกิตสูงสุดตามหลักสูตร
        description: subploMap[skill] || skill
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
        rawScore: avg,
        score: weightedScore,
        percent,
        gradeNorm,
        coverage,
        credits,
        maxCredits,
        description: ploMap[key] || key
      };
    });

    // 9) career mapping – ใช้ percent ของ SubPLO โดยตรง + ทักษะหลัก 80% / ทักษะรอง 20%
    const CORE_WEIGHT = 0.8;
    const SUPPORT_WEIGHT = 0.2;

    const careerDocs = await admin.firestore().collection("career").get();
    const careerScores = [];

    careerDocs.forEach((doc) => {
      const d = doc.data();
      const careerId = d.career_id;
      if (!careerId) return;

      const coreSubploIds = Array.isArray(d.core_subplo_id)
        ? d.core_subplo_id
        : d.core_subplo_id
        ? [d.core_subplo_id]
        : [];

      const supportSubploIds = Array.isArray(d.support_subplo_id)
        ? d.support_subplo_id
        : d.support_subplo_id
        ? [d.support_subplo_id]
        : [];

      let corePercentSum = 0;
      let coreCount = 0;
      let supportPercentSum = 0;
      let supportCount = 0;

      // สำหรับเกรด/coverage ของสายอาชีพ
      let sumGradePoints = 0;
      let sumGradeCredits = 0;
      let sumCredits = 0;
      let maxCreditsCareer = 0;
      const usedForGrade = new Set();

      const handleSkill = (sid, isCore) => {
        if (!sid) return;

        const subKey = sid.toString().toUpperCase();
        const subMax = subploMaxCredits[subKey] || 0;
        const sub = subploScores[subKey];

        const p =
          sub && typeof sub.percent === "number" ? sub.percent : 0; // 0–100

        if (isCore) {
          corePercentSum += p;
          coreCount += 1;
        } else {
          supportPercentSum += p;
          supportCount += 1;
        }

        maxCreditsCareer += subMax;

        if (sub && !usedForGrade.has(subKey)) {
          const raw = sub.rawScore != null ? sub.rawScore : sub.score;
          const c = sub.credits || 0;
          sumGradePoints += raw * c;
          sumGradeCredits += c;
          sumCredits += c;
          usedForGrade.add(subKey);
        }
      };

      coreSubploIds.forEach((sid) => handleSkill(sid, true));
      supportSubploIds.forEach((sid) => handleSkill(sid, false));

      const coreAvg = coreCount > 0 ? corePercentSum / coreCount : null;
      const supportAvg =
        supportCount > 0 ? supportPercentSum / supportCount : null;

      let basePercent = 0;
      if (coreAvg !== null && supportAvg !== null) {
        basePercent = coreAvg * CORE_WEIGHT + supportAvg * SUPPORT_WEIGHT;
      } else if (coreAvg !== null) {
        basePercent = coreAvg;
      } else if (supportAvg !== null) {
        basePercent = supportAvg;
      }

      // clamp + ปัดให้เป็นจำนวนเต็ม
      let percent = basePercent;
      if (percent == null || Number.isNaN(percent)) percent = 0;
      percent = Math.round(Math.max(0, Math.min(100, percent)));
      const match01 = percent / 100;

      const avgRaw =
        sumGradeCredits > 0 ? sumGradePoints / sumGradeCredits : 0;
      const gradeNormCareer = normalizeGrade(avgRaw);
      const coverageCareer =
        maxCreditsCareer > 0
          ? Math.min(1, sumCredits / maxCreditsCareer)
          : 0;

      careerScores.push({
        career_id: careerId,
        thname: d.career_thname || "",
        enname: d.career_enname || "",
        match: match01,
        percent,                 // ใช้โชว์ในหน้า Recommended careers
        rawScore: avgRaw,        // 0–4 เกรดเฉลี่ยดิบของ SubPLO กลุ่มนี้
        gradeNorm: gradeNormCareer,
        coverage: coverageCareer,
        credits: sumCredits,
        maxCredits: maxCreditsCareer
      });
    });

    return res.json({
      gpa,
      gpaBySemester,
      subploScores,
      ploScores,
      careerScores
    });
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message || "Unknown error" });
  }
});
