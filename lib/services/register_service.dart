import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class RegisterService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  static const _otpEndpoint =
      'https://us-central1-rmutl-fullproject.cloudfunctions.net/sendOtpEmail';

  String _generateOtp() {
    final random = Random.secure();
    final value = 100000 + random.nextInt(900000);
    return value.toString();
  }

  /// ✅ ส่ง OTP ผ่าน Firebase Cloud Function
  Future<void> sendOtp(String email) async {
    // 🔹 ตรวจสอบอีเมลซ้ำ
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.isNotEmpty) throw Exception('This email is already in use.');

    final exists =
        await _db
            .collection('user')
            .where('user_email', isEqualTo: email)
            .limit(1)
            .get();
    if (exists.docs.isNotEmpty)
      throw Exception('This email is already in use.');

    // 🔹 สร้างรหัส OTP 6 หลัก
    final code = _generateOtp();

    // 🔹 บันทึกลง Firestore
    final now = Timestamp.now();
    final expires = Timestamp.fromDate(
      DateTime.now().add(const Duration(minutes: 10)),
    );
    await _db.collection('email_otp').doc(email).set({
      'otp_code': code,
      'otp_created': now,
      'otp_expire': expires,
    });
    try {
      final response = await http.post(
        Uri.parse(_otpEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'code': code}),
      );

      if (response.statusCode != 200) {
        String message = 'Failed to send OTP.';
        try {
          final body = jsonDecode(response.body);
          if (body is Map && body['error'] is String) {
            message = body['error'] as String;
          }
        } catch (_) {}
        throw Exception(message);
      }
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  /// ✅ ตรวจสอบ OTP
  Future<void> verifyOtp(String email, String otp) async {
    final doc = await _db.collection('email_otp').doc(email).get();
    if (!doc.exists) throw Exception('OTP not found.');

    final data = doc.data()!;
    final code = data['otp_code'] as String;
    final expires = (data['otp_expire'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expires)) {
      throw Exception('OTP expired.');
    }
    if (otp != code) {
      throw Exception('Invalid OTP code.');
    }

  }

  /// ✅ ลงทะเบียนผู้ใช้ใหม่
  Future<void> register({
    required String studentId,
    required String fullname,
    required String email,
    required String password,
  }) async {
    try {
      // สร้างบัญชีใน Firebase Auth
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final uid = cred.user!.uid;

      // บันทึกข้อมูลใน Firestore
      final newUser = UserModel(
        userId: studentId,
        userName: studentId,
        fullName: fullname,
        email: email,
        role: 'Student',
      );

      await _db.collection('user').doc(uid).set(newUser.toMap());

      // ลบ OTP ที่ใช้แล้ว
      await _db.collection('email_otp').doc(email).delete();
    } catch (e) {
      throw Exception('Failed to register user: $e');
    }
  }
}
