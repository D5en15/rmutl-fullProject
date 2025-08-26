import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell ใส่ Bottom Navigation ตามบทบาท
/// role: 'student' | 'teacher' | 'admin'
class RoleShell extends StatelessWidget {
  final String role;
  final Widget child;
  const RoleShell({super.key, required this.role, required this.child});

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();

    // เมนูต่อบทบาท (อิง flowchart)
    final List<_NavItem> items = switch (role) {
      'student' => const [
        _NavItem('Home', Icons.home_outlined, '/student'),
        _NavItem('Career', Icons.work_outline, '/student/career'),
        _NavItem('Board', Icons.forum_outlined, '/student/forum'),
        _NavItem('Setting', Icons.settings_outlined, '/student/settings'),
      ],
      'teacher' => const [
        _NavItem('Home', Icons.home_outlined, '/teacher'),
        _NavItem('Board', Icons.forum_outlined, '/teacher/forum'),
        _NavItem('Setting', Icons.settings_outlined, '/teacher/settings'),
      ],
      _ => const [
        // admin
        _NavItem('Home', Icons.home_outlined, '/admin'),
        _NavItem('Users', Icons.group_outlined, '/admin/users'),
        _NavItem('CareerCfg', Icons.work_outline, '/admin/career-config'),
        _NavItem('Moderation', Icons.shield_outlined, '/admin/moderation'),
      ],
    };

    int currentIndex = 0;
    for (var i = 0; i < items.length; i++) {
      if (uri == items[i].path || uri.startsWith('${items[i].path}/')) {
        currentIndex = i;
        break;
      }
    }

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: cs.primary.withOpacity(.12),
        selectedIndex: currentIndex,
        onDestinationSelected: (i) {
          final target = items[i].path;
          if (uri != target) context.go(target);
        },
        destinations: [
          for (final it in items)
            NavigationDestination(icon: Icon(it.icon), label: it.label),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}
