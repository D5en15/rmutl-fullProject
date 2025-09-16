// lib/ui/forum/forum_list_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// ---------- Global constants (ใช้ได้ทั้งไฟล์) ----------
const Color kForumTextDark = Color(0xFF2B2E3A); // ใช้แทน _textDark เดิม
const Color kForumMuted    = Color(0xFF8B90A0);
const Color kForumChipBg   = Color(0xFFF4F6FA);
const double kCardRadius   = 12.0;

class ForumListPage extends StatelessWidget {
  const ForumListPage({super.key});

  /// เดา role จาก path ปัจจุบัน
  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin'))   return 'admin';
    return 'student';
  }

  String _baseOf(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin'   => '/admin',
        _         => '/student',
      };

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);

    final posts = List.generate(
      8,
      (i) => _Post(
        id: 'p$i',
        title: [
          'What are some snacks you genuinely enjoy before a workout that also give you the energy you need?',
          'Anyone recently tried a new fitness class? Would love to hear your honest thoughts and any recommendations!',
          'How do you personally find motivation on those tough weeks when working out feels challenging? Any real-life tips?',
          'When it comes to your weekly workout schedule, how do you honestly balance cardio and strength training?',
        ][i % 4],
        answers: (i + 1) * 2,
        timeText: i.isEven ? '1m' : '${i + 1}h',
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My board'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Create post',
            icon: const Icon(Icons.add),
            onPressed: () => context.push('$base/forum/create'),
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final p = posts[i];
          return _PostCard(
            post: p,
            onTap: () => context.push('$base/forum/${p.id}'),
            onAnswer: () => context.push('$base/forum/${p.id}'),
            onView: () => context.push('$base/forum/${p.id}'),
            onFollow: () {},
          );
        },
      ),
    );
  }
}

/// ---------- Model ----------
class _Post {
  final String id;
  final String title;
  final int answers;
  final String timeText;
  const _Post({
    required this.id,
    required this.title,
    required this.answers,
    required this.timeText,
  });
}

/// ---------- Card ----------
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.onAnswer,
    required this.onView,
    required this.onFollow,
  });

  final _Post post;
  final VoidCallback onTap;
  final VoidCallback onAnswer;
  final VoidCallback onView;
  final VoidCallback onFollow;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(kCardRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(kCardRadius),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // meta row: "5 Answers • 1m" ...  more
              Row(
                children: [
                  Text(
                    '${post.answers} Answers',
                    style: const TextStyle(color: kForumMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: kForumMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(
                    post.timeText,
                    style: const TextStyle(color: kForumMuted, fontSize: 12),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'More',
                    icon: const Icon(Icons.more_vert, size: 20),
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'share', child: Text('Share')),
                      PopupMenuItem(value: 'report', child: Text('Report')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                    onSelected: (v) {
                      // TODO: handle actions (share/report/delete)
                    },
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.title,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kForumTextDark,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // action chips: Answer | View + ... Follow +
              Row(
                children: [
                  _ActionChip(
                    text: 'Answer',
                    onTap: onAnswer,
                    bg: kForumChipBg,
                    // icon ภายใน box เล็ก ๆ ตามภาพ
                    leadingBoxIcon: Icons.edit_outlined,
                  ),
                  const SizedBox(width: 8),
                  _ActionChip(
                    text: 'View',
                    onTap: onView,
                    bg: kForumChipBg,
                    trailingPlus: true, // แสดง " + "
                  ),
                  const Spacer(),
                  _ActionChip(
                    text: 'Follow',
                    onTap: onFollow,
                    bg: kForumChipBg,
                    trailingPlus: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Action Chip (capsule) ----------
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.text,
    required this.onTap,
    required this.bg,
    this.leadingBoxIcon,
    this.trailingPlus = false,
  });

  final String text;
  final VoidCallback onTap;
  final Color bg;
  final IconData? leadingBoxIcon; // ไอคอนในกล่องสี่เหลี่ยมเล็ก (สำหรับ Answer)
  final bool trailingPlus;        // แสดงเครื่องหมาย + ท้ายคำ

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leadingBoxIcon != null) ...[
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFCDD4E1)),
                ),
                alignment: Alignment.center,
                child: Icon(leadingBoxIcon, size: 13, color: kForumTextDark),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (trailingPlus) ...[
              const SizedBox(width: 4),
              const Text('+',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}
