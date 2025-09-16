import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentDetailPage extends StatelessWidget {
  const StudentDetailPage({super.key, required this.studentId});
  final String studentId;

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _bgSoft = Color(0xFFF6F7FF);

  @override
  Widget build(BuildContext context) {
    // mock
    const name = 'Michael Brown';
    const code = '21_A_043';
    const room = 'Class A';
    const email = 'michaelb@email.com';
    const phone = '+1 234 567 890';

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            children: [
              const CircleAvatar(
                radius: 40,
                backgroundColor: Color(0xFFFFE3B5),
                child: Icon(Icons.person, size: 42, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              Text(name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: 6),
              Text(
                '$code  •  $room\n$email\n$phone',
                textAlign: TextAlign.center,
                style: const TextStyle(color: _muted),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  onPressed: () => context.go('/chat/$studentId'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                  ),
                  child: const Text('Message'),
                ),
              ),
              const SizedBox(height: 16),

              // Grade progress
              _GradeCard(
                title: 'Grade progress',
                subtitle: 'GPA by semester',
                data: const [2.1, 2.5, 3.0, 3.2, 3.1, 3.9],
              ),
              const SizedBox(height: 12),

              // Skill strengths
              _SkillStrengths(skills: const [
                ('Data Analysis', 86),
                ('Machine Learning', 75),
                ('Mathematics', 64),
                ('Programming', 58),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeCard extends StatelessWidget {
  const _GradeCard({
    required this.title,
    required this.subtitle,
    required this.data,
  });

  final String title;
  final String subtitle;
  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
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
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Color(0xFF858597))),
            const SizedBox(height: 12),
            SizedBox(
              height: 170,
              width: double.infinity,
              child: CustomPaint(painter: _LineChartPainter(data)),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  const ['S1', 'S2', 'S3', 'S5', 'S6'].map((e) => _Axis(e)).toList()
                    ..insert(3, const _Axis('S4')),
            ),
          ],
        ),
      ),
    );
  }
}

class _Axis extends StatelessWidget {
  const _Axis(this.t);
  final String t;
  @override
  Widget build(BuildContext context) =>
      Text(t, style: const TextStyle(color: Color(0xFF858597), fontSize: 12));
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
    final dx = size.width / (data.length - 1);
    final path = Path();
    final line = Paint()
      ..color = const Color(0xFF3D5CFF)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final dot = Paint()..color = const Color(0xFF3D5CFF);

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

class _SkillStrengths extends StatelessWidget {
  const _SkillStrengths({required this.skills});
  final List<(String, int)> skills;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
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
            Row(
              children: const [
                Expanded(
                  child: Text('Skill strengths',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                Text('86%',
                    style:
                        TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
              ],
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
    );
  }
}

class _SkillBar extends StatelessWidget {
  const _SkillBar({required this.title, required this.percent});
  final String title;
  final int percent;

  @override
  Widget build(BuildContext context) {
    final value = (percent / 100.0).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              child: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
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
                const AlwaysStoppedAnimation(Color(0xFF3D5CFF)),
          ),
        ),
      ],
    );
  }
}
