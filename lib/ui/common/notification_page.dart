import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin')) return 'admin';
    return 'student';
  }

  String _baseOf(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin' => '/admin',
        _ => '/student',
      };

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          // ✅ กลับไปหน้าหลักของบทบาทที่ล็อกอินมา
          onPressed: () => context.go(base),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
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
                  trailingDot: false,
                  onTap: () => context.push('$base/messages'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.notifications_none_rounded,
                      size: 80, color: _muted),
                  SizedBox(height: 12),
                  Text(
                    "ไม่มีการแจ้งเตือน",
                    style: TextStyle(
                      color: _muted,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
  static const _muted = Color(0xFF858597);

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