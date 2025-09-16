// lib/ui/forum/create_post_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _text.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Post'),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()),
        actions: [
          TextButton(
            onPressed: canPost ? () => _submit(context) : null,
            child: const Text('Post'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Row(
              children: const [
                CircleAvatar(radius: 16, backgroundColor: Color(0xFFDDE3F8)),
                SizedBox(width: 10),
                Text('What’s in your mind?', style: TextStyle(color: Color(0xFF8B90A0))),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TextField(
                controller: _text,
                maxLines: null,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Write something…',
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.image_outlined)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.tag_outlined)),
                const Spacer(),
                FilledButton(
                  onPressed: canPost ? () => _submit(context) : null,
                  child: const Text('Post'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  void _submit(BuildContext context) {
    // TODO: เชื่อมบริการจริง
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('โพสต์สำเร็จ (mock)')),
    );
    context.pop(); // กลับไปหน้า list
  }
}
