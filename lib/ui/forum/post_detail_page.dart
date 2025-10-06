import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailPage extends StatefulWidget {
  final String postId;
  const PostDetailPage({super.key, required this.postId});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  static const _muted = Color(0xFF8B90A0);
  final _commentCtrl = TextEditingController();

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  /// ✅ เพิ่มคอมเมนต์
  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final userDoc = await FirebaseFirestore.instance
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (userDoc.docs.isEmpty) return;
    final userData = userDoc.docs.first.data();

    await FirebaseFirestore.instance
        .collection('post')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'user_id': userData['user_id'],
      'comment_content': text,
      'comment_time': FieldValue.serverTimestamp(),
      'authorName': userData['user_fullname'] ?? 'Unknown',
      'authorAvatar': userData['user_img'],
    });

    _commentCtrl.clear();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: const Text('Post Detail'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('post')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || !snap.data!.exists) {
                  return const Center(child: Text("Post not found"));
                }

                final data = snap.data!.data() as Map<String, dynamic>;
                final title = data['post_title'] ?? '';
                final content = data['post_content'] ?? '';
                final createdAt =
                    (data['post_time'] as Timestamp?)?.toDate();
                final author = data['authorName'] ?? 'Unknown';
                final avatar = data['authorAvatar'];
                final imageUrl = data['post_img'];

                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 90),
                  children: [
                    // 🧑‍💻 Header (author info)
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFFDDE3F8),
                          backgroundImage:
                              avatar != null ? NetworkImage(avatar) : null,
                          child: avatar == null
                              ? const Icon(Icons.person,
                                  size: 20, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(author,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text(
                                createdAt != null ? _timeAgo(createdAt) : '',
                                style: const TextStyle(
                                    fontSize: 12, color: _muted),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // 📝 หัวข้อ
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 📄 เนื้อหา (ย้ายมาไว้เหนือรูป)
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 🖼 รูปภาพ (โชว์หลังเนื้อหา)
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          imageUrl,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const Padding(
                              padding: EdgeInsets.all(30),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    const Divider(thickness: 1.1),
                    const SizedBox(height: 8),

                    const Text(
                      'Comments',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
                    ),
                    const SizedBox(height: 10),

                    // 💬 Comments list
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('post')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('comment_time', descending: true)
                          .snapshots(),
                      builder: (context, snapC) {
                        if (snapC.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                        if (!snapC.hasData || snapC.data!.docs.isEmpty) {
                          return const Text("ยังไม่มีความคิดเห็น",
                              style: TextStyle(color: _muted));
                        }

                        return Column(
                          children: snapC.data!.docs.map((d) {
                            final c = d.data() as Map<String, dynamic>;
                            return _CommentTile(
                              name: c['authorName'] ?? 'Unknown',
                              avatar: c['authorAvatar'],
                              text: c['comment_content'] ?? '',
                              time:
                                  (c['comment_time'] as Timestamp?)?.toDate() ??
                                      DateTime.now(),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),

          // 💭 Comment input
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
                color: Colors.white,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentCtrl,
                      decoration: const InputDecoration(
                        hintText: "เขียนความคิดเห็น...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.blueAccent),
                    onPressed: _submitComment,
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ✅ Tile แสดงคอมเมนต์
class _CommentTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final String text;
  final DateTime time;
  const _CommentTile({
    required this.name,
    required this.text,
    required this.time,
    this.avatar,
  });

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFFD9E3FF),
            backgroundImage: avatar != null ? NetworkImage(avatar!) : null,
            child: avatar == null
                ? const Icon(Icons.person, size: 16, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(time),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8B90A0))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  text,
                  style: const TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}