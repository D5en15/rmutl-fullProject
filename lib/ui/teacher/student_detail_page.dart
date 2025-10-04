import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

const _primary = Color(0xFF3D5CFF);
const _muted = Color(0xFF858597);
const _bgSoft = Color(0xFFF6F7FF);

class StudentDetailPage extends StatefulWidget {
  const StudentDetailPage({super.key, required this.studentId});
  final String studentId;

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  Map<String, dynamic>? studentData;
  Map<String, dynamic>? metricsData;

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
  }

  /// ✅ ดึงข้อมูลนักศึกษาจาก Firestore + Cloud Function เดียวกับ student_home_page.dart
  Future<void> _loadStudentDetail() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.studentId)
          .get();

      if (!userDoc.exists) throw Exception("ไม่พบนักศึกษาในระบบ");

      final user = userDoc.data()!;
      final email = user['user_email'];

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

      setState(() {
        studentData = user;
        metricsData = jsonDecode(response.body);
      });
    } catch (e) {
      debugPrint("🔥 Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (studentData == null || metricsData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = studentData!;
    final metrics = metricsData!;

    final name = user['user_fullname'] ?? "Unknown";
    final email = user['user_email'] ?? "";
    final code = user['user_code'] ?? "-";
    final room = user['user_class'] ?? "-";
    final gpa = (metrics['gpa'] as num?)?.toDouble() ?? 0;
    final gpaBySemester =
        Map<String, dynamic>.from(metrics['gpaBySemester'] ?? {});
    final subploScores =
        Map<String, dynamic>.from(metrics['subploScores'] ?? {});
    final ploScores =
        Map<String, dynamic>.from(metrics['ploScores'] ?? {});

    // ✅ ทักษะเด่น
    List<Map<String, dynamic>> skills = [];
    subploScores.forEach((key, val) {
      final double score = (val["score"] as num).toDouble();
      final desc = val["description"] ?? key;
      final percent = ((score / 4.0) * 100).clamp(0, 100).toInt();
      skills.add({
        "title": "$key: $desc",
        "percent": percent,
      });
    });
    skills.sort((a, b) => (b['percent'] as int).compareTo(a['percent'] as int));
    skills = skills.take(5).toList();

    // ✅ PLO เด่นสุด
    String topPloDesc = "No description available";
    double topPloValue = -1;

    ploScores.forEach((key, val) {
      final double score = (val["score"] as num).toDouble();
      if (key.toUpperCase() == "PLO1") return;
      if (score > topPloValue) {
        topPloValue = score;
        final desc = val["description"] ?? key;
        topPloDesc = "$desc (${score.toStringAsFixed(2)}/4.00)";
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Detail'),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFFFE3B5),
                child: Icon(Icons.person, size: 42, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(name,
                  textAlign: TextAlign.center,
                  style:
                      const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 6),
              Text('$code  •  $room\n$email',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: _muted)),
              const SizedBox(height: 16),

              // ✅ GPA Card
              _GpaCard(gpa: gpa),
              const SizedBox(height: 16),

              // ✅ Grade Progress Chart
              _GradeProgressCard(gpaBySemester: gpaBySemester),
              const SizedBox(height: 16),

              // ✅ Top Strength
              _TopStrengthChip(description: topPloDesc),
              const SizedBox(height: 16),

              // ✅ Skill Strengths
              _SkillStrengths(skills: skills),
            ],
          ),
        ),
      ),
    );
  }
}

/// GPA Card
class _GpaCard extends StatelessWidget {
  const _GpaCard({required this.gpa});
  final double gpa;

  @override
  Widget build(BuildContext context) {
    final progressValue = (gpa / 4.0).clamp(0.0, 1.0);
    return PhysicalModel(
      color: Colors.white,
      elevation: 4,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grade Point Average',
                style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(gpa.toStringAsFixed(2),
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
                const SizedBox(width: 6),
                const Text('/ 4.00', style: TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              minHeight: 8,
              value: progressValue,
              backgroundColor: const Color(0xFFE8EAFF),
              valueColor: const AlwaysStoppedAnimation(_primary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grade Progress + Subjects
class _GradeProgressCard extends StatelessWidget {
  const _GradeProgressCard({required this.gpaBySemester});
  final Map<String, dynamic> gpaBySemester;

  @override
  Widget build(BuildContext context) {
    final semesters = gpaBySemester.keys.toList()..sort();

    final values = semesters.map((s) {
      final val = gpaBySemester[s];
      return val is Map && val.containsKey('gpa')
          ? (val['gpa'] as num).toDouble()
          : (val as num).toDouble();
    }).toList();

    final subjects = <Map<String, dynamic>>[];
    for (var s in semesters) {
      final semData = gpaBySemester[s];
      if (semData is Map && semData['subjects'] != null) {
        for (var sub in List.from(semData['subjects'])) {
          subjects.add({
            "semester": s,
            "subject": sub["name"] ?? "-",
            "grade": sub["grade"] ?? "-",
          });
        }
      }
    }

    return PhysicalModel(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Grade Progress',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              width: double.infinity,
              child: CustomPaint(painter: _LineChartPainter(values, semesters)),
            ),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Subjects & Grades',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 8),
            ...subjects.map((s) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(
                          s["semester"],
                          style: const TextStyle(color: Colors.black54),
                        ),
                      ),
                      Expanded(
                        flex: 5,
                        child: Text(s["subject"],
                            style:
                                const TextStyle(fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          s["grade"].toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// 📊 Line Chart Painter
class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _LineChartPainter(this.data, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    const maxY = 4.0;
    const minY = 0.0;

    final chartHeight = size.height - 30;
    final chartWidth = size.width - 30;
    const offsetLeft = 30.0;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8;
    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = _primary;

    // 🔹 เส้นแนวนอน (เกรด 0–4)
    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (i / 4) * chartHeight;
      canvas.drawLine(
          Offset(offsetLeft, y), Offset(offsetLeft + chartWidth, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(offsetLeft - tp.width - 4, y - 6));
    }

    // 🔹 เส้นกราฟเกรด
    final dx = chartWidth / (data.length - 1);
    final path = Path();
    for (int i = 0; i < data.length; i++) {
      final x = offsetLeft + i * dx;
      final y = chartHeight - ((data[i] - minY) / (maxY - minY)) * chartHeight;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);

      // แสดงค่าตัวเลขเกรดบนจุด
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].toStringAsFixed(2),
          style: const TextStyle(fontSize: 10, color: _primary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, y - 14));
    }
    canvas.drawPath(path, linePaint);

    // 🔹 Label ปี/เทอม
    for (int i = 0; i < labels.length; i++) {
      final x = offsetLeft + i * dx;
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: const TextStyle(fontSize: 10, color: Colors.black87),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, chartHeight + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

/// 🔥 Top Strength
class _TopStrengthChip extends StatelessWidget {
  const _TopStrengthChip({required this.description});
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _bgSoft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_outlined, color: _primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(description,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

/// 🧠 Skill Strengths
class _SkillStrengths extends StatelessWidget {
  const _SkillStrengths({required this.skills});
  final List<Map<String, dynamic>> skills;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 2,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Skill Strengths',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 10),
            ...skills.map((e) {
              final title = e['title'];
              final percent = e['percent'];
              final value = (percent / 100.0);
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title)),
                        Text('$percent%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: const Color(0xFFE8EAFF),
                      valueColor: const AlwaysStoppedAnimation(_primary),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}