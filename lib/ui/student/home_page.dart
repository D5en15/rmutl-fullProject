// lib/ui/student/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  // THEME TOKENS
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _bgSoft = Color(0xFFF6F7FF);
  static const _accentOrange = Color(0xFFFF7A50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: const [
              _HeaderWithFloatingGpa(),
              SizedBox(height: 90),
              _GradeProgressCard(),
              SizedBox(height: 16),
              _TopStrengthChip(),
              SizedBox(height: 12),
              _SkillStrengths(),
              SizedBox(height: 12),
              _RecommendedCareers(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🔵 Header + GPA ลอยคาบขอบ
/// -----------------------------------------------------------------
class _HeaderWithFloatingGpa extends StatelessWidget {
  const _HeaderWithFloatingGpa();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: const [
        _BlueHeader(),
        Positioned(
          left: 16,
          right: 16,
          bottom: -86,
          child: _GpaCompactCard(),
        ),
      ],
    );
  }
}

class _BlueHeader extends StatelessWidget {
  const _BlueHeader();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170,
      decoration: const BoxDecoration(color: StudentHomePage._primary),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(_uid).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          }
          final data = snapshot.data!.data() as Map<String, dynamic>? ?? {};
          final user = FirebaseAuth.instance.currentUser;
          final username = data['username'] ?? user?.displayName ?? 'Student';
          final photoUrl = data['avatar'] as String?;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🔔 Notifications
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => context.go('/student/notifications'),
                child: const Padding(
                  padding: EdgeInsets.all(4.0),
                  child: Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(width: 12),

              // 👋 Username
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Hi, $username',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Let's start learning",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // 👤 Avatar
              CircleAvatar(
                radius: 22,
                backgroundColor: Colors.white,
                backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                    ? NetworkImage(photoUrl)
                    : null,
                child: (photoUrl == null || photoUrl.isEmpty)
                    ? const Icon(Icons.person, color: Colors.black54, size: 22)
                    : null,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🧾 GPA card (ลอยคาบขอบ)
// -----------------------------------------------------------------
class _GpaCompactCard extends StatelessWidget {
  const _GpaCompactCard();

  double _gradeToPoint(String grade) {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return -1; // W, I, S, U, AU → ไม่คิด
    }
  }

  Future<double> _calculateGpa(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .get();

    double totalPoints = 0;
    double totalCredits = 0;

    for (var doc in snap.docs) {
      final data = doc.data();
      final grade = data['grade'] as String? ?? '';
      final creditsText =
          (data['credits'] as String? ?? '0').split('(').first.trim();
      final credits = double.tryParse(creditsText) ?? 0;

      final point = _gradeToPoint(grade);
      if (point >= 0) {
        totalPoints += point * credits;
        totalCredits += credits;
      }
    }

    return totalCredits > 0 ? totalPoints / totalCredits : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<double>(
      future: _calculateGpa(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final gpa = snapshot.data!;
        final maxGpa = 4.0;
        final value = (gpa / maxGpa).clamp(0.0, 1.0);

        return PhysicalModel(
          color: Colors.white,
          elevation: 10,
          shadowColor: Colors.black12,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Grade point average',
                        style: TextStyle(fontSize: 12.5, color: Colors.black54),
                      ),
                    ),
                    InkWell(
                      onTap: () => context.go('/student/subjects'),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: StudentHomePage._bgSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'My Subject',
                          style: TextStyle(
                            color: StudentHomePage._primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(gpa.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 26, fontWeight: FontWeight.w800)),
                    const SizedBox(width: 6),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child:
                          Text('/ 4.00', style: TextStyle(color: Colors.black45)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    minHeight: 6,
                    value: value,
                    backgroundColor: const Color(0xFFF3E8E4),
                    valueColor:
                        const AlwaysStoppedAnimation(StudentHomePage._accentOrange),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// -----------------------------------------------------------------
/// 📈 Grade progress (พื้นหลังขาว)
// -----------------------------------------------------------------
class _GradeProgressCard extends StatelessWidget {
  const _GradeProgressCard();

  double _gradeToPoint(String grade) {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return -1;
    }
  }

  Future<Map<String, double>> _calculateGpaBySemester(String uid) async {
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .get();

    final Map<String, List<double>> semPoints = {};
    final Map<String, List<double>> semCredits = {};

    for (var doc in snap.docs) {
      final data = doc.data();
      final grade = data['grade'] as String? ?? '';
      final semester = data['semester'] as String? ?? '';
      final creditsText =
          (data['credits'] as String? ?? '0').split('(').first.trim();
      final credits = double.tryParse(creditsText) ?? 0;

      final point = _gradeToPoint(grade);
      if (point >= 0) {
        semPoints.putIfAbsent(semester, () => []);
        semCredits.putIfAbsent(semester, () => []);
        semPoints[semester]!.add(point * credits);
        semCredits[semester]!.add(credits);
      }
    }

    final Map<String, double> semGpa = {};
    semPoints.forEach((sem, pts) {
      final totalPts = pts.fold(0.0, (a, b) => a + b);
      final totalCrd = semCredits[sem]!.fold(0.0, (a, b) => a + b);
      semGpa[sem] = totalCrd > 0 ? totalPts / totalCrd : 0.0;
    });

    return semGpa;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<Map<String, double>>(
      future: _calculateGpaBySemester(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final semGpa = snapshot.data!;
        final semesters = semGpa.keys.toList()..sort();
        final values = semesters.map((s) => semGpa[s] ?? 0.0).toList();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PhysicalModel(
            color: Colors.white,
            elevation: 3,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Expanded(
                        child: Text('Grade progress',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 18)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'GPA by semester',
                    style: TextStyle(color: StudentHomePage._muted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: _LineChartPainter(values),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children:
                        semesters.map((s) => _AxisLabel(s)).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(color: StudentHomePage._muted, fontSize: 12));
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()..color = const Color(0xFFEFF1F7)..strokeWidth = 1;
    final border = Paint()..color = const Color(0xFFE1E3EC)..strokeWidth = 1;

    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * (i / steps);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), i == steps ? border : grid);
    }

    const maxY = 4.0, minY = 0.0;
    final dx = data.length > 1 ? size.width / (data.length - 1) : size.width;
    final path = Path();
    final line = Paint()
      ..color = StudentHomePage._primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = StudentHomePage._primary;

    for (var i = 0; i < data.length; i++) {
      final x = i * dx;
      final v = data[i].clamp(minY, maxY);
      final y = size.height - ((v - minY) / (maxY - minY)) * size.height;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3.5, dot);
    }
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

/// -----------------------------------------------------------------
/// 🔥 Top strength chip (mock ไว้ก่อน)
/// -----------------------------------------------------------------
class _TopStrengthChip extends StatelessWidget {
  const _TopStrengthChip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: StudentHomePage._bgSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.local_fire_department_outlined,
                color: StudentHomePage._primary),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Top strength: Data Analysis 86%',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🧠 Skill strengths (real from Firestore)
/// -----------------------------------------------------------------
class _SkillStrengths extends StatelessWidget {
  const _SkillStrengths();

  double _gradeToPoint(String grade) {
    switch (grade) {
      case 'A':
        return 4.0;
      case 'B+':
        return 3.5;
      case 'B':
        return 3.0;
      case 'C+':
        return 2.5;
      case 'C':
        return 2.0;
      case 'D+':
        return 1.5;
      case 'D':
        return 1.0;
      case 'F':
        return 0.0;
      default:
        return -1; // W, I, S, U, AU → ไม่คิด
    }
  }

  Future<List<Map<String, dynamic>>> _calculateSkillStrengths(String uid) async {
    final userSubsSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .get();

    Map<String, double> skillScores = {};
    Map<String, double> skillMax = {};

    for (var doc in userSubsSnap.docs) {
      final data = doc.data();
      final subjectId = data['subjectId'];
      final grade = data['grade'] as String? ?? '';
      final credits = (data['credits'] is int)
          ? data['credits'].toDouble()
          : double.tryParse(data['credits'].toString()) ?? 0;

      final point = _gradeToPoint(grade);
      if (point < 0) continue;

      // ดึง mapping subject → skills
      final mapDoc = await FirebaseFirestore.instance
          .collection('subject_skill_map')
          .doc(subjectId)
          .get();

      if (!mapDoc.exists) continue;
      final skills = mapDoc.data()!['skills'] as List<dynamic>;

      for (var s in skills) {
        final skillId = s['skillId'];
        final weight = (s['weight'] as num).toDouble();

        final score = point * credits * weight;
        skillScores[skillId] = (skillScores[skillId] ?? 0) + score;

        // เก็บค่า max ที่เป็นไปได้ (4.0 × credits × weight)
        final maxScore = 4.0 * credits * weight;
        skillMax[skillId] = (skillMax[skillId] ?? 0) + maxScore;
      }
    }

    // ดึงชื่อ skill จาก skills collection
    List<Map<String, dynamic>> results = [];
    for (var entry in skillScores.entries) {
      final skillId = entry.key;
      final score = entry.value;
      final max = skillMax[skillId] ?? 1;

      final skillDoc = await FirebaseFirestore.instance
          .collection('skills')
          .doc(skillId)
          .get();
      final skillName = skillDoc.data()?['name'] ?? skillId;

      results.add({
        'name': skillName,
        'percent': ((score / max) * 100).clamp(0, 100),
      });
    }

    // เรียงจากมากไปน้อย
    results.sort((a, b) => (b['percent']).compareTo(a['percent']));
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _calculateSkillStrengths(uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final skills = snapshot.data!;
        if (skills.isEmpty) {
          return const Center(child: Text("No skill data yet"));
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: PhysicalModel(
            color: Colors.white,
            elevation: 2,
            shadowColor: Colors.black12,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Skill strengths',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  ...skills.map((e) => _SkillBar(
                        title: e['name'],
                        percent: (e['percent'] as double).round(),
                      )),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// -----------------------------------------------------------------
/// 💼 Recommended careers (mock ไว้ก่อน)
/// -----------------------------------------------------------------
class _RecommendedCareers extends StatelessWidget {
  const _RecommendedCareers();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Recommended careers',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          SizedBox(height: 10),
          _CareerItem(
            title: 'Software Engineer',
            tags: ['Python', 'SQL'],
            score: 82,
            icon: Icons.code,
          ),
          SizedBox(height: 10),
          _CareerItem(
            title: 'Data Analyst',
            tags: ['Excel', 'SQL', 'Power BI'],
            score: 78,
            icon: Icons.analytics_outlined,
          ),
        ],
      ),
    );
  }
}

class _CareerItem extends StatelessWidget {
  const _CareerItem({
    required this.title,
    required this.tags,
    required this.score,
    required this.icon,
  });

  final String title;
  final List<String> tags;
  final int score;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: StudentHomePage._bgSoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: StudentHomePage._primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: -6,
                    children: tags
                        .map(
                          (t) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Color(0xFFF1F2F6),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child:
                                Text(t, style: const TextStyle(fontSize: 12)),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: StudentHomePage._bgSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '$score%',
                style: const TextStyle(
                    color: StudentHomePage._primary,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.title, required this.percent});
  final String title;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final value = percent / 100.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
            Text('$percent%'),
          ]),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: value,
              minHeight: 8,
              backgroundColor: const Color(0xFFE8EAFF),
              valueColor:
                  const AlwaysStoppedAnimation(StudentHomePage._primary),
            ),
          ),
        ],
      ),
    );
  }
}