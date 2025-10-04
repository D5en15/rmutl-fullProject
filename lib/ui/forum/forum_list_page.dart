import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ---------- Global constants ----------
const Color kForumTextDark = Color(0xFF2B2E3A);
const Color kForumMuted = Color(0xFF8B90A0);
const Color kForumChipBg = Color(0xFFF4F6FA);
const double kCardRadius = 12.0;

class ForumListPage extends StatefulWidget {
  const ForumListPage({super.key});

  @override
  State<ForumListPage> createState() => _ForumListPageState();
}

class _ForumListPageState extends State<ForumListPage> {
  String? _currentUserId; // ✅ user_id (จาก collection user)
  String? _role;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("user")
        .where("user_email", isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        _currentUserId = data["user_id"].toString();
        _role = data["user_role"] ?? "student";
      });
    }
  }

  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin')) return 'admin';
    return 'student';
  }

  String _baseOf(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin' => '/admin',
        _ => '/student',
      };

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    final role = _detectRole(context);
    final base = _baseOf(role);

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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('post') // ✅ collection ใหม่
            .orderBy('post_time', descending: true) // ✅ field ใหม่
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มีโพสต์"));
          }

          final posts = snap.data!.docs.map((d) {
            final data = d.data() as Map<String, dynamic>;
            return _Post(
              id: d.id,
              title: data['post_title'] ?? '',
              detail: data['post_content'] ?? '',
              authorId: data['user_id'] ?? '',
              authorName: data['authorName'] ?? 'Unknown',
              createdAt: (data['post_time'] as Timestamp?)?.toDate(),
            );
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            itemCount: posts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final p = posts[i];
              return _PostCard(
                post: p,
                timeText: p.createdAt != null ? _timeAgo(p.createdAt!) : "",
                onTap: () => context.push('$base/forum/${p.id}'),
                onView: () => context.push('$base/forum/${p.id}'),
                canManage: (_role == 'admin') || (_currentUserId == p.authorId),
                base: base,
              );
            },
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
  final String detail;
  final String authorId;
  final String authorName;
  final DateTime? createdAt;
  const _Post({
    required this.id,
    required this.title,
    required this.detail,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
  });
}

/// ---------- Card ----------
class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.timeText,
    required this.onTap,
    required this.onView,
    required this.canManage,
    required this.base,
  });

  final _Post post;
  final String timeText;
  final VoidCallback onTap;
  final VoidCallback onView;
  final bool canManage;
  final String base;

  /// ✅ แก้ไขตรงนี้: ลบทั้งโพสต์ + sub-collection comments
  Future<void> _deletePost(BuildContext context) async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('post').doc(post.id);

      // ลบ sub-collection comments ก่อน
      final comments = await postRef.collection('comments').get();
      for (var c in comments.docs) {
        await c.reference.delete();
      }

      // ลบ document ของโพสต์
      await postRef.delete();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโพสต์และความคิดเห็นสำเร็จ')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

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
              // meta row: "authorName • time"
              Row(
                children: [
                  Text(
                    post.authorName,
                    style: const TextStyle(color: kForumMuted, fontSize: 12),
                  ),
                  const SizedBox(width: 8),
                  const Text('•', style: TextStyle(color: kForumMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(
                    timeText,
                    style: const TextStyle(color: kForumMuted, fontSize: 12),
                  ),
                  const Spacer(),

                  // ✅ Dropdown แก้ไข + ลบ
                  if (canManage)
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        icon: const Icon(Icons.more_vert, size: 20),
                        onChanged: (value) {
                          if (value == 'edit') {
                            context.push('$base/forum/${post.id}/edit');
                          } else if (value == 'delete') {
                            _deletePost(context);
                          }
                        },
                        items: const [
                          DropdownMenuItem(
                            value: 'edit',
                            child: Text('แก้ไข'),
                          ),
                          DropdownMenuItem(
                            value: 'delete',
                            child: Text('ลบ'),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                post.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kForumTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.detail,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: kForumTextDark,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),

              // action chips: View only
              Row(
                children: [
                  _ActionChip(
                    text: 'View',
                    onTap: onView,
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

/// ---------- Action Chip ----------
class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.text,
    required this.onTap,
    required this.bg,
    this.trailingPlus = false,
  });

  final String text;
  final VoidCallback onTap;
  final Color bg;
  final bool trailingPlus;

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