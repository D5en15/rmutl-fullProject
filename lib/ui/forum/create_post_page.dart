import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;

  String? _fullname;
  String? _avatar;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('user') // ✅ ใช้ collection ล่าสุด
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (doc.docs.isEmpty) return;
    final data = doc.docs.first.data();

    setState(() {
      _fullname = data['user_fullname'] ?? user.email ?? 'Unknown';
      _avatar = data['user_img'];
      _userId = data['user_id'].toString();
    });
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPost = _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty &&
        !_loading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Create Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: canPost ? () => _submit(context) : null,
            child: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Post'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDDE3F8),
                  backgroundImage: _avatar != null ? NetworkImage(_avatar!) : null,
                  child: _avatar == null
                      ? const Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  _fullname ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Enter post title...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: TextField(
                controller: _contentCtrl,
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
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.image_outlined),
                ),
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

  Future<void> _submit(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเข้าสู่ระบบก่อนโพสต์')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      // ✅ หา post_id ล่าสุด
      final snap = await FirebaseFirestore.instance
          .collection('post')
          .orderBy('post_id', descending: true)
          .limit(1)
          .get();

      int newId = 1;
      if (snap.docs.isNotEmpty) {
        final lastIdStr = snap.docs.first['post_id'].toString();
        newId = int.parse(lastIdStr) + 1;
      }

      // ✅ ฟอร์แมตเป็น 3 หลัก เช่น 001, 002
      final formattedId = newId.toString().padLeft(3, '0');

      // ✅ ใช้ post_id เป็น doc id
      await FirebaseFirestore.instance.collection('post').doc(formattedId).set({
        'post_id': formattedId,
        'user_id': _userId,
        'post_title': _titleCtrl.text.trim(),
        'post_content': _contentCtrl.text.trim(),
        'post_img': null,
        'post_time': FieldValue.serverTimestamp(),
        'authorName': _fullname ?? user.email ?? 'Unknown',
        'authorAvatar': _avatar,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โพสต์สำเร็จ')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}