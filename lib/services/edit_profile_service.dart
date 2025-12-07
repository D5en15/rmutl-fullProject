import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
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

  /// ✅ Upload avatar (mobile/web safe – no crash from camera permissions)
  Future<String?> pickAndUploadAvatar(BuildContext context) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No logged-in user.');

    File? file;
    Uint8List? bytes;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      compressFormat: ImageCompressFormat.jpg,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Photo',
          toolbarColor: const Color(0xFF1E63E9),
          toolbarWidgetColor: Colors.white,
          activeControlsWidgetColor: const Color(0xFF1E63E9),
          hideBottomControls: true,
          lockAspectRatio: true,
        ),
        IOSUiSettings(
          title: 'Crop Photo',
          aspectRatioLockEnabled: true,
        ),
        if (kIsWeb)
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(width: 420, height: 420),
            dragMode: WebDragMode.crop,
            viewwMode: WebViewMode.mode_1,
          ),
      ],
    );
    if (cropped == null) return null;

    if (kIsWeb) {
      bytes = await cropped.readAsBytes();
    } else {
      file = File(cropped.path);
    }

    if (file == null && (bytes == null || bytes.isEmpty)) return null;

    final storageRef = _storage.ref().child('avatars/${user.uid}.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    try {
      if (file != null) {
        await storageRef.putFile(file, metadata);
      } else if (bytes != null) {
        await storageRef.putData(bytes, metadata);
      }
    } on FirebaseException catch (e) {
      debugPrint("Upload failed: $e");
      rethrow;
    }

    final url = await storageRef.getDownloadURL();
    await _updateUserImage(url);
    return url;
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
