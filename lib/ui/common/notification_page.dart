import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  // THEME
  static const _primary = Color(0xFF3D5CFF);
  static const _muted   = Color(0xFF858597);

  // ตรวจบทบาทจาก prefix ของ URI
  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin'))   return 'admin';
    return 'student';
  }

  // คืน base path ของ role
  String _baseOf(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin'   => '/admin',
        _         => '/student',
      };

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);

    // mock list
    final items = List.generate(6, (i) => (
      icon: Icons.description_rounded,
      title: 'Congratulations on completing the first lesson, keep up the good work!',
      time: i == 0 ? 'Just now' : (i == 1 ? '5 min ago' : 'Today')
    ));

    return WillPopScope(
      // ✅ ถ้ากด Back ของระบบแล้วสแตกว่าง ให้ไปหน้า Home ของบทบาท
      onWillPop: () async {
        if (Navigator.of(context).canPop()) return true;
        context.go(base); // <— เดิมไป settings, แก้ให้ไป Home
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('Notifications',
              style: TextStyle(fontWeight: FontWeight.w800)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            onPressed: () {
              // ✅ ปุ่ม back: ถ้ามีเส้นทางก่อนหน้าให้ pop, ไม่งั้นไป Home ของบทบาท
              if (Navigator.of(context).canPop()) {
                context.pop();
              } else {
                context.go(base); // <— เดิมไป settings, แก้ให้ไป Home
              }
            },
          ),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
        body: Column(
          children: [
            // ---------- Tabs ----------
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  _TabButton(
                    text: 'notification',
                    isActive: true,
                    onTap: () {},
                  ),
                  const SizedBox(width: 18),
                  _TabButton(
                    text: 'message',
                    isActive: false,
                    trailingDot: true,
                    // ใช้ push เพื่อคง back-stack
                    onTap: () => context.push('$base/messages'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ---------- List ----------
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _NotiCard(
                  icon: items[i].icon,
                  title: items[i].title,
                  time:  items[i].time,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.text,
    required this.isActive,
    this.trailingDot = false,
    this.onTap,
  });

  final String text;
  final bool isActive;
  final bool trailingDot;
  final VoidCallback? onTap;

  static const _primary = Color(0xFF3D5CFF);
  static const _muted   = Color(0xFF858597);

  @override
  Widget build(BuildContext context) {
    final color = isActive ? Colors.black87 : _muted;
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  text,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color),
                ),
                if (trailingDot) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Colors.orange,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 3,
              width: isActive ? 90 : 0,
              decoration: BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotiCard extends StatelessWidget {
  const _NotiCard({
    required this.icon,
    required this.title,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 3.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF3D5CFF)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.circle, size: 8, color: Color(0xFFD4DAE6)),
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          color: Color(0xFF9CA3AF),
                          fontSize: 12,
                        ),
                      ),
                    ],
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
