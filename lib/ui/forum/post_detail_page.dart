// lib/ui/forum/post_detail_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // ✅ เพิ่ม

class PostDetailPage extends StatefulWidget {
  const PostDetailPage({super.key, required this.postId});
  final String postId;

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

  Future<void> _submitComment() async {
    final text = _commentCtrl.text.trim();
    if (text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // ✅ ดึงข้อมูลผู้ใช้จริงจาก Firestore
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add({
      'text': text,
      'authorId': user.uid,
      'authorName': userData?['displayName'] ??
          userData?['username'] ??
          user.email ??
          'Unknown',
      'authorAvatar': userData?['avatar'],
      'createdAt': FieldValue.serverTimestamp(),
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
            onPressed: () => context.pop()),
        title: const Text('Post'),
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .doc(widget.postId)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final data = snap.data!.data() as Map<String, dynamic>?;
                if (data == null) {
                  return const Center(child: Text("Post not found"));
                }

                final author = data['authorName'] ?? 'Unknown';
                final content = data['content'] ?? '';
                final createdAt =
                    (data['createdAt'] as Timestamp?)?.toDate();
                final avatar = data['authorAvatar']; // ✅ ดึงจาก Firestore

                return ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: const Color(0xFFDDE3F8),
                          backgroundImage: avatar != null
                              ? AssetImage('assets/avatars/$avatar')
                              : null,
                          child: avatar == null
                              ? const Icon(Icons.person,
                                  size: 18, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(author,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700)),
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
                    const SizedBox(height: 10),
                    Text(content,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 16),
                    const Text('Comments',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),

                    // ✅ Comments list
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('posts')
                          .doc(widget.postId)
                          .collection('comments')
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snapC) {
                        if (!snapC.hasData || snapC.data!.docs.isEmpty) {
                          return const Text("ยังไม่มีความคิดเห็น");
                        }
                        return Column(
                          children: snapC.data!.docs.map((d) {
                            final c = d.data() as Map<String, dynamic>;
                            return _CommentTile(
                              name: c['authorName'] ?? 'Unknown',
                              avatar: c['authorAvatar'],
                              text: c['text'] ?? '',
                              time: (c['createdAt'] as Timestamp?)?.toDate() ??
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

          // ✅ Input zone
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
                    icon: const Icon(Icons.send, color: Colors.blue),
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

class _CommentTile extends StatelessWidget {
  final String name;
  final String? avatar;
  final String text;
  final DateTime time;
  const _CommentTile(
      {required this.name,
      required this.text,
      required this.time,
      this.avatar});

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
      margin: const EdgeInsets.only(bottom: 8),
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
            backgroundImage:
                avatar != null ? AssetImage('assets/avatars/$avatar') : null,
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
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text(_timeAgo(time),
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF8B90A0))),
                  ],
                ),
                const SizedBox(height: 4),
                Text(text),
              ],
            ),
          ),
        ],
      ),
    );
  }
}