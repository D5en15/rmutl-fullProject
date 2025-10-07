import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/user_model.dart';
import 'package:firebase_app_check/firebase_app_check.dart';

class RegisterService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  ); // ✅ ให้ตรง region

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
    final code = List.generate(6, (_) => Random.secure().nextInt(10)).join();

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
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug,
      );

      print('Sending email: $email, code: $code');
      final functions = FirebaseFunctions.instanceFor(region: 'us-central1');

      final result = await functions.httpsCallable('sendOtpEmail').call({
        'email': email,
        'code': code,
      });

      print('✅ Result: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Error: ${e.message}');
    } catch (e) {
      print('❌ Unexpected: $e');
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
    required String username,
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
        userId: uid,
        userName: username,
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
