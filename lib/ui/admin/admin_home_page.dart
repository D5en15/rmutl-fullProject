import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/page_template.dart';

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Card(
        'Users & Roles',
        Icons.group_outlined,
        () => context.push('/admin/users'),
      ),
      _Card(
        'Role Permission',
        Icons.lock_outline,
        () => context.push('/admin/roles'),
      ),
      _Card(
        'Career Config',
        Icons.work_outline,
        () => context.push('/admin/career-config'),
      ),
      _Card(
        'Moderation',
        Icons.shield_outlined,
        () => context.push('/admin/moderation'),
      ),
      _Card('Forum', Icons.forum_outlined, () => context.push('/admin/forum')),
      _Card(
        'Settings',
        Icons.settings_outlined,
        () => context.push('/admin/settings'),
      ),
    ];
    return PageTemplate(
      title: 'Admin Home',
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: MediaQuery.of(context).size.width > 720 ? 3 : 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        children: items,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _Card(this.title, this.icon, this.onTap, {super.key});
  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 36),
              const SizedBox(height: 8),
              Text(title),
            ],
          ),
        ),
      ),
    );
  }
}
