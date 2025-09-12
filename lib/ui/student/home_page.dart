import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 170, // จะลด/เพิ่มได้ตามชอบ
      decoration: const BoxDecoration(color: StudentHomePage._primary),
      // เว้นระยะด้านบนล่างให้พอดี
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 🔔 กระดิ่ง (ซ้าย)
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

          // 👋 กลาง: Hi, Smith + subtitle (จัดกึ่งกลางแนวตั้ง)
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Hi, Smith',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Let's start learning",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // 👤 Avatar (ขวา)
          const CircleAvatar(
            radius: 22,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, color: Colors.black54, size: 22),
          ),
        ],
      ),
    );
  }
}


/// -----------------------------------------------------------------
/// 🧾 GPA card (ลอยคาบขอบ)
// -----------------------------------------------------------------
class _GpaCompactCard extends StatelessWidget {
  const _GpaCompactCard();

  @override
  Widget build(BuildContext context) {
    const gpa = 3.42;
    const maxGpa = 4.00;
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
              children: const [
                Text('3.42',
                    style:
                        TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                SizedBox(width: 6),
                Padding(
                  padding: EdgeInsets.only(bottom: 2),
                  child: Text('/ 4.00', style: TextStyle(color: Colors.black45)),
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
                valueColor: const AlwaysStoppedAnimation(
                    StudentHomePage._accentOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// -----------------------------------------------------------------
/// 📈 Grade progress (พื้นหลังขาว)
// -----------------------------------------------------------------
class _GradeProgressCard extends StatelessWidget {
  const _GradeProgressCard();

  @override
  Widget build(BuildContext context) {
    const data = [2.0, 2.0, 2.8, 3.2, 3.0, 4.0]; // S1..S6

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
                children: [
                  const Expanded(
                    child: Text('Grade progress',
                        style:
                            TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: StudentHomePage._bgSoft,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      '3.42  +0.12',
                      style: TextStyle(
                          color: StudentHomePage._primary,
                          fontWeight: FontWeight.w700),
                    ),
                  )
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
                  painter: _LineChartPainter(data),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _AxisLabel('S1'),
                  _AxisLabel('S2'),
                  _AxisLabel('S3'),
                  _AxisLabel('S4'),
                  _AxisLabel('S5'),
                  _AxisLabel('S6'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AxisLabel extends StatelessWidget {
  const _AxisLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style:
            const TextStyle(color: StudentHomePage._muted, fontSize: 12),
      );
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter(this.data);
  final List<double> data;

  @override
  void paint(Canvas canvas, Size size) {
    final grid =
        Paint()..color = const Color(0xFFEFF1F7)..strokeWidth = 1;
    final border =
        Paint()..color = const Color(0xFFE1E3EC)..strokeWidth = 1;

    // grid y lines
    const steps = 4;
    for (var i = 0; i <= steps; i++) {
      final y = size.height * (i / steps);
      canvas.drawLine(
          Offset(0, y), Offset(size.width, y), i == steps ? border : grid);
    }

    const maxY = 4.0, minY = 0.0;
    final dx = size.width / (data.length - 1);
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
/// 🔥 Top strength chip
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
/// 🧠 Skill strengths
/// -----------------------------------------------------------------
class _SkillStrengths extends StatelessWidget {
  const _SkillStrengths();

  @override
  Widget build(BuildContext context) {
    final skills = <(String, int)>[
      ('Data Analysis', 86),
      ('Machine Learning', 75),
      ('Mathematics', 64),
      ('Programming', 60),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: PhysicalModel(
        color: Colors.white,
        elevation: 2,
        shadowColor: Colors.black12,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Skill strengths',
                style:
                    TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 10),
              ...skills
                  .map((e) => _SkillBar(title: e.$1, percent: e.$2))
                  .expand((w) => [w, const SizedBox(height: 8)])
                  .toList()
                ..removeLast(),
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
    final value = percent / 100.0;
    return Column(
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
            valueColor: const AlwaysStoppedAnimation(
                StudentHomePage._primary),
          ),
        ),
      ],
    );
  }
}

/// -----------------------------------------------------------------
/// 💼 Recommended careers
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
          color: Colors.white, borderRadius: BorderRadius.circular(14),
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
                              color: const Color(0xFFF1F2F6),
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
