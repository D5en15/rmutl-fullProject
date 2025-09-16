import 'package:flutter/material.dart';
import '../common/page_template.dart';
import '../../services/admin_service.dart';

class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Moderation',
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: AdminService().moderationQueue(),
        builder: (_, snap) {
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());
          final items = snap.data!;
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final it = items[i];
              return Card(
                child: ListTile(
                  leading: const Icon(Icons.report_outlined),
                  title: Text('Post ${it['id']}'),
                  subtitle: Text(
                    'Reason: ${it['reason']} • by ${it['author']}',
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(
                        onPressed: () {},
                        child: const Text('Dismiss'),
                      ),
                      FilledButton(
                        onPressed: () {},
                        child: const Text('Remove'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}