import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/forum_model.dart';
import '../../services/forum_service.dart';

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
  final _service = ForumService();
  String? _currentUserId;
  String? _role;
  String _searchQuery = "";
  bool _showMyPostsOnly = false;

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
      if (mounted) {
        setState(() {
          _currentUserId = data["user_id"]?.toString();
          _role = data["user_role"] ?? "student";
        });
      }
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
      body: SafeArea(
        child: Column(
          children: [
            // ✅ Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Community Forum",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    tooltip: "Create post",
                    icon: const Icon(Icons.add_circle_outline,
                        color: Colors.black, size: 28),
                    onPressed: () => context.push('$base/forum/create'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // 🔍 Search + My Posts
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value.trim()),
                      decoration: InputDecoration(
                        hintText: 'Search by title or author...',
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Colors.black12, width: 1),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text("My posts"),
                    selected: _showMyPostsOnly,
                    onSelected: (v) => setState(() => _showMyPostsOnly = v),
                    selectedColor: Colors.blueAccent.withOpacity(0.15),
                    checkmarkColor: Colors.blueAccent,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: BorderSide(
                        color: _showMyPostsOnly
                            ? Colors.blueAccent
                            : Colors.grey.shade400,
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 🔹 Post List
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: _service.getPosts(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snap.hasData || snap.data!.docs.isEmpty) {
                    return const Center(
                      child: Text("ยังไม่มีโพสต์",
                          style: TextStyle(color: kForumMuted)),
                    );
                  }

                  final allPosts = snap.data!.docs
                      .map((d) => ForumPost.fromDoc(d))
                      .toList();

                  final filteredPosts = allPosts.where((p) {
                    final query = _searchQuery.toLowerCase();
                    final matchesSearch = query.isEmpty ||
                        p.title.toLowerCase().contains(query) ||
                        p.authorName.toLowerCase().contains(query);
                    final matchesMine = !_showMyPostsOnly ||
                        (_currentUserId != null &&
                            p.authorId == _currentUserId);
                    return matchesSearch && matchesMine;
                  }).toList();

                  if (filteredPosts.isEmpty) {
                    return const Center(
                      child: Text("ไม่พบโพสต์ที่ตรงกับเงื่อนไข",
                          style: TextStyle(color: kForumMuted)),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                    itemCount: filteredPosts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, i) {
                      final post = filteredPosts[i];
                      return _PostCard(
                        post: post,
                        timeText: post.createdAt != null
                            ? _timeAgo(post.createdAt!)
                            : "",
                        onView: () => context.push('$base/forum/${post.id}'),
                        canManage: (_role == 'admin') ||
                            (_currentUserId == post.authorId),
                        base: base,
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.timeText,
    required this.onView,
    required this.canManage,
    required this.base,
  });

  final ForumPost post;
  final String timeText;
  final VoidCallback onView;
  final bool canManage;
  final String base;

  Future<void> _deletePost(BuildContext context) async {
    try {
      final postRef =
          FirebaseFirestore.instance.collection('post').doc(post.id);
      final comments = await postRef.collection('comments').get();
      for (var c in comments.docs) {
        await c.reference.delete();
      }
      await postRef.delete();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบโพสต์และความคิดเห็นสำเร็จ')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
      );
    }
  }

  void _showManageMenu(BuildContext context) {
    final rootContext = Navigator.of(context, rootNavigator: true).context;

    showModalBottomSheet(
      context: rootContext,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined,
                      color: Colors.blueAccent),
                  title: const Text("แก้ไขโพสต์"),
                  onTap: () {
                    Navigator.of(rootContext).pop();
                    context.push('$base/forum/${post.id}/edit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text("ลบโพสต์"),
                  onTap: () {
                    Navigator.of(rootContext).pop();
                    _confirmDelete(context);
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.close, color: Colors.black54),
                  title: const Text("Cancel"),
                  onTap: () => Navigator.of(rootContext).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: Navigator.of(context, rootNavigator: true).context,
      builder: (ctx) => AlertDialog(
        title: const Text("ยืนยันการลบโพสต์"),
        content: const Text("คุณต้องการลบโพสต์นี้หรือไม่?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("ยกเลิก"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("ลบ",
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirm == true) await _deletePost(context);
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
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(post.authorName,
                      style: const TextStyle(color: kForumMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  const Text('•',
                      style: TextStyle(color: kForumMuted, fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(timeText,
                      style: const TextStyle(color: kForumMuted, fontSize: 12)),
                  const Spacer(),
                  if (canManage)
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          size: 22, color: Colors.black54),
                      onPressed: () => _showManageMenu(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: kForumTextDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                post.content,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: kForumTextDark,
                  fontSize: 14,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
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
            Text(text,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            if (trailingPlus) ...[
              const SizedBox(width: 4),
              const Text('+',
                  style:
                      TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ],
        ),
      ),
    );
  }
}