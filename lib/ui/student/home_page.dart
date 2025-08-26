import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/page_template.dart';
import '../../services/grade_service.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});
  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  double? avg;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final grades = await GradeService().fetchGrades('me');
    setState(() => avg = GradeService().average(grades));
  }

  @override
  Widget build(BuildContext context) {
    final cards = [
      _HomeCard(
        'Grades',
        Icons.school_outlined,
        () => context.push('/student/grades'),
      ),
      _HomeCard(
        'Career',
        Icons.work_outline,
        () => context.push('/student/career'),
      ),
      _HomeCard(
        'Forum',
        Icons.forum_outlined,
        () => context.push('/student/forum'),
      ),
      _HomeCard(
        'Settings',
        Icons.settings_outlined,
        () => context.push('/student/settings'),
      ),
    ];

    return PageTemplate(
      title: 'Student Home',
      actions: [
        IconButton(
          onPressed: () => context.push('/student/notifications'),
          icon: const Icon(Icons.notifications_none),
        ),
        IconButton(
          onPressed: () => context.push('/student/profile'),
          icon: const Icon(Icons.person_outline),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (avg != null)
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Average score'),
                subtitle: Text('${avg!.toStringAsFixed(1)} / 100'),
              ),
            ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: MediaQuery.of(context).size.width > 720 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            children: cards,
          ),
        ],
      ),
    );
  }
}

class _HomeCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;
  const _HomeCard(this.title, this.icon, this.onTap);

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
