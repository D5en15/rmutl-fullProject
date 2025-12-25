import 'package:cloud_firestore/cloud_firestore.dart';

/// ForumPost model
class ForumPost {
  final String id;
  final String title;
  final String content;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String? imageUrl;
  final DateTime? createdAt;
  final bool isAnnouncement;

  const ForumPost({
    required this.id,
    required this.title,
    required this.content,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    this.imageUrl,
    this.createdAt,
    this.isAnnouncement = false,
  });

  factory ForumPost.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ForumPost(
      id: doc.id,
      title: data['post_title'] ?? '',
      content: data['post_content'] ?? '',
      authorId: data['user_id']?.toString() ?? '',
      authorName: data['authorName'] ?? 'Unknown',
      authorAvatar: data['authorAvatar'],
      imageUrl: data['post_img'],
      isAnnouncement: (data['is_announcement'] ?? false) == true,
      createdAt: (data['post_time'] is Timestamp)
          ? (data['post_time'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'post_title': title,
        'post_content': content,
        'user_id': authorId,
        'authorName': authorName,
        'authorAvatar': authorAvatar,
        'is_announcement': isAnnouncement,
        'post_img': imageUrl,
        'post_time': createdAt ?? FieldValue.serverTimestamp(),
      };
}
