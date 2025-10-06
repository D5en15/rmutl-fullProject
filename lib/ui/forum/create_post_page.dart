import 'dart:typed_data';
import 'package:flutter/foundation.dart' show Uint8List;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';

import '../../services/forum_service.dart';
import '../../models/forum_model.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _service = ForumService(); // ✅ ใช้ ForumService ที่แยกออกไปแล้ว

  bool _loading = false;
  String? _fullname;
  String? _avatar;
  String? _userId;

  Uint8List? _webImage; // ✅ เก็บภาพที่เลือก (รองรับเว็บด้วย)

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// ✅ โหลดข้อมูลผู้ใช้จาก Firestore
  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _service.db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return;
    final data = snap.docs.first.data();

    setState(() {
      _fullname = data['user_fullname'] ?? user.email ?? 'Unknown';
      _avatar = data['user_img'];
      _userId = data['user_id'].toString();
    });
  }

  /// ✅ เลือกรูปภาพ (รองรับเว็บ)
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        setState(() => _webImage = result.files.first.bytes);
      }
    } catch (e) {
      debugPrint('❌ Error selecting image: $e');
    }
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
                : const Text(
                    'Post',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧑‍💻 Header (Avatar + Name)
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: const Color(0xFFDDE3F8),
                  backgroundImage:
                      _avatar != null ? NetworkImage(_avatar!) : null,
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

            // 📝 Title field — ไม่มีกรอบ และตัดบรรทัดอัตโนมัติ
            TextField(
              controller: _titleCtrl,
              onChanged: (_) => setState(() {}),
              maxLines: null,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              decoration: const InputDecoration(
                hintText: 'Enter post title...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),

            // ✏️ Content field
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

            // 🖼 Preview รูปภาพ
            if (_webImage != null) ...[
              const SizedBox(height: 10),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      _webImage!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 14,
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 14),
                        onPressed: () => setState(() => _webImage = null),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),

            // 📸 ปุ่มเพิ่มรูปภาพ
            Row(
              children: [
                IconButton(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Add image',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ เมื่อกดโพสต์
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
      // ✅ ใช้ ForumService ที่แยกไว้
      await _service.createPost(
        userId: _userId!,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        authorName: _fullname ?? user.email ?? 'Unknown',
        authorAvatar: _avatar,
        imageBytes: _webImage,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โพสต์สำเร็จ!')),
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