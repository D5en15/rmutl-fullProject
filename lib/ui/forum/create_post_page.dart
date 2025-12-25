import 'dart:io' show File;
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/forum_service.dart';

const _announcementColor = Color(0xFF3D5CFF);

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _service = ForumService();

  bool _loading = false;
  String? _fullname;
  String? _avatar;
  String? _userId;
  String? _role;
  bool _isAnnouncement = false;
  Uint8List? _imageBytes;

  bool get _isTeacher => (_role ?? '').toLowerCase() == 'teacher';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    final fallbackUid = user?.uid;
    if (user == null) return;

    try {
      final snap = await _service.db
          .collection('user')
          .where('user_email', isEqualTo: user.email)
          .limit(1)
          .get();

      if (snap.docs.isNotEmpty) {
        final data = snap.docs.first.data();
        setState(() {
          _fullname = data['user_fullname'] ?? user.email ?? 'Unknown';
          _avatar = data['user_img'];
          _userId = data['user_id']?.toString();
          _role = data['user_role']?.toString();
        });
        return;
      }
    } catch (_) {
      // ignore and fallback
    }

    if (fallbackUid != null) {
      setState(() {
        _fullname = user.email ?? 'Unknown';
        _avatar = null;
        _userId = fallbackUid;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        return;
      }
      final picked = result.files.first;
      Uint8List? bytes = picked.bytes;
      if (bytes == null && !kIsWeb && picked.path != null) {
        try {
          bytes = await File(picked.path!).readAsBytes();
        } catch (_) {
          bytes = null;
        }
      }
      if (bytes == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not read image file.')),
        );
        return;
      }
      setState(() => _imageBytes = bytes);
    } catch (e) {
      debugPrint('Error selecting image: $e');
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                  _fullname ?? 'Loading... ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
            TextField(
              controller: _contentCtrl,
              maxLines: null,
              minLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Write something...',
                border: InputBorder.none,
              ),
            ),
            const SizedBox(height: 4),
            if (_isTeacher) ...[
              _AnnouncementToggle(
                value: _isAnnouncement,
                onChanged: (val) => setState(() => _isAnnouncement = val),
              ),
              const SizedBox(height: 8),
            ],
            if (_imageBytes != null) ...[
              const SizedBox(height: 6),
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: GestureDetector(
                      onTap: () => _showImagePreview(_imageBytes!),
                      child: AspectRatio(
                        aspectRatio: 3 / 4,
                        child: Image.memory(
                          _imageBytes!,
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
                        onPressed: () => setState(() => _imageBytes = null),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image_outlined),
                    tooltip: 'Add image',
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Add image',
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

  Future<void> _submit(BuildContext context) async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in before posting')),
      );
      return;
    }

    DateTime? lastTime;
    try {
      final latest = await _service.db
          .collection('post')
          .where('user_id', isEqualTo: _userId)
          .orderBy('post_time', descending: true)
          .limit(1)
          .get();
      if (latest.docs.isNotEmpty) {
        lastTime =
            (latest.docs.first.data()['post_time'] as Timestamp?)?.toDate();
      }
    } catch (_) {
      final fallback = await _service.db
          .collection('post')
          .where('user_id', isEqualTo: _userId)
          .get();
      for (final d in fallback.docs) {
        final t = (d.data()['post_time'] as Timestamp?)?.toDate();
        if (t != null && (lastTime == null || t.isAfter(lastTime))) {
          lastTime = t;
        }
      }
    }

    if (lastTime != null) {
      final now = DateTime.now();
      final nextAllowed = lastTime.add(const Duration(days: 1));
      final remaining = nextAllowed.difference(now);
      if (remaining > Duration.zero) {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes.remainder(60);
        final countdown =
            hours > 0 ? '${hours}h ${minutes.toString().padLeft(2, '0')}m' : '${minutes}m';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'You can post again in $countdown. Please wait 24 hours between posts.',
            ),
          ),
        );
        return;
      }
    }

    setState(() => _loading = true);

    try {
      await _service.createPost(
        userId: _userId!,
        title: _titleCtrl.text.trim(),
        content: _contentCtrl.text.trim(),
        authorName: _fullname ?? authUser.email ?? 'Unknown',
        authorAvatar: _avatar,
        imageBytes: _imageBytes,
        isAnnouncement: _isTeacher && _isAnnouncement,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post created successfully')),
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

  void _showImagePreview(Uint8List bytes) {
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
                constraints:
                    const BoxConstraints.tightFor(width: 40, height: 40),
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
}

class _AnnouncementToggle extends StatelessWidget {
  const _AnnouncementToggle({
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F7FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send as announcement',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Notify every user about this post.',
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: _announcementColor,
          ),
        ],
      ),
    );
  }
}
