import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/settings_model.dart';

class SettingsService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  /// โหลดข้อมูลผู้ใช้ปัจจุบัน
  Future<SettingsModel?> loadUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final snap = await _db
        .collection('user')
        .where('user_email', isEqualTo: user.email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    return SettingsModel.fromMap(snap.docs.first.data());
  }

  /// ส่งลิงก์รีเซ็ตรหัสผ่าน
  Future<void> sendResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// ออกจากระบบ
  Future<void> logout() async {
    await _auth.signOut();
  }
}