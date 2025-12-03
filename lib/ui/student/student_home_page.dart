// lib/ui/student/home_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  // THEME TOKENS
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _bgSoft = Color(0xFFF6F7FF);
  static const _accentOrange = Color(0xFFFF7A50);

  Future<Map<String, dynamic>> _fetchMetrics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final email = user.email;
    final url = Uri.parse(
      "https://calculatestudentmetrics-hifpdjd5kq-uc.a.run.app",
    );

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );

    if (response.statusCode != 200) {
      throw Exception("Error: ${response.body}");
    }
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>?> _loadUserProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final qs = await FirebaseFirestore.instance
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (qs.docs.isEmpty) return null;
    return qs.docs.first.data();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (!authSnapshot.hasData) {
              return const Center(child: Text("⚠ กรุณาล็อกอินก่อนเข้าหน้านี้"));
            }

            return FutureBuilder<List<dynamic>>(
              future: Future.wait([
                _fetchMetrics(),
                _loadUserProfile(),
              ]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      "❌ Error: ${snapshot.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(child: Text("ไม่พบข้อมูลจากระบบ"));
                }

                final metrics = snapshot.data![0] as Map<String, dynamic>;
                final userProfile =
                    snapshot.data!.length > 1 && snapshot.data![1] != null
                        ? snapshot.data![1] as Map<String, dynamic>
                        : null;

                final gpa = (metrics['gpa'] as num?)?.toDouble() ?? 0;
                final gpaBySemester =
                    Map<String, dynamic>.from(metrics['gpaBySemester'] ?? {});
                final subploScores =
                    Map<String, dynamic>.from(metrics['subploScores'] ?? {});
                final ploScores =
                    Map<String, dynamic>.from(metrics['ploScores'] ?? {});
                final careerScores =
                    List<Map<String, dynamic>>.from(metrics['careerScores'] ?? []);
                final avatarUrl =
                    (userProfile?['user_img'] as String?)?.trim();

                // ✅ หา Top PLO
                String topPlo = "Unknown";
                String topPloDesc = "No description available";
                double topPloValue = -1;

                ploScores.forEach((key, val) {
                  final double score = (val["score"] as num).toDouble();
                  if (key.toUpperCase() == "PLO1") return;
                  if (score > topPloValue) {
                    topPloValue = score;
                    topPlo = key;
                    final desc = val["description"] ?? key;
                    topPloDesc = desc;
                  }
                });

                // ✅ SubPLO → skills (Top 5)
                List<Map<String, dynamic>> skills = [];
                subploScores.forEach((key, val) {
                  final double score = (val["score"] as num).toDouble();
                  final desc = val["description"] ?? key;
                  final percent =
                      ((score / 4.0) * 100).clamp(0, 100).toInt();
                  skills.add({
                    "title": desc,
                    "percent": percent,
                  });
                });

                skills.sort((a, b) =>
                    (b['percent'] as int).compareTo(a['percent'] as int));
                skills = skills.take(5).toList();

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      _HeaderWithFloatingGpa(
                        roleLabel: 'Student',
                        subtitle:
                            'Track progress and unlock personalized career skills.',
                        gpa: gpa,
                        photoUrl: avatarUrl,
                        onProfileTap: () => context.go(
                          '/profile/edit',
                          extra: const {'role': 'student'},
                        ),
                      ),
                      const SizedBox(height: 100),
                      _GradeProgressCard(gpaBySemester: gpaBySemester),
                      const SizedBox(height: 16),
                      _TopStrengthChip(
                        topPlo: topPlo,
                        description: topPloDesc,
                      ),
                      const SizedBox(height: 12),
                      _SkillStrengths(skills: skills),
                      const SizedBox(height: 24),
                      _RecommendedCareers(careers: careerScores), // 👈 เพิ่มตรงนี้
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🔵 Header + GPA Floating
/// -----------------------------------------------------------------
class _HeaderWithFloatingGpa extends StatelessWidget {
  const _HeaderWithFloatingGpa({
    required this.roleLabel,
    required this.subtitle,
    required this.gpa,
    required this.photoUrl,
    required this.onProfileTap,
  });
  final String roleLabel;
  final String subtitle;
  final double gpa;
  final String? photoUrl;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        _BlueHeader(
          roleLabel: roleLabel,
          subtitle: subtitle,
          photoUrl: photoUrl,
          onProfileTap: onProfileTap,
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: -60,
          child: _GpaCompactCard(gpa: gpa),
        ),
      ],
    );
  }
}

class _BlueHeader extends StatelessWidget {
  const _BlueHeader({
    required this.roleLabel,
    required this.subtitle,
    required this.photoUrl,
    required this.onProfileTap,
  });
  final String roleLabel;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: const BoxDecoration(color: StudentHomePage._primary),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => context.go('/student/notifications'),
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.notifications_none_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  roleLabel,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: onProfileTap,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white,
              backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                  ? NetworkImage(photoUrl!)
                  : null,
              child: (photoUrl == null || photoUrl!.isEmpty)
                  ? const Icon(Icons.person, color: Colors.black54, size: 22)
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🧾 GPA Card
/// -----------------------------------------------------------------
class _GpaCompactCard extends StatelessWidget {
  const _GpaCompactCard({required this.gpa});
  final double gpa;

  @override
  Widget build(BuildContext context) {
    final progressValue = (gpa / 4.0).clamp(0.0, 1.0);
    return PhysicalModel(
      color: Colors.white,
      elevation: 10,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Expanded(
                  child: Text(
                    'Grade point average',
                    style: TextStyle(fontSize: 12.5, color: Colors.black54),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  gpa.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                const Text('/ 4.00', style: TextStyle(color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              minHeight: 6,
              value: progressValue,
              backgroundColor: const Color(0xFFF3E8E4),
              valueColor: const AlwaysStoppedAnimation(
                StudentHomePage._accentOrange,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 📈 Grade progress card
/// -----------------------------------------------------------------
class _GradeProgressCard extends StatelessWidget {
  const _GradeProgressCard({required this.gpaBySemester});
  final Map<String, dynamic> gpaBySemester;

  @override
  Widget build(BuildContext context) {
    final entries = gpaBySemester.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final mapped = entries
        .map((e) => {
              "label": _formatLabel(e.key),
              "value": (e.value as num).toDouble(),
            })
        .toList();
    final trimmed = mapped.length > 8 ? mapped.sublist(mapped.length - 8) : mapped;
    final values = trimmed.map((e) => e["value"] as double).toList();
    final labels = trimmed.map((e) => e["label"] as String).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Grade progress',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 220,
            child: CustomPaint(
              painter: _LineChartPainter(values, labels),
            ),
          ),
        ],
      ),
    );
  }

  String _formatLabel(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9/]'), '');
    final parts = cleaned.split('/');
    if (parts.length >= 2) {
      final year = int.tryParse(parts[0]) ?? parts[0];
      final term = int.tryParse(parts[1]) ?? parts[1];
      return "Y$year · T$term";
    }
    return raw;
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data, this.labels);
  final List<double> data;
  final List<String> labels;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint axis = Paint()
      ..color = Colors.black26
      ..strokeWidth = 1;

    final Paint line = Paint()
      ..color = StudentHomePage._primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final Paint dot = Paint()
      ..color = StudentHomePage._primary
      ..style = PaintingStyle.fill;

    final double paddingLeft = 30;
    final double paddingBottom = 28;
    final chartWidth = size.width - paddingLeft;
    final chartHeight = size.height - paddingBottom;

    canvas.drawLine(
      Offset(paddingLeft, chartHeight),
      Offset(size.width, chartHeight),
      axis,
    );
    canvas.drawLine(
      Offset(paddingLeft, 0),
      Offset(paddingLeft, chartHeight),
      axis,
    );

    const maxGrade = 4;
    for (int g = 0; g <= maxGrade; g++) {
      final y = chartHeight - (g / maxGrade) * chartHeight;
      final tp = TextPainter(
        text: TextSpan(
          text: g.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 6));

      canvas.drawLine(
        Offset(paddingLeft, y),
        Offset(size.width, y),
        Paint()
          ..color = Colors.grey.shade200
          ..strokeWidth = 0.5,
      );
    }

    if (data.isEmpty) return;
    final dx = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * dx;
      final y = chartHeight - (data[i] / maxGrade) * chartHeight;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
      canvas.drawCircle(Offset(x, y), 3, dot);

      if (i < labels.length) {
        final tp = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(fontSize: 10, color: Colors.black54),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 6));
      }
    }

    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

/// -----------------------------------------------------------------
/// 🔥 Top strength chip
/// -----------------------------------------------------------------
class _TopStrengthChip extends StatelessWidget {
  const _TopStrengthChip({
    required this.topPlo,
    required this.description,
  });

  final String topPlo;
  final String description;

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
        child: Row(
          children: [
            const Icon(Icons.local_fire_department_outlined,
                color: StudentHomePage._primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(description,
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 🧠 Skill strengths (Top 5 SubPLO)
/// -----------------------------------------------------------------
class _SkillStrengths extends StatelessWidget {
  const _SkillStrengths({required this.skills});
  final List<Map<String, dynamic>> skills;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhysicalModel(
        color: Colors.white,
        elevation: 2,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skill strengths',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...skills.map((e) {
                final title = e['title'] as String? ?? "Unknown";
                final percent = (e['percent'] as num?)?.toInt() ?? 0;
                return _SkillBar(title: title, percent: percent);
              }),
            ],
          ),
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
    final double value = percent.toDouble() / 100.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: value,
            minHeight: 8,
            backgroundColor: const Color(0xFFE8EAFF),
            valueColor:
                const AlwaysStoppedAnimation(StudentHomePage._primary),
          ),
        ],
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 💼 Recommended careers (จาก Cloud Function)
/// -----------------------------------------------------------------
class _RecommendedCareers extends StatelessWidget {
  const _RecommendedCareers({required this.careers});
  final List<Map<String, dynamic>> careers;

  @override
  Widget build(BuildContext context) {
    if (careers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text("No recommended careers available",
            style: TextStyle(color: Colors.black54)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recommended careers',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 12),
          ...careers.map((career) {
            final name = career["enname"] ?? "Unknown Career";
            final thname = career["thname"] ?? "";
            final percent = (career["percent"] as num?)?.toInt() ?? 0;

            return Card(
              color: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.black.withOpacity(0.05)),
              ),
              child: ListTile(
                leading: const Icon(Icons.work_outline,
                    color: StudentHomePage._primary),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(thname),
                trailing: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: StudentHomePage._primary, width: 1),
                  ),
                  child: Text(
                    "$percent%",
                    style: const TextStyle(
                        color: StudentHomePage._primary,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
