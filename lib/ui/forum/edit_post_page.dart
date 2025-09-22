// lib/ui/forum/edit_post_page.dart
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
  final _text = TextEditingController();
  bool _loading = false;
  String? _authorName;
  String? _avatar;
  String? _authorId; 
  String? _role;     

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadCurrentUserRole();
  }

  Future<void> _loadPost() async {
    final doc = await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _text.text = data['content'] ?? '';
        _authorName = data['authorName'];
        _avatar = data['authorAvatar'];
        _authorId = data['authorId'];
      });
    }
  }

  Future<void> _loadCurrentUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data != null) {
      setState(() {
        _role = data['role'] ?? 'student';
      });
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _deletePost(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('posts').doc(widget.postId).delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบโพสต์สำเร็จ')),
        );
        context.pop(); // กลับไปหน้ารายการ
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
    final canSave = _text.text.trim().isNotEmpty && !_loading;

    final currentUser = FirebaseAuth.instance.currentUser;
    final canManage = _role == 'admin' || (_authorId != null && currentUser?.uid == _authorId);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Post'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          // ✅ จุด 3 จุด (admin → ทุกโพสต์, เจ้าของ → ของตัวเอง)
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  // 👉 แก้ไขโพสต์ (จริง ๆ อยู่ในหน้านี้แล้ว แต่ทำไว้เผื่อ flow อื่น)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('คุณอยู่ในหน้าแก้ไขแล้ว')),
                  );
                } else if (value == 'delete') {
                  _deletePost(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'edit',
                  child: Text('แก้ไข'),
                ),
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
                  backgroundImage: _avatar != null
                      ? AssetImage('assets/avatars/$_avatar')
                      : null,
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
            Expanded(
              child: TextField(
                controller: _text,
                maxLines: null,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: 'Edit your post…',
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
          .collection('posts')
          .doc(widget.postId)
          .update({
        'content': _text.text.trim(),
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