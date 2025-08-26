import 'package:flutter/material.dart';
import '../common/page_template.dart';
import '../../services/admin_service.dart';

class UserManagePage extends StatelessWidget {
  const UserManagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Users & Roles',
      child: FutureBuilder<List<Map<String, String>>>(
        future: AdminService().listUsers(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final users = snap.data!;
          return ListView.separated(
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder:
                (_, i) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(users[i]['email']!),
                    subtitle: Text('role: ${users[i]['role']}'),
                    trailing: FilledButton(
                      onPressed: () {},
                      child: const Text('Edit'),
                    ),
                  ),
                ),
          );
        },
      ),
    );
  }
}
