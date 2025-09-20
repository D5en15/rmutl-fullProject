import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // EmailJS config
  static const String emailJsServiceId = 'service_gi42co9';
  static const String emailJsTemplateId = 'template_uf9af69';
  static const String emailJsPublicKey = 'dk61mQ7FFN-eYQvkc';

  final _formKey = GlobalKey<FormState>();
  final _usernameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _agree = false;
  bool _loading = false;

  bool _otpSent = false;
  bool _otpVerified = false;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({bool isPassword = false, int? pwdField}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3D5CFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: isPassword
          ? IconButton(
              tooltip: (pwdField == 1 ? _obscure1 : _obscure2) ? 'Show' : 'Hide',
              icon: Icon(
                (pwdField == 1 ? _obscure1 : _obscure2)
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  if (pwdField == 1) {
                    _obscure1 = !_obscure1;
                  } else {
                    _obscure2 = !_obscure2;
                  }
                });
              },
            )
          : null,
    );
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _gen6() => List.generate(6, (_) => Random.secure().nextInt(10)).join();

  // ✅ Get OTP (เช็คอีเมลซ้ำใน Firebase Auth และ Firestore)
  Future<void> _getOtp() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) {
      _toast('กรอกอีเมลก่อน');
      return;
    }
    setState(() => _loading = true);

    try {
      // 🔎 เช็คใน Firebase Auth
      final methods =
          await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      if (methods.isNotEmpty) {
        _toast('อีเมลนี้ถูกใช้งานแล้ว');
        setState(() => _loading = false);
        return;
      }

      // 🔎 เช็คใน Firestore (users collection)
      final snap = await FirebaseFirestore.instance
          .collection("users")
          .where("email", isEqualTo: email)
          .limit(1)
          .get();
      if (snap.docs.isNotEmpty) {
        _toast('อีเมลนี้ถูกใช้งานแล้ว');
        setState(() => _loading = false);
        return;
      }

      // ✅ ถ้าไม่มีซ้ำ → สร้าง OTP
      final code = _gen6();
      final now = Timestamp.now();
      final expires =
          Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 10)));

      final otpRef =
          FirebaseFirestore.instance.collection('email_otps').doc(email);

      await otpRef.set({
        'code': code,
        'createdAt': now,
        'expiresAt': expires,
        'consumed': false,
      });

      // ส่งอีเมลผ่าน EmailJS
      final res = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'service_id': emailJsServiceId,
          'template_id': emailJsTemplateId,
          'user_id': emailJsPublicKey,
          'template_params': {
            'to_email': email,
            'code': code,
          },
        }),
      );

      if (res.statusCode >= 200 && res.statusCode < 300) {
        _otpSent = true;
        _otpVerified = false;
        _toast('ส่งรหัสไปที่อีเมลแล้ว (หมดอายุใน 10 นาที)');
      } else {
        _toast('ส่งอีเมลไม่สำเร็จ: ${res.statusCode}');
      }
      setState(() {});
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-email') {
        _toast('รูปแบบอีเมลไม่ถูกต้อง');
      } else {
        _toast('FirebaseAuth error: ${e.code}');
      }
    } catch (e) {
      _toast('ส่ง OTP ผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (!_otpSent) {
      _toast('ยังไม่ได้ส่ง OTP');
      return;
    }
    if (_otpCtrl.text.trim().length != 6) {
      _toast('กรอกรหัส OTP 6 หลัก');
      return;
    }

    setState(() => _loading = true);
    final email = _emailCtrl.text.trim();
    final input = _otpCtrl.text.trim();

    try {
      await FirebaseFirestore.instance
          .collection('email_otps')
          .doc(email)
          .collection('verify_attempts')
          .add({
        'code': input,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _otpVerified = true;
      _toast('ยืนยัน OTP สำเร็จ');
      setState(() {});
    } on FirebaseException catch (e) {
      _toast('OTP ไม่ถูกต้องหรือหมดอายุ: ${e.code}');
    } catch (e) {
      _toast('ยืนยัน OTP ผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false) || !_agree) {
      return;
    }
    if (!_otpVerified) {
      _toast('กรุณายืนยัน OTP ให้เรียบร้อย');
      return;
    }

    setState(() => _loading = true);
    final username = _usernameCtrl.text.trim();
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim().toLowerCase();
    final pass = _passCtrl.text;

    try {
      final cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: pass);
      final uid = cred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'username': username,
        'displayName': name,
        'email': email,
        'role': 'student',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('email_otps')
          .doc(email)
          .delete();

      _toast('สมัครสมาชิกสำเร็จ');
      if (!mounted) return;
      context.go('/login');
    } on FirebaseAuthException catch (e) {
      var msg = 'สมัครไม่สำเร็จ: ${e.code}';
      if (e.code == 'email-already-in-use') msg = 'อีเมลนี้ถูกใช้งานแล้ว';
      if (e.code == 'weak-password') msg = 'รหัสผ่านอ่อนเกินไป';
      if (e.code == 'invalid-email') msg = 'รูปแบบอีเมลไม่ถูกต้อง';
      _toast(msg);
    } catch (e) {
      _toast('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: const Color.fromARGB(255, 230, 230, 230),
          elevation: 0,
          flexibleSpace: const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                'Sign Up',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  const Text("Username",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _usernameCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter username'
                        : null,
                    decoration: _dec(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Name",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _nameCtrl,
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your name'
                        : null,
                    decoration: _dec(),
                  ),
                  const SizedBox(height: 20),
                  const Text("Email",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return 'Please enter email';
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                    decoration: _dec(),
                  ),
                  const SizedBox(height: 20),
                  const Text("OTP",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _otpCtrl,
                          keyboardType: TextInputType.number,
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Enter OTP' : null,
                          decoration: _dec(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed:
                              _loading ? null : (_otpSent ? _verifyOtp : _getOtp),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF3D5CFF)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          child: Text(
                            _otpSent ? "Verify" : "Get OTP",
                            style: const TextStyle(
                              color: Color(0xFF3D5CFF),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text("Password",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _obscure1,
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please enter password';
                      if (v.length < 8)
                        return 'Password must be at least 8 characters';
                      return null;
                    },
                    decoration: _dec(isPassword: true, pwdField: 1),
                  ),
                  const SizedBox(height: 20),
                  const Text("Confirm password",
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _obscure2,
                    textInputAction: TextInputAction.done,
                    validator: (v) {
                      if (v == null || v.isEmpty)
                        return 'Please confirm password';
                      if (v != _passCtrl.text) return 'Passwords do not match';
                      return null;
                    },
                    decoration: _dec(isPassword: true, pwdField: 2),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agree,
                        onChanged: (v) => setState(() => _agree = v ?? false),
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          'By creating an account you have to agree with our terms & conditions.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D5CFF),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Create account',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text(
                          'Log in',
                          style: TextStyle(
                            color: Color(0xFF3D5CFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}