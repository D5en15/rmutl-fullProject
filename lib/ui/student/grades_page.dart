import 'package:flutter/material.dart';
import '../common/page_template.dart';
import '../../services/grade_service.dart';
import '../../models/grade_entry.dart';
import '../../widgets/grade_chart.dart';
import 'package:go_router/go_router.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({super.key});
  @override
  State<GradesPage> createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {
  late Future<List<GradeEntry>> future;

  @override
  void initState() {
    super.initState();
    future = GradeService().fetchGrades('me');
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Grades',
      actions: [
        IconButton(
          onPressed: () => context.push('/student/grades/edit'),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: FutureBuilder<List<GradeEntry>>(
        future: future,
        builder: (context, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final grades = snap.data!;
          final avg = GradeService().average(grades);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradeChart(data: grades),
              const SizedBox(height: 16),
              Text(
                'Average: ${avg.toStringAsFixed(1)}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: grades.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final g = grades[i];
                    return Card(
                      child: ListTile(
                        title: Text('${g.subjectCode} • ${g.subjectName}'),
                        trailing: Text(g.score.toStringAsFixed(1)),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
