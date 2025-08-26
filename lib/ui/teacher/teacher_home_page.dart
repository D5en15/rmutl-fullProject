import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/page_template.dart';

class TeacherHomePage extends StatelessWidget {
  const TeacherHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _Card(
        'Students',
        Icons.people_outline,
        () => context.push('/teacher/students'),
      ),
      _Card(
        'Feedback',
        Icons.rate_review_outlined,
        () => context.push('/teacher/feedback'),
      ),
      _Card(
        'Forum',
        Icons.forum_outlined,
        () => context.push('/teacher/forum'),
      ),
      _Card(
        'Settings',
        Icons.settings_outlined,
        () => context.push('/teacher/settings'),
      ),
    ];
    return PageTemplate(
      title: 'Teacher Home',
      child: GridView.count(
        shrinkWrap: true,
        crossAxisCount: MediaQuery.of(context).size.width > 720 ? 4 : 2,
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
