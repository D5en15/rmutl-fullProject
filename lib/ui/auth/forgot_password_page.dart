import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) {
      _toast("กรอกอีเมลก่อน");
      return;
    }

    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('user')
          .where('user_email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        _toast("❌ ไม่พบบัญชีนี้ในระบบ");
        setState(() => _loading = false);
        return;
      }

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      _toast("📩 ลิงก์รีเซ็ตรหัสผ่านถูกส่งไปที่ $email แล้ว");

      if (mounted) context.go("/login");
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        _toast("❌ ไม่พบบัญชีนี้ในระบบ");
      } else {
        _toast("Auth Error: ${e.message}");
      }
    } catch (e) {
      _toast("Error: $e");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec() {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3D5CFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
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
                'Forgot Password',
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
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),

            // 👉 Email Field แบบเดียวกับหน้า Login
            const Text(
              "Email",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: _dec(),
            ),

            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: const Color(0xFF3D5CFF),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Reset Password",
                      style: TextStyle(color: Colors.white),
                    ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Remember your password?  ",
                  style: TextStyle(color: Colors.black54),
                ),
                TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    "Log in",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}