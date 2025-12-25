import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationItem {
  final String id;
  final String title;
  final String body;
  final DateTime? createdAt;
  final bool read;
  final String? postId;
  final String type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.read,
    required this.type,
    this.postId,
  });

  factory NotificationItem.fromDoc(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return NotificationItem(
      id: doc.id,
      title: data['title'] ?? 'Notification',
      body: data['body'] ?? '',
      postId: data['post_id'],
      type: data['type'] ?? 'general',
      read: (data['read'] ?? false) == true,
      createdAt: (data['created_at'] is Timestamp)
          ? (data['created_at'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'post_id': postId,
        'type': type,
        'read': read,
        'created_at': createdAt ?? FieldValue.serverTimestamp(),
      };
}
