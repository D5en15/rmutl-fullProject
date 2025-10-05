import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> sendResetLink(String email) async {
    final lowerEmail = email.trim().toLowerCase();

    // 🔍 ตรวจสอบอีเมลใน Firestore
    final userSnap = await _db
        .collection('user')
        .where('user_email', isEqualTo: lowerEmail)
        .limit(1)
        .get();

    if (userSnap.docs.isEmpty) {
      throw Exception("No account found with this email.");
    }

    // 📩 ส่งลิงก์รีเซ็ตรหัสผ่าน
    await _auth.sendPasswordResetEmail(email: lowerEmail);
  }
}