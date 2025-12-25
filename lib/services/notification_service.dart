import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/notification_item.dart';

class NotificationService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String? _cachedUserDocId;

  Future<String?> _ensureDocId() async {
    if (_cachedUserDocId != null) return _cachedUserDocId;
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    _cachedUserDocId = snap.docs.first.id;
    return _cachedUserDocId;
  }

  Future<String?> getUserDocId() => _ensureDocId();

  Stream<List<NotificationItem>> notificationsStream() {
    return Stream.fromFuture(_ensureDocId()).asyncExpand((docId) {
      if (docId == null) return Stream.value(<NotificationItem>[]);
      return _db
          .collection('user')
          .doc(docId)
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .snapshots()
          .map((snap) =>
              snap.docs.map((doc) => NotificationItem.fromDoc(doc)).toList());
    });
  }

  Stream<int> unreadCountStream() {
    return Stream.fromFuture(_ensureDocId()).asyncExpand((docId) {
      if (docId == null) return Stream.value(0);
      return _db
          .collection('user')
          .doc(docId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .snapshots()
          .map((snap) => snap.size);
    });
  }

  Future<void> markAsRead(String notificationId) async {
    final docId = await _ensureDocId();
    if (docId == null) return;
    await _db
        .collection('user')
        .doc(docId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  Future<void> markAllAsRead() async {
    final docId = await _ensureDocId();
    if (docId == null) return;
    final snap = await _db
        .collection('user')
        .doc(docId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (snap.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    int ops = 0;
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'read': true});
      ops++;
      if (ops == 400) {
        await batch.commit();
        batch = _db.batch();
        ops = 0;
      }
    }
    if (ops > 0) await batch.commit();
  }
}
