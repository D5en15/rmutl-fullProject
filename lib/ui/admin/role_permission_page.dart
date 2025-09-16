import 'package:flutter/material.dart';
import '../common/page_template.dart';

class RolePermissionPage extends StatelessWidget {
  const RolePermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    final rows = const [
      _Row('student', ['read:board', 'write:comment']),
      _Row('teacher', ['read/write:board', 'grade:edit']),
      _Row('admin', ['*']),
    ];
    return PageTemplate(
      title: 'Role & Permission',
      child: DataTable(
        columns: const [
          DataColumn(label: Text('Role')),
          DataColumn(label: Text('Permissions')),
        ],
        rows:
            rows
                .map(
                  (r) => DataRow(
                    cells: [
                      DataCell(Text(r.role)),
                      DataCell(Text(r.perms.join(', '))),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }
}

class _Row {
  final String role;
  final List<String> perms;
  const _Row(this.role, this.perms);
}