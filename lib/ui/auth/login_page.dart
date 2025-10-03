import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailOrUserController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool obscurePassword = true;
  bool loading = false;

  final bool navigateAfterLogin = true;

  @override
  void dispose() {
    emailOrUserController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final input = emailOrUserController.text.trim();
    final password = passwordController.text;

    if (input.isEmpty || password.isEmpty) {
      _toast('กรอกอีเมล/ชื่อผู้ใช้ และรหัสผ่าน');
      return;
    }

    setState(() => loading = true);
    try {
      debugPrint('🔐 login with: $input');

      String? emailToLogin = input;

      // 👉 ถ้า input ไม่ใช่อีเมล → ให้หาจาก Firestore ว่าเป็น username
      if (!input.contains('@')) {
        final snap = await FirebaseFirestore.instance
            .collection('user')
            .where('user_name', isEqualTo: input)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          _toast('❌ ไม่พบบัญชีผู้ใช้');
          setState(() => loading = false);
          return;
        }

        emailToLogin = snap.docs.first.data()['user_email'] as String?;
      }

      if (emailToLogin == null || emailToLogin.isEmpty) {
        _toast('❌ บัญชีนี้ไม่มีอีเมลสำหรับเข้าสู่ระบบ');
        setState(() => loading = false);
        return;
      }

      // ✅ Auth ตรวจสอบ email/password
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: emailToLogin, password: password);

      final uid = cred.user!.uid;
      debugPrint('✅ Auth OK uid=$uid');

      // ✅ ดึงข้อมูล Firestore (collection user)
      final doc =
          await FirebaseFirestore.instance.collection('user').doc(uid).get();

      if (!doc.exists) {
        _toast('❌ ไม่พบบัญชีใน Firestore');
        return;
      }

      final data = doc.data()!;
      final role = (data['user_role'] as String?)?.toLowerCase();

      if (role == null || role.isEmpty) {
        _toast('❌ บัญชีนี้ไม่มี role');
        return;
      }

      _toast('✅ เข้าสู่ระบบสำเร็จ (role=$role)');

      if (!mounted || !navigateAfterLogin) return;

      switch (role) {
        case 'admin':
          context.go('/admin');
          break;
        case 'teacher':
          context.go('/teacher');
          break;
        default:
          context.go('/student');
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Auth error: code=${e.code}, msg=${e.message}');
      _toast('เข้าสู่ระบบไม่สำเร็จ: ${e.message}');
    } catch (e) {
      debugPrint('❌ Unknown: $e');
      _toast('เกิดข้อผิดพลาด: $e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  InputDecoration _dec({bool isPassword = false}) {
    return InputDecoration(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF3D5CFF)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      suffixIcon: isPassword
          ? IconButton(
              tooltip: obscurePassword ? 'Show' : 'Hide',
              icon: Icon(
                obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => obscurePassword = !obscurePassword),
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          backgroundColor: const Color.fromARGB(255, 230, 230, 230),
          elevation: 0,
          flexibleSpace: const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.only(left: 16, bottom: 16),
              child: Text(
                'Log In',
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const Text(
                  "Email or Username",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: emailOrUserController,
                  textInputAction: TextInputAction.next,
                  decoration: _dec(),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Password",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  onSubmitted: (_) => _login(),
                  decoration: _dec(isPassword: true),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push('/forgot'),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(
                        color: Color.fromARGB(255, 180, 180, 180),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3D5CFF),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Log In',
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
                    const Text("Don't have an account? "),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text(
                        'Sign up',
                        style: TextStyle(
                          color: Color(0xFF3D5CFF),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'Or login with',
                        style: TextStyle(
                          color: cs.onSurfaceVariant,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.g_mobiledata_rounded),
                    label: const Text(
                      'Continue with Google',
                      style: TextStyle(color: Color(0xFF3D5CFF)),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF3D5CFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}