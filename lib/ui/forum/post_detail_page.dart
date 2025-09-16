// lib/ui/forum/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

  static const _muted = Color(0xFF8B90A0);

  @override
  Widget build(BuildContext context) {
    // mock post + comments
    final post = _PostDetail(
      author: 'Akash Pandey',
      role: 'Yoga Enthusiast and Meditation…',
      timeText: '2h',
      title:
          'What are some snacks you genuinely enjoy before a workout that also give you the energy you need?',
      hasImage: true,
    );

    final comments = List.generate(
      6,
      (i) => _Comment(
        name: ['Mukta Prasad', 'Samuel Harbour', 'Farida Khan', 'Neeti Mohan'][i % 4],
        role: ['Passionate Design Aficionado', 'Visual Storyteller', 'UI/UX Designer', 'Elevating Brands…'][i % 4],
        timeText: ['15m', '26m', '7m', '1h'][i % 4],
        text: [
          'I love the idea of combining quick-release carbs with sustained energy. Definitely trying this tomorrow!',
          'This is now my go-to pre-workout snack!',
          'The taste is fantastic, and I love that it\'s not only delicious but also nourishing. Thanks for the great idea!',
          'Looking forward to adding this to my pre-workout routine.',
        ][i % 4],
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: () => context.pop()),
        title: const Text('Post'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
        children: [
          Row(
            children: [
              const CircleAvatar(radius: 18, backgroundColor: Color(0xFFDDE3F8)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.author, style: const TextStyle(fontWeight: FontWeight.w700)),
                    Text('${post.role}  •  ${post.timeText}', style: const TextStyle(fontSize: 12, color: _muted)),
                  ],
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          const SizedBox(height: 10),
          Text(post.title, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          if (post.hasImage)
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: const Color(0xFF232CF0).withOpacity(.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE7EAF3)),
              ),
              alignment: Alignment.center,
              child: const Text('IMAGE', style: TextStyle(letterSpacing: 4, fontWeight: FontWeight.w800)),
            ),

          const SizedBox(height: 16),
          const Text('Comments', style: TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),

          for (final c in comments) ...[
            _CommentTile(c),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _PostDetail {
  final String author;
  final String role;
  final String timeText;
  final String title;
  final bool hasImage;
  const _PostDetail({
    required this.author,
    required this.role,
    required this.timeText,
    required this.title,
    required this.hasImage,
  });
}

class _Comment {
  final String name;
  final String role;
  final String timeText;
  final String text;
  const _Comment({required this.name, required this.role, required this.timeText, required this.text});
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.c);
  final _Comment c;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 1.5,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6FA),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const CircleAvatar(radius: 16, backgroundColor: Color(0xFFD9E3FF)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text(c.timeText, style: const TextStyle(fontSize: 11, color: Color(0xFF8B90A0))),
                    ],
                  ),
                  Text(c.role, style: const TextStyle(fontSize: 11, color: Color(0xFF8B90A0))),
                  const SizedBox(height: 6),
                  Text(c.text),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
