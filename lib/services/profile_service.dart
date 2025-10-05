import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_model.dart';

class ProfileService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  /// ✅ โหลดข้อมูลผู้ใช้จาก Firestore
  Future<UserModel?> getUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final qs = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;
    return UserModel.fromMap(qs.docs.first.data());
  }

  /// ✅ อัปเดตข้อมูลผู้ใช้
  Future<void> updateUser(String docId, Map<String, dynamic> data) async {
    await _db.collection('user').doc(docId).update(data);
  }

  /// ✅ อัปโหลดรูปโปรไฟล์ → ส่ง URL กลับ
  Future<String> uploadAvatar(File file) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final ref = FirebaseStorage.instance.ref().child('avatars/${user.uid}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  /// ✅ ค้นหา docId ของผู้ใช้ปัจจุบัน
  Future<String?> getUserDocId() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    return snap.docs.isNotEmpty ? snap.docs.first.id : null;
  }
}