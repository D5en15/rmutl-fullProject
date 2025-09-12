import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shell ใส่ Bottom Navigation ตามบทบาท
/// role: 'student' | 'teacher' | 'admin'
class RoleShell extends StatelessWidget {
  final String role;
  final Widget child;
  const RoleShell({super.key, required this.role, required this.child});

  // Theme token
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _bgSoft = Color(0xFFF6F7FF);

  @override
  Widget build(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();

    // เมนูต่อบทบาท
    final List<_NavItem> items = switch (role) {
      'student' => const [
        _NavItem('Home', Icons.home_outlined, '/student'),
        _NavItem('Subject list', Icons.list_alt_outlined, '/student/subjects'),
        _NavItem('Community', Icons.forum_outlined, '/student/forum'),
        _NavItem('Setting', Icons.settings_outlined, '/student/settings'),
      ],
      'teacher' => const [
        _NavItem('Home', Icons.home_outlined, '/teacher'),
        _NavItem('Community', Icons.forum_outlined, '/teacher/forum'),
        _NavItem('Setting', Icons.settings_outlined, '/teacher/settings'),
      ],
      _ => const [
        // admin
        _NavItem('Home', Icons.home_outlined, '/admin'),
        _NavItem('Config', Icons.track_changes_outlined, '/admin/career-config'),
        _NavItem('Community', Icons.forum_outlined, '/admin/forum'),
        _NavItem('Setting', Icons.settings_outlined, '/admin/settings'),
      ],
    };

    int currentIndex = 0;
    for (var i = 0; i < items.length; i++) {
      if (uri == items[i].path || uri.startsWith('${items[i].path}/')) {
        currentIndex = i;
        break;
      }
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.only(bottom: 6, left: 8, right: 8),
        child: switch (role) {
          'teacher' => _FlatNavBar(
              items: items,
              currentIndex: currentIndex,
              onTap: (i) {
                final target = items[i].path;
                if (uri != target) context.go(target);
              },
            ),
          _ => _PillNavBar(
              items: items,
              currentIndex: currentIndex,
              onTap: (i) {
                final target = items[i].path;
                if (uri != target) context.go(target);
              },
            ),
        },
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// 📦 Pill Navigation (student + admin)
/// ----------------------------------------------------------------------
class _PillNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _PillNavBar(
      {required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
              color: Colors.black12, blurRadius: 6, offset: Offset(0, 2))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < items.length; i++)
            _PillItem(
              item: items[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _PillItem extends StatelessWidget {
  const _PillItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _primary = RoleShell._primary;
  static const _muted = RoleShell._muted;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _muted;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, color: color, size: 26),
              const SizedBox(height: 8),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// 📦 Flat Navigation (teacher)
/// ----------------------------------------------------------------------
class _FlatNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  const _FlatNavBar(
      {required this.items, required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int i = 0; i < items.length; i++)
            _FlatItem(
              item: items[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );
  }
}

class _FlatItem extends StatelessWidget {
  const _FlatItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  static const _primary = RoleShell._primary;
  static const _muted = RoleShell._muted;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _primary : _muted;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(item.icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ----------------------------------------------------------------------
/// 📦 Item model
/// ----------------------------------------------------------------------
class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  const _NavItem(this.label, this.icon, this.path);
}
