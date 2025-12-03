import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoleShell extends StatelessWidget {
  final String role;
  final Widget child;

  const RoleShell({
    super.key,
    required this.role,
    required this.child,
  });

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    final List<_NavItem> items = switch (role) {
      'student' => const [
        _NavItem('Home', Icons.home_outlined, '/student'),
        _NavItem('Subjects', Icons.list_alt_outlined, '/student/subjects'),
        _NavItem('Community', Icons.forum_outlined, '/student/forum'),
        _NavItem('Edit Profile', Icons.edit_outlined, '/student/settings'),
      ],
      'teacher' => const [
        _NavItem('Home', Icons.home_outlined, '/teacher'),
        _NavItem('Community', Icons.forum_outlined, '/teacher/forum'),
        _NavItem('Edit Profile', Icons.edit_outlined, '/teacher/settings'),
      ],
      _ => const [
        _NavItem('Home', Icons.home_outlined, '/admin'),
        _NavItem('Config', Icons.track_changes_outlined, '/admin/config', aliases: [
          '/admin/career-config',
          '/admin/config/subjects',
          '/admin/config/skills',
        ]),
        _NavItem('Community', Icons.forum_outlined, '/admin/forum'),
        _NavItem('Edit Profile', Icons.edit_outlined, '/admin/settings'),
      ],
    };

    final currentIndex = _resolveIndex(location, items);

    return Scaffold(
      body: child,
      bottomNavigationBar: SafeArea(
        top: false,
        child: _SimpleNavBar(
          items: items,
          currentIndex: currentIndex,
          onTap: (i) => _goIfChanged(context, location, items[i].path),
        ),
      ),
    );
  }

  static int _resolveIndex(String uri, List<_NavItem> items) {
    for (var i = 0; i < items.length; i++) {
      final paths = [items[i].path, ...items[i].aliases];
      for (final p in paths) {
        if (uri == p || uri.startsWith('$p/')) return i;
      }
    }
    return 0;
  }

  static void _goIfChanged(BuildContext context, String currentUri, String target) {
    if (currentUri != target) context.go(target);
  }
}

class _SimpleNavBar extends StatelessWidget {
  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _SimpleNavBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade300, width: 1)),
        color: Colors.white,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          for (int i = 0; i < items.length; i++)
            Expanded(
              child: _SimpleNavItem(
                item: items[i],
                selected: i == currentIndex,
                onTap: () => onTap(i),
              ),
            ),
        ],
      ),
    );
  }
}

class _SimpleNavItem extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SimpleNavItem({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  static const _primary = RoleShell._primary;
  static const _muted = RoleShell._muted;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.1,
    );

    const color = _muted;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        splashColor: _primary.withOpacity(0.2),
        highlightColor: _primary.withOpacity(0.08),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(item.icon, size: 26, color: color),
              const SizedBox(height: 4),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📦 Nav Item Model
class _NavItem {
  final String label;
  final IconData icon;
  final String path;
  final List<String> aliases;

  const _NavItem(this.label, this.icon, this.path, {this.aliases = const []});
}
