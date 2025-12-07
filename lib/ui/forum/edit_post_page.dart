import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../services/forum_service.dart';
import '../../models/forum_model.dart';

class EditPostPage extends StatefulWidget {
  final String postId;
  const EditPostPage({super.key, required this.postId});

  @override
  State<EditPostPage> createState() => _EditPostPageState();
}

class _EditPostPageState extends State<EditPostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _service = ForumService();

  bool _loading = false;
  String? _authorName;
  String? _avatar;
  String? _authorId;
  String? _role;
  String? _userId;
  String? _imageUrl;
  Uint8List? _newImage;

  @override
  void initState() {
    super.initState();
    _loadPost();
    _loadCurrentUser();
  }

  void _showFullImageMemory(Uint8List bytes) {
    if (bytes.isEmpty) return;
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (dialogCtx) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogCtx).pop(),
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: InteractiveViewer(
                child: Image.memory(bytes),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: IconButton(
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImageNetwork(String url) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      barrierDismissible: true,
      builder: (dialogCtx) => Stack(
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.of(dialogCtx).pop(),
            child: Container(
              color: Colors.black,
              alignment: Alignment.center,
              child: InteractiveViewer(
                child: Image.network(url),
              ),
            ),
          ),
          Positioned(
            top: 30,
            right: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.2),
              ),
              child: IconButton(
                constraints: const BoxConstraints.tightFor(width: 40, height: 40),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(dialogCtx).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 22),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadPost() async {
    final post = await _service.getPostById(widget.postId);
    if (post != null) {
      final snap = await _service.db.collection('post').doc(widget.postId).get();
      final data = snap.data()!;
      setState(() {
        _titleCtrl.text = post.title;
        _contentCtrl.text = post.content;
        _authorName = data['authorName'];
        _avatar = data['authorAvatar'];
        _authorId = data['user_id'];
        _imageUrl = data['post_img'];
      });
    }
  }

  Future<void> _loadCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snap = await _service.db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final data = snap.docs.first.data();
      setState(() {
        _role = data['user_role'] ?? 'student';
        _userId = data['user_id'].toString();
      });
    }
  }

  Future<void> _pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      setState(() => _newImage = result.files.first.bytes);
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
    final canSave = _titleCtrl.text.trim().isNotEmpty &&
        _contentCtrl.text.trim().isNotEmpty &&
        !_loading;

    final canManage =
        _role == 'admin' || (_authorId != null && _userId == _authorId);

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
                child: Text('Delete post'),
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
                : const Text(
                    'Save',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🧑 Header: author info
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
                  _authorName ?? 'Loading...',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 📝 Title
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
                hintText: 'Edit post title...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 8),

            // ✏️ Content
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              minLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Edit your content...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 4),

            // 🖼️ Preview (if has image)
            if (_newImage != null || (_imageUrl != null && _imageUrl!.isNotEmpty))
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: GestureDetector(
                        onTap: () {
                          if (_newImage != null) {
                            _showFullImageMemory(_newImage!);
                          } else if (_imageUrl != null &&
                              _imageUrl!.isNotEmpty) {
                            _showFullImageNetwork(_imageUrl!);
                          }
                        },
                        child: AspectRatio(
                          aspectRatio: 3 / 4,
                          child: _newImage != null
                              ? Image.memory(
                                  _newImage!,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _imageUrl!,
                                  fit: BoxFit.cover,
                                ),
                        ),
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
                          onPressed: () =>
                              setState(() => {_newImage = null, _imageUrl = null}),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 10),

            // 📸 ปุ่มเปลี่ยนรูป (ชิดซ้าย)
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Change image',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    "Change image",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ บันทึกโพสต์
  Future<void> _submit(BuildContext context) async {
    if (!_titleCtrl.text.trim().isNotEmpty ||
        !_contentCtrl.text.trim().isNotEmpty) return;

    setState(() => _loading = true);

    try {
      String? imageUrl = _imageUrl;

      if (_newImage != null) {
        imageUrl = await _service.uploadPostImage(_newImage!, widget.postId);
      }

      await _service.updatePost(widget.postId, {
        'post_title': _titleCtrl.text.trim(),
        'post_content': _contentCtrl.text.trim(),
        'post_img': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post updated')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// ✅ ลบโพสต์
  Future<void> _deletePost(BuildContext context) async {
    try {
      await _service.deletePost(widget.postId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post deleted')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}
