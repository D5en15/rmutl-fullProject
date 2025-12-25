import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStudentDetail();
  }

  Future<void> _loadStudentDetail() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.studentId)
          .get();
      if (!userDoc.exists) {
        throw Exception('Student not found');
      }
      final user = userDoc.data()!;
      final email = (user['user_email'] ?? '').toString();
      final reportRef = userDoc.reference.collection('app').doc('report');
      Map<String, dynamic>? report;

      final snap = await reportRef.get();
      if (snap.exists && snap.data() != null) {
        report = snap.data()!;
      } else if (email.isNotEmpty) {
        // fallback: trigger calc and try again
        try {
          await http.post(
            Uri.parse('https://calculatestudentmetrics-hifpdjd5kq-uc.a.run.app'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          );
          final snap2 = await reportRef.get();
          if (snap2.exists && snap2.data() != null) {
            report = snap2.data()!;
          }
        } catch (_) {}
      }

      setState(() {
        studentData = user;
        metricsData = report ?? {};
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load student: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (studentData == null) {
      return const Scaffold(body: Center(child: Text('Student not found')));
    }

    final user = studentData!;
    final metrics = metricsData ?? {};

    final name = (user['user_fullname'] ?? 'Unknown').toString();
    final email = (user['user_email'] ?? '').toString();
    final code = (user['user_code'] ?? '-').toString();
    final avatar = (user['user_img'] ?? '').toString();

    final gpa = _asDouble(metrics['field_gpa'] ?? metrics['gpa'] ?? 0);
    final gpaBySemester = Map<String, dynamic>.from(
      metrics['field_gpaBySemester'] ?? metrics['gpaBySemester'] ?? {},
    );
    final subploScores = Map<String, dynamic>.from(
      metrics['field_subploScores'] ?? metrics['subploScores'] ?? {},
    );
    final ploScores = Map<String, dynamic>.from(
      metrics['field_ploScores'] ?? metrics['ploScores'] ?? {},
    );
    final careerScores = List<Map<String, dynamic>>.from(
      metrics['field_careerScores'] ?? metrics['careerScores'] ?? [],
    );

    // Top PLO
    String topPloDesc = 'No description available';
    double topPloValue = -1;
    ploScores.forEach((key, val) {
      final score = _asDouble(val['score'] ?? 0);
      if (key.toUpperCase() == 'PLO1') return;
      if (score > topPloValue) {
        topPloValue = score;
        topPloDesc = (val['description'] ?? key).toString();
      }
    });

    // Skill strengths from subPLO
    List<Map<String, dynamic>> skills = [];
    subploScores.forEach((key, val) {
      final score = _asDouble(val['score'] ?? 0);
      final percent = ((score / 4.0) * 100).clamp(0, 100).toInt();
      skills.add({
        'title': (val['description'] ?? key).toString(),
        'percent': percent,
      });
    });
    skills.sort((a, b) => (b['percent'] as int).compareTo(a['percent'] as int));
    skills = skills.take(5).toList();

    final sortedCareers = List<Map<String, dynamic>>.from(careerScores)
      ..sort((a, b) => (_asDouble(b['percent']) ).compareTo(_asDouble(a['percent'])));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Student Detail',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: const Color(0xFFE8EDFF),
                    backgroundImage:
                        avatar.isNotEmpty ? NetworkImage(avatar) : null,
                    child: avatar.isEmpty
                        ? const Icon(Icons.person, size: 34, color: Colors.black54)
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, fontSize: 20),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text('ID: $code',
                      style: const TextStyle(color: _muted),
                      textAlign: TextAlign.center),
                  Text(email,
                      style: const TextStyle(color: _muted),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Message'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              _GpaCard(gpa: gpa),
              const SizedBox(height: 16),

              _GradeProgressCard(gpaBySemester: gpaBySemester),
              const SizedBox(height: 16),

              _TopStrengthChip(description: topPloDesc),
              const SizedBox(height: 16),

              _SkillStrengths(skills: skills),
              const SizedBox(height: 16),

              _RecommendedCareers(
                careers: sortedCareers,
                subploScores: subploScores,
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
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
    final entries = gpaBySemester.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final mapped = entries
        .map((e) => {
              'label': e.key,
              'value': (e.value is Map && (e.value as Map).containsKey('gpa'))
                  ? ((e.value as Map)['gpa'] as num).toDouble()
                  : (e.value as num?)?.toDouble() ?? 0,
            })
        .toList();
    final values = mapped.map((e) => e['value'] as double).toList();
    final labels = mapped.map((e) => e['label'] as String).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      child: PhysicalModel(
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
                width: double.infinity,
                height: 220,
                child: CustomPaint(
                  painter: _LineChartPainter(values, labels),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  final List<double> data;
  final List<String> labels;
  _LineChartPainter(this.data, this.labels);

  @override
  void paint(Canvas canvas, Size size) {
    const maxY = 4.0;
    const minY = 0.0;
    const double paddingLeft = 40;
    const double paddingRight = 20;
    const double paddingBottom = 40;
    final chartWidth = size.width - paddingLeft - paddingRight;
    final chartHeight = size.height - paddingBottom;

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8;
    final linePaint = Paint()
      ..color = _primary
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = _primary;

    for (int i = 0; i <= 4; i++) {
      final y = chartHeight - (i / 4) * chartHeight;
      canvas.drawLine(
          Offset(paddingLeft, y), Offset(paddingLeft + chartWidth, y), gridPaint);
      final tp = TextPainter(
        text: TextSpan(
          text: i.toString(),
          style: const TextStyle(fontSize: 10, color: Colors.black54),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(paddingLeft - tp.width - 6, y - 6));
    }

    if (data.isEmpty) return;
    final dx = data.length > 1 ? chartWidth / (data.length - 1) : chartWidth;
    final path = Path();

    for (int i = 0; i < data.length; i++) {
      final x = paddingLeft + i * dx;
      final y = chartHeight - ((data[i] - minY) / (maxY - minY)) * chartHeight;
      if (i == 0) path.moveTo(x, y);
      else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 3, dotPaint);

      final tpVal = TextPainter(
        text: TextSpan(
          text: data[i].toStringAsFixed(2),
          style: const TextStyle(fontSize: 10, color: _primary),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tpVal.paint(canvas, Offset(x - tpVal.width / 2, y - 15));

      if (i < labels.length) {
        final tpLbl = TextPainter(
          text: TextSpan(
            text: labels[i],
            style: const TextStyle(fontSize: 10, color: Colors.black87),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        canvas.save();
        canvas.translate(x, chartHeight + 24);
        canvas.rotate(-0.785398); // -45 deg
        tpLbl.paint(canvas, Offset(-tpLbl.width / 2, 0));
        canvas.restore();
      }
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) => true;
}

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
              final title = e['title'] as String? ?? '';
              final percent = (e['percent'] as num?)?.toInt() ?? 0;
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

class _RecommendedCareers extends StatefulWidget {
  const _RecommendedCareers({
    required this.careers,
    required this.subploScores,
  });
  final List<Map<String, dynamic>> careers;
  final Map<String, dynamic> subploScores;

  @override
  State<_RecommendedCareers> createState() => _RecommendedCareersState();
}

class _RecommendedCareersState extends State<_RecommendedCareers> {
  late Future<Map<String, Map<String, dynamic>>> _detailFuture;
  final Set<String> _expanded = {};

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadCareerDetails();
  }

  Future<Map<String, Map<String, dynamic>>> _loadCareerDetails() async {
    final Map<String, Map<String, dynamic>> result = {};
    final futures = widget.careers.map((career) async {
      final careerId = (career['career_id'] ?? career['id'] ?? '').toString();
      if (careerId.isEmpty) return;
      final snap = await FirebaseFirestore.instance
          .collection('career')
          .doc(careerId)
          .get();
      if (!snap.exists) return;
      result[careerId] = snap.data() ?? {};
    });
    await Future.wait(futures);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.careers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('No recommended careers available',
            style: TextStyle(color: Colors.black54)),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0),
      child: FutureBuilder<Map<String, Map<String, dynamic>>>(
        future: _detailFuture,
        builder: (context, snapshot) {
          final details = snapshot.data ?? {};

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recommended careers',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
              const SizedBox(height: 12),
              ...widget.careers.map((career) {
                final id = (career['career_id'] ?? career['id'] ?? '').toString();
                final name = career['enname'] ?? 'Unknown Career';
                final thname = career['thname'] ?? '';
                final percent = (_asDouble(career['percent']) * 1).round();
                final detail = details[id] ?? {};

                final coreIds =
                    List<String>.from(detail['core_subplo_id'] ?? const []);
                final supportIds =
                    List<String>.from(detail['support_subplo_id'] ?? const []);

                final coreSkills = _buildSkillList(coreIds);
                final supportSkills = _buildSkillList(supportIds);

                final isExpanded = _expanded.contains(id);

                return Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expanded.remove(id);
                            } else {
                              _expanded.add(id);
                            }
                          });
                        },
                        leading: const Icon(Icons.work_outline,
                            color: _primary),
                        title: Text(name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text(thname),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                    color: _primary, width: 1),
                              ),
                              child: Text(
                                "$percent%",
                                style: const TextStyle(
                                  color: _primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              isExpanded
                                  ? Icons.expand_less
                                  : Icons.expand_more,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                      if (isExpanded) ...[
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (coreSkills.isNotEmpty) ...[
                                const Text(
                                  'Core skills',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                ...coreSkills
                                    .map((s) => _SkillLine(
                                          label: s.title,
                                          percent: s.percent,
                                        ))
                                    .toList(),
                                const SizedBox(height: 12),
                              ],
                              if (supportSkills.isNotEmpty) ...[
                                const Text(
                                  'Support skills',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14),
                                ),
                                const SizedBox(height: 8),
                                ...supportSkills
                                    .map((s) => _SkillLine(
                                          label: s.title,
                                          percent: s.percent,
                                        ))
                                    .toList(),
                              ],
                              if (coreSkills.isEmpty && supportSkills.isEmpty)
                                const Text(
                                  'No skill details available',
                                  style: TextStyle(
                                      color: Colors.black54, fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<_SkillEntry> _buildSkillList(List<String> ids) {
    final List<_SkillEntry> items = [];
    for (final id in ids) {
      final dynamic raw = widget.subploScores[id];
      if (raw is Map && raw.containsKey('score')) {
        final double score = _asDouble(raw['score']);
        final String title = (raw['description'] as String?) ?? id;
        final int percent = ((score / 4.0) * 100).clamp(0, 100).round();
        items.add(_SkillEntry(title: title, percent: percent));
      }
    }
    items.sort((a, b) => b.percent.compareTo(a.percent));
    return items;
  }

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }
}

class _SkillEntry {
  _SkillEntry({required this.title, required this.percent});
  final String title;
  final int percent;
}

class _SkillLine extends StatelessWidget {
  const _SkillLine({required this.label, required this.percent});
  final String label;
  final int percent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13.5, color: Colors.black87),
            ),
          ),
          Text(
            '$percent%',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
