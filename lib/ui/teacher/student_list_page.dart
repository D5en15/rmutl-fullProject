import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../common/page_template.dart';

class StudentListPage extends StatelessWidget {
  const StudentListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final students = List.generate(12, (i) => 'stu_${1000 + i}');
    return PageTemplate(
      title: 'Students',
      child: ListView.separated(
        itemCount: students.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder:
            (_, i) => Card(
              child: ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Student ${students[i]}'),
                onTap: () => context.push('/teacher/students/${students[i]}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
      ),
    );
  }
}
