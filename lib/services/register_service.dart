import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class RegisterService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  // EmailJS config
  static const _serviceId = 'service_gi42co9';
  static const _templateId = 'template_uf9af69';
  static const _publicKey = 'dk61mQ7FFN-eYQvkc';

  /// ✅ Send OTP to email
  Future<void> sendOtp(String email) async {
    final methods = await _auth.fetchSignInMethodsForEmail(email);
    if (methods.isNotEmpty) throw Exception('This email is already in use.');

    final exists = await _db
        .collection('user')
        .where('user_email', isEqualTo: email)
        .limit(1)
        .get();
    if (exists.docs.isNotEmpty) throw Exception('This email is already in use.');

    final code = List.generate(6, (_) => Random.secure().nextInt(10)).join();
    final now = Timestamp.now();
    final expires =
        Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10)));

    await _db.collection('email_otp').doc(email).set({
      'otp_code': code,
      'otp_created': now,
      'otp_expire': expires,
    });

    final res = await http.post(
      Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'service_id': _serviceId,
        'template_id': _templateId,
        'user_id': _publicKey,
        'template_params': {'to_email': email, 'code': code},
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Failed to send OTP email (${res.statusCode}).');
    }
  }

  /// ✅ Verify OTP
  Future<void> verifyOtp(String email, String otp) async {
    final doc = await _db.collection('email_otp').doc(email).get();
    if (!doc.exists) throw Exception('OTP not found.');

    final data = doc.data()!;
    final code = data['otp_code'] as String;
    final expires = (data['otp_expire'] as Timestamp).toDate();

    if (DateTime.now().isAfter(expires)) throw Exception('OTP expired.');
    if (otp != code) throw Exception('Invalid OTP code.');
  }

  /// ✅ Register new student
  Future<void> register({
    required String username,
    required String fullname,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;

    final newUser = UserModel(
      userId: uid,
      userName: username,
      fullName: fullname,
      email: email,
      role: 'Student',
    );

    await _db.collection('user').doc(uid).set(newUser.toMap());
    await _db.collection('email_otp').doc(email).delete();
  }
}