import 'package:flutter/material.dart';
import 'page_template.dart';

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = List.generate(6, (i) => 'Notification #${i + 1}');
    return PageTemplate(
      title: 'Notifications',
      child: ListView.separated(
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder:
            (_, i) => Card(
              child: ListTile(
                leading: const Icon(Icons.notifications_active_outlined),
                title: Text(items[i]),
                subtitle: const Text('This is a sample notification'),
              ),
            ),
      ),
    );
  }
}
