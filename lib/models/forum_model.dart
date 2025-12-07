import 'package:cloud_firestore/cloud_firestore.dart';

/// ✅ ForumPost Model — ใช้แทนโพสต์แต่ละรายการ
class ForumPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? imageUrl; // ✅ เพิ่มฟิลด์รูปภาพ
  final DateTime? createdAt;

  const ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.imageUrl,
    this.createdAt,
  });

  /// ✅ แปลงจาก Firestore document
  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ForumPost(
      id: doc.id,
      title: data['post_title'] ?? '',
      content: data['post_content'] ?? '',
      authorId: data['user_id']?.toString() ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorAvatar: data['authorAvatar'],
      imageUrl: data['post_img'], // ✅ รองรับรูปภาพ
      createdAt: (data['post_time'] is Timestamp)
          ? (data['post_time'] as Timestamp).toDate()
          : null,
    );
  }

  /// ✅ แปลงกลับเป็น Map สำหรับบันทึก Firestore
  Map<String, dynamic> toMap() => {
        'post_title': title,
        'post_content': content,
        'user_id': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'post_img': imageUrl,
        'post_time': createdAt ?? FieldValue.serverTimestamp(),
      };
}
