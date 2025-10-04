import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditPostPage extends StatefulWidget {
  const EditPostPage({super.key, required this.postId});
  final String postId;

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  bool _loading = false;
  String? _authorName;
  String? _avatar;
  String? _authorId;
  String? _role;
  String? _userId; // ✅ user_id ของ current user (จาก table user)

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadCurrentUser();
  }

  Future<void> _loadPost() async {
    final doc = await FirebaseFirestore.instance
        .collection('post') // ✅ ใช้ collection ใหม่
        .doc(widget.postId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _titleCtrl.text = data['post_title'] ?? '';
        _contentCtrl.text = data['post_content'] ?? '';
        _authorName = data['authorName'];
        _avatar = data['authorAvatar'];
        _authorId = data['user_id']; // ✅ foreign key
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('user') // ✅ collection ล่าสุด
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (doc.docs.isNotEmpty) {
      final data = doc.docs.first.data();
      setState(() {
        _role = data['user_role'] ?? 'student';
        _userId = data['user_id'].toString(); // ✅ เก็บ user_id ที่แม็ปกับ post
      });
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    super.dispose();
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance
          .collection('post') // ✅ ใช้ collection ใหม่
          .doc(widget.postId)
          .delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโพสต์สำเร็จ')),
        );
        context.pop(); // กลับไปหน้า list
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
    final canSave = _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty &&
        !_loading;

    // ✅ เปลี่ยนการตรวจสอบ: เทียบ user_id (DB) แทน uid (Firebase)
    final canManage = _role == 'admin' || (_authorId != null && _userId == _authorId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') {
                  _deletePost(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: Text('ลบ'),
                ),
              ],
            ),
          TextButton(
            onPressed: canSave ? () => _submit(context) : null,
            child: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
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
                  _authorName ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                hintText: 'Edit post title…',
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
                  hintText: 'Edit your post content…',
                  border: InputBorder.none,
                ),
              ),
            ),
            Row(
              children: [
                const Spacer(),
                FilledButton(
                  onPressed: canSave ? () => _submit(context) : null,
                  child: const Text('Save'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuildContext context) async {
    setState(() => _loading = true);

    try {
      await FirebaseFirestore.instance
          .collection('post') // ✅ ใช้ collection ใหม่
          .doc(widget.postId)
          .update({
        'post_title': _titleCtrl.text.trim(),
        'post_content': _contentCtrl.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('อัปเดตโพสต์เรียบร้อย')),
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