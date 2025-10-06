import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  /// ✅ โหลดข้อมูลผู้ใช้จาก Firestore (แนบ docId กลับไปด้วย)
  Future<Map<String, dynamic>?> loadProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final qs = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (qs.docs.isEmpty) return null;

    final doc = qs.docs.first;
    final data = doc.data();

    // ✅ แนบ docId เข้าไปเพื่อให้หน้าฟอร์มใช้ตอน update
    data['docId'] = doc.id;

    debugPrint("✅ Loaded user document: ${doc.id}");
    return data;
  }

  /// ✅ Upload + Crop รูปก่อนบันทึก
  Future<String?> pickAndUploadAvatar(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    XFile? picked;

    if (kIsWeb) {
      // 🌐 Web — ใช้ file_picker
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      if (result == null || result.files.single.bytes == null) return null;

      // ✅ Upload ตรงไปยัง Storage
      final storageRef = _storage.ref().child('avatars/${user.uid}.jpg');
      await storageRef.putData(
        result.files.single.bytes!,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final url = await storageRef.getDownloadURL();
      await _updateUserImage(url);
      return url;
    } else {
      // 📱 Mobile/Desktop
      picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked == null) return null;

      // ✂️ Crop 1:1 ก่อนอัปโหลด
      final cropped = await ImageCropper().cropImage(
        sourcePath: picked.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Image',
            toolbarColor: Colors.blue,
            toolbarWidgetColor: Colors.white,
            lockAspectRatio: true,
          ),
          IOSUiSettings(title: 'Crop Profile Image'),
        ],
      );

      if (cropped == null) return null;

      // ✅ Upload หลัง crop เสร็จ
      final storageRef = _storage.ref().child('avatars/${user.uid}.jpg');
      await storageRef.putFile(File(cropped.path));
      final url = await storageRef.getDownloadURL();
      await _updateUserImage(url);
      return url;
    }
  }

  /// ✅ บันทึก URL ลง Firestore
  Future<void> _updateUserImage(String url) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final qs = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (qs.docs.isNotEmpty) {
      final docId = qs.docs.first.id;
      await _db.collection('user').doc(docId).update({'user_img': url});
      debugPrint("🪄 Updated user_img for uid: ${user.uid}");
    } else {
      debugPrint("⚠️ No user document found to update image.");
    }
  }

  /// ✅ อัปเดตข้อมูลโปรไฟล์
  Future<void> updateProfile(String docId, Map<String, dynamic> payload) async {
    await _db.collection('user').doc(docId).update(payload);
    debugPrint("✅ Profile updated for docId: $docId");
  }
}