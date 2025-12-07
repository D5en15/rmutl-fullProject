import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/forum_model.dart';

/// ✅ ForumService — จัดการ Firestore และ Storage สำหรับโพสต์ใน Forum
class ForumService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// ✅ เปิดให้เข้าถึง Firestore instance ได้แบบปลอดภัย
  FirebaseFirestore get db => _db;

  /// ✅ ดึงโพสต์ทั้งหมด (เรียงตามเวลา)
  Stream<QuerySnapshot<Map<String, dynamic>>> getPosts() {
    return _db
        .collection('post')
        .orderBy('post_time', descending: true)
        .snapshots();
  }

  /// ✅ ดึงโพสต์เดียว
  Future<ForumPost?> getPostById(String id) async {
    final doc = await _db.collection('post').doc(id).get();
    return doc.exists ? ForumPost.fromDoc(doc) : null;
  }

  /// ✅ สร้างโพสต์ใหม่ (รองรับรูปภาพ)
  Future<void> createPost({
    required String userId,
    required String title,
    required String content,
    required String authorName,
    String? authorAvatar,
    Uint8List? imageBytes,
  }) async {
    // หา post_id ล่าสุด
    final snap = await _db
        .collection('post')
        .orderBy('post_id', descending: true)
        .limit(1)
        .get();

    int newId = 1;
    if (snap.docs.isNotEmpty) {
      final lastIdStr = snap.docs.first['post_id'].toString();
      newId = int.tryParse(lastIdStr) != null ? int.parse(lastIdStr) + 1 : 1;
    }
    final formattedId = newId.toString().padLeft(3, '0');

    // ✅ ถ้ามีรูป → upload
    String? imageUrl;
    if (imageBytes != null) {
      imageUrl = await uploadPostImage(imageBytes, formattedId);
    }

    await _db.collection('post').doc(formattedId).set({
      'post_id': formattedId,
      'user_id': userId,
      'post_title': title,
      'post_content': content,
      'post_img': imageUrl,
      'post_time': FieldValue.serverTimestamp(),
      'authorName': authorName,
      'authorAvatar': authorAvatar,
    });
  }

  /// ✅ อัปโหลดรูปภาพ (รองรับเว็บ)
  Future<String?> uploadPostImage(Uint8List bytes, String postId) async {
    if (bytes.isEmpty) {
      throw Exception('Image is empty.');
    }

    Future<String> _upload(String path) async {
      final ref = _storage.ref().child(path);
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      return ref.getDownloadURL();
    }

    try {
      return await _upload('post_images/$postId.jpg');
    } catch (_) {
      // Fallback: unique name to avoid any stale reference issues
      final ts = DateTime.now().millisecondsSinceEpoch;
      return await _upload('post_images/${postId}_$ts.jpg');
    }
  }

  /// ✅ อัปเดตโพสต์
  Future<void> updatePost(String id, Map<String, dynamic> data) async {
    await _db.collection('post').doc(id).update(data);
  }

  /// ✅ ลบโพสต์ (พร้อมลบ comments ย่อย)
  Future<void> deletePost(String id) async {
    final postRef = _db.collection('post').doc(id);
    final comments = await postRef.collection('comments').get();

    for (var c in comments.docs) {
      await c.reference.delete();
    }

    await postRef.delete();
  }

  /// ✅ ดึงโพสต์ของ user
  Stream<QuerySnapshot<Map<String, dynamic>>> getMyPosts(String userId) {
    return _db
        .collection('post')
        .where('user_id', isEqualTo: userId)
        .orderBy('post_time', descending: true)
        .snapshots();
  }

  /// ✅ ค้นหาด้วย keyword (หัวข้อ / ชื่อผู้โพสต์)
  Stream<QuerySnapshot<Map<String, dynamic>>> searchPosts(String query) {
    // หมายเหตุ: Firestore ยังไม่รองรับ OR-search จริง ๆ → ใช้ client-side filter
    return _db
        .collection('post')
        .orderBy('post_time', descending: true)
        .snapshots();
  }
}
