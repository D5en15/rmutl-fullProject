const {onRequest} = require("firebase-functions/v2/https");
const {onDocumentWritten} = require("firebase-functions/v2/firestore");
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

// Е1?Е,>Е,ЭЕ,╪Е,,Е,°Е1?Е,TЕ,TЕ1?Е,%Е,ЭЕ,цЕ1^Е,Ы 0Г?"4 -> 0Г?"1 Е1,Е,"Е,ЫЕ,-Е,·Е,-Е,Е1^Е,¤ C = 0, A = 1
function normalizeGrade(avgPoint) {
  const norm = (avgPoint - 2.0) / 2.0; // 2 -> 0, 4 -> 1
  return Math.max(0, Math.min(1, norm));
}

// Гo. Е1ЯЕ,SЕ1% "Е1?Е,?Е,ЬЕ,"" + "coverage" Е1?Е,sЕ,sЕ,-Е1^Е,Е,╪Е,TЕ1%Е,3Е,оЕ,TЕ,ёЕ,? (Е1?Е,TЕ1%Е,TЕ1?Е,?Е,ЬЕ," 60% coverage 40%)
function combineGradeAndCoverage(gradeNorm, coverage) {
  const g = Math.max(0, Math.min(1, gradeNorm || 0));
  const c = Math.max(0, Math.min(1, coverage || 0));
  const score01 = 0.6 * g + 0.4 * c; // 0..1
  return Math.round(score01 * 100);  // 0..100
}

function sanitizeId(value) {
  if (!value) return "";
  return value.toString().replace(/[^0-9A-Za-z]/g, "");
}

async function calculateMetricsForUserId(userId, userData, docId) {
  // 2) preload subjects
  const subjectSnap = await admin.firestore().collection("subject").get();

  const subjectsMap = {};        // doc.id -> data
  const subploMaxCredits = {};   // "1A"  -> total possible credits
  const ploMaxCredits = {};      // "PLO1" -> total possible credits

  subjectSnap.forEach((doc) => {
    const subj = doc.data();
    subjectsMap[doc.id] = subj;
    const subjectIdField = (subj.subject_id || "").toString();
    if (subjectIdField) {
      subjectsMap[subjectIdField] = subj; // map ด้วย subject_id ด้วย เผื่อ doc id ไม่ตรง
    }

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

      // PLO "1A" -> "PLO1"
      const ploId = "PLO" + skill[0];
      if (!ploMaxCredits[ploId]) ploMaxCredits[ploId] = 0;
      ploMaxCredits[ploId] += share;
    }
  });

  // 3) enrollment of user (รองรับหลายรูปแบบ user_id/user_code)
  const candidates = new Set();
  if (userId) candidates.add(userId.toString());
  if (docId) candidates.add(docId.toString());
  if (userData && userData.user_code) candidates.add(userData.user_code.toString());
  if (userData && userData.user_id) candidates.add(userData.user_id.toString());
  // sanitized version (ลบเครื่องหมาย)
  [...candidates].forEach((v) => {
    const cleaned = sanitizeId(v);
    if (cleaned && cleaned !== v) candidates.add(cleaned);
  });

  const idList = [...candidates].filter((v) => v);

  let enrollSnap;
  const enrollCol = admin.firestore().collection("enrollment");
  if (idList.length === 0) {
    enrollSnap = await enrollCol.limit(0).get();
  } else if (idList.length === 1) {
    enrollSnap = await enrollCol.where("user_id", "==", idList[0]).get();
  } else {
    // Firestore 'in' รองรับสูงสุด 10 ค่า
    const limited = idList.slice(0, 10);
    enrollSnap = await enrollCol.where("user_id", "in", limited).get();
  }

  if (enrollSnap.empty) {
    return {
      gpa: 0,
      gpaBySemester: {},
      subploScores: {},
      ploScores: {},
      careerScores: []
    };
  }

  // accumulators
  let totalPoints = 0;
  let totalCredits = 0;
  const semPoints = {};
  const semCredits = {};

  const subploStats = {}; // { '1A': { points, credits } }
  const ploStats = {};    // { 'PLO1': { points, credits } }

  // 4) loop enrollment
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

    // GPA aggregates
    totalPoints += point * credits;
    totalCredits += credits;
    semPoints[semester] = (semPoints[semester] || 0) + point * credits;
    semCredits[semester] = (semCredits[semester] || 0) + credits;

    // Skills
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

  // 5) GPA summary
  const gpa = totalCredits > 0 ? totalPoints / totalCredits : 0;
  const gpaBySemester = {};
  Object.keys(semPoints).forEach((sem) => {
    const pts = semPoints[sem];
    const crd = semCredits[sem] || 0;
    gpaBySemester[sem] = crd > 0 ? pts / crd : 0;
  });

  // 6) descriptions
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

  // 7) SubPLO scores
  const subploScores = {};
  Object.keys(subploStats).forEach((skill) => {
    const { points, credits } = subploStats[skill];
    const avg = credits > 0 ? points / credits : 0; // 0-4

    const gradeNorm = normalizeGrade(avg);      // 0-1
    const maxCredits = subploMaxCredits[skill] || credits || 0;
    const coverage = maxCredits > 0 ? Math.min(1, credits / maxCredits) : 0; // 0-1

    const percent = combineGradeAndCoverage(gradeNorm, coverage); // 0-100
    const weight01 = percent / 100;          // 0-1
    const weightedScore = weight01 * 4;      // 0-4

    subploScores[skill] = {
      rawScore: avg,
      score: weightedScore,
      percent,                    // 0-100
      gradeNorm,                  // 0-1
      coverage,                   // 0-1
      credits,
      maxCredits,
      description: subploMap[skill] || skill
    };
  });

  // 8) PLO scores
  const ploScores = {};
  Object.keys(ploStats).forEach((ploId) => {
    const { points, credits } = ploStats[ploId];
    const avg = credits > 0 ? points / credits : 0; // 0-4

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

  // 9) Career mapping
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

    // coverage helpers
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

      const p = sub && typeof sub.percent === "number" ? sub.percent : 0; // 0-100

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
      percent,
      rawScore: avgRaw,
      gradeNorm: gradeNormCareer,
      coverage: coverageCareer,
      credits: sumCredits,
      maxCredits: maxCreditsCareer
    });
  });

  return {
    gpa,
    gpaBySemester,
    subploScores,
    ploScores,
    careerScores
  };
}

async function persistMetrics(userDocRef, metrics) {
  await userDocRef.collection("app").doc("report").set({
    field_gpa: metrics.gpa,
    field_gpaBySemester: metrics.gpaBySemester,
    field_subploScores: metrics.subploScores,
    field_ploScores: metrics.ploScores,
    field_careerScores: metrics.careerScores,
    field_updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });
}

async function calculateAndPersist({ email, userId }) {
  const db = admin.firestore();
  let userSnap;

  if (email) {
    userSnap = await db
      .collection("user")
      .where("user_email", "==", email)
      .limit(1)
      .get();
  } else if (userId) {
    // ลองจับคู่ทั้ง user_id และ user_code เผื่อข้อมูลไม่ตรงกัน
    userSnap = await db
      .collection("user")
      .where("user_id", "==", userId)
      .limit(1)
      .get();

    if (userSnap.empty) {
      userSnap = await db
        .collection("user")
        .where("user_code", "==", userId)
        .limit(1)
        .get();
    }
  }

  if (!userSnap || userSnap.empty) {
    throw new Error("User not found");
  }

  const userDoc = userSnap.docs[0];
  const userData = userDoc.data() || {};
  const resolvedUserId = userData.user_id || userData.user_code || userId || userDoc.id;

  const metrics = await calculateMetricsForUserId(resolvedUserId, userData, userDoc.id);
  await persistMetrics(userDoc.ref, metrics);

  return { metrics, userId: resolvedUserId };
}

// export helpers for reuse in bulk recalculation
module.exports.calculateMetricsForUserId = calculateMetricsForUserId;
module.exports.persistMetrics = persistMetrics;
module.exports.calculateAndPersist = calculateAndPersist;

// HTTP function (returns metrics and persists to user/app/report)
exports.calculateStudentMetrics = onRequest(async (req, res) => {
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

    const result = await calculateAndPersist({ email });
    return res.json(result.metrics);
  } catch (err) {
    console.error(err);
    return res.status(500).json({ error: err.message || "Unknown error" });
  }
});

// Firestore trigger: recalc when enrollment changes
exports.recalculateStudentMetricsOnEnrollmentChange = onDocumentWritten(
  {
    region: "asia-southeast1", // deploy Firestore trigger in the same region as the database/eventarc trigger
  },
  "enrollment/{enrollmentId}",
  async (event) => {
    const data = event.data?.after.exists
      ? event.data.after.data()
      : event.data?.before?.data();
    const userId = data && data.user_id;
    if (!userId) {
      return null;
    }

    try {
      await calculateAndPersist({ userId });
    } catch (err) {
      console.error(`Failed to recalc metrics for user_id ${userId}:`, err);
    }
    return null;
  }
);
