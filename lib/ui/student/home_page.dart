import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StudentHomePage extends StatelessWidget {
  const StudentHomePage({super.key});

  static const Color _primary = Color(0xFF3D5CFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ----- Header Blue + GPA Card (overlay) -----
            const _HeaderWithGpaCard(),
            // ระยะเผื่อการ์ดที่ลอยออกจากพื้นหลังฟ้า
            const SizedBox(height: 56),

            // ----- Body: Career advice -----
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Career advice',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),

                  _AdviceCard(
                    leading: Icons.work_outline_rounded,
                    title: 'View career',
                    subtitle: 'Look at careers that interest you.',
                    buttonText: 'Enter',
                    onPressed: () => context.go('/student/career'),
                  ),
                  const SizedBox(height: 12),

                  _AdviceCard(
                    leading: Icons.fact_check_outlined,
                    title: 'Survey',
                    subtitle: 'Take the survey to find the right career.',
                    buttonText: 'Log In',
                    onPressed: () => context.go('/login'),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// พื้นหลังฟ้า (สูง 150 เหมือนหัวสีเทาของหน้า Login) + การ์ด GPA ลอยชิดขอบ
class _HeaderWithGpaCard extends StatelessWidget {
  const _HeaderWithGpaCard();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // พื้นหลังฟ้า
        Container(
          height: 200, // เท่าหน้า Login
          padding: const EdgeInsets.only(top: 28, left: 20, right: 20),
          decoration: const BoxDecoration(color: _StudentHomeHeader.primary),
          child: const SafeArea(bottom: false, child: _StudentHomeHeader()),
        ),

        // การ์ด GPA ลอยชิดขอบล่างของพื้นหลังฟ้า (กลางแนวนอน)
        Positioned(
          left: 16,
          right: 16,
          bottom: -38, // ค่าลบ = ลอยลงพ้นขอบฟ้าเล็กน้อย ให้ดู "ชิดขอบ"
          child: const _GpaCard(),
        ),
      ],
    );
  }
}

class _StudentHomeHeader extends StatelessWidget {
  const _StudentHomeHeader();

  static const Color primary = Color(0xFF3D5CFF);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: const [
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hi, Smith',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Let's start learning",
                  style: TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.person, color: Colors.black54),
        ),
      ],
    );
  }
}

class _GpaCard extends StatelessWidget {
  const _GpaCard();

  @override
  Widget build(BuildContext context) {
    const double gpa = 3.45; // เกรดจำลอง
    const double gpaMax = 4.00;
    final double progress = (gpa / gpaMax).clamp(0.0, 1.0);

    return Card(
      elevation: 6,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(
                  'My learning',
                  style: TextStyle(
                    color: Color(0xFF3D5CFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: const [
                Text(
                  '3.45',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                SizedBox(width: 6),
                Text('/ 4.00', style: TextStyle(color: Colors.black45)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                backgroundColor: const Color(0xFFE8EAFF),
                valueColor: const AlwaysStoppedAnimation(Color(0xFF3D5CFF)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  const _AdviceCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onPressed,
  });

  final IconData leading;
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF3FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(leading, size: 38, color: const Color(0xFF3D5CFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.black54,
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton(
                        onPressed: onPressed,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3D5CFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 22),
                        ),
                        child: Text(
                          buttonText,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
