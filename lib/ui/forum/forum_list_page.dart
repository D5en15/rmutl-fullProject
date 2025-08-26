import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForumListPage extends StatelessWidget {
  final String? basePath;
  const ForumListPage({super.key, this.basePath});

  @override
  Widget build(BuildContext context) {
    final posts = List.generate(8, (i) => 'post_${i + 1}');
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Forum')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final id = posts[i];
          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: cs.primaryContainer,
                child: Text(
                  '${i + 1}',
                  style: TextStyle(color: cs.onPrimaryContainer),
                ),
              ),
              title: Text('Post $id'),
              subtitle: const Text('Sample forum item'),
              trailing: const Icon(Icons.chevron_right),
              // ใช้ relative push → จะเป็น /student/forum/:id หรือ /forum/:id
              onTap: () => context.push(id),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('create'),
        icon: const Icon(Icons.add),
        label: const Text('Create'),
      ),
    );
  }
}
