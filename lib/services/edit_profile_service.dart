import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// ✅ โหลดข้อมูลผู้ใช้จาก Firestore
  Future<Map<String, dynamic>?> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final qs = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    return qs.docs.isEmpty ? null : qs.docs.first.data();
  }

  /// ✅ บันทึกข้อมูลโปรไฟล์กลับ Firestore
  Future<void> updateProfile(String docId, Map<String, dynamic> payload) async {
    await _db.collection('user').doc(docId).update(payload);
  }

  /// ✅ เลือกรูปจากอุปกรณ์ (มือถือ/เว็บ)
  Future<String?> pickAndUploadAvatar() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return null;

    final storageRef = _storage.ref().child('avatars/${user.uid}.jpg');

    if (kIsWeb) {
      // สำหรับเว็บ: ใช้ putData()
      final bytes = await picked.readAsBytes();
      await storageRef.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    } else {
      // สำหรับมือถือ/เดสก์ท็อป
      await storageRef.putFile(File(picked.path));
    }

    return await storageRef.getDownloadURL();
  }
}