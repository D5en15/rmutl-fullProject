import 'package:flutter/material.dart';
import '../common/page_template.dart';
import '../../services/grade_service.dart';
import '../../models/grade_entry.dart';

class StudentDetailPage extends StatefulWidget {
  final String studentId;
  const StudentDetailPage({super.key, required this.studentId});

  @override
  State<StudentDetailPage> createState() => _StudentDetailPageState();
}

class _StudentDetailPageState extends State<StudentDetailPage> {
  late Future<List<GradeEntry>> future;

  @override
  void initState() {
    super.initState();
    future = GradeService().fetchGrades(widget.studentId);
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Student ${widget.studentId}',
      child: FutureBuilder<List<GradeEntry>>(
        future: future,
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final grades = snap.data!;
          final avg = GradeService().average(grades);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
