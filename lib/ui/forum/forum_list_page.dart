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
  static const _primary = Color(0xFF3D5CFF);

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
                  SizedBox(
                    height: 46,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _showMyPostsOnly
                              ? Colors.blueAccent
                              : Colors.grey.shade400,
                        ),
                        backgroundColor: _showMyPostsOnly
                            ? Colors.blueAccent.withOpacity(0.12)
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _showMyPostsOnly = !_showMyPostsOnly),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.person, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            "My posts",
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: _showMyPostsOnly
                                  ? Colors.blueAccent
                                  : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
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
                      child: Text("No posts yet",
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
                      child: Text("No posts match your search",
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
                        canManage: (role == 'admin') ||
                            (_role == 'admin') ||
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('$base/forum/create'),
        backgroundColor: ForumListPage._primary,
        child: const Icon(Icons.add, color: Colors.white),
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

  Widget _avatar(String? url) {
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFD9E3FF),
      backgroundImage: url != null && url.isNotEmpty ? NetworkImage(url) : null,
      child: (url == null || url.isEmpty)
          ? const Icon(Icons.person, size: 18, color: Colors.white)
          : null,
    );
  }

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
        const SnackBar(content: Text('Post and comments deleted')),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
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
                  title: const Text("Edit post"),
                  onTap: () {
                    Navigator.of(rootContext).pop();
                    context.push('$base/forum/${post.id}/edit');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline,
                      color: Colors.redAccent),
                  title: const Text("Delete post"),
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
        title: const Text("Delete post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Delete",
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _avatar(post.authorAvatar),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          post.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: kForumTextDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          timeText,
                          style: const TextStyle(
                            color: kForumMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (canManage)
                    IconButton(
                      icon: const Icon(Icons.more_vert,
                          size: 22, color: Colors.black54),
                      onPressed: () => _showManageMenu(context),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (post.isAnnouncement)
                Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ForumListPage._primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.campaign_outlined,
                          size: 14, color: ForumListPage._primary),
                      SizedBox(width: 6),
                      Text(
                        'Teacher announcement',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: ForumListPage._primary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
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
