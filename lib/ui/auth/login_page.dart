import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/app_toast.dart'; // ✅ ใช้ระบบแจ้งเตือนกลาง

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool obscure = true;
  bool loading = false;

  Future<void> _login() async {
    final input = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();

    if (input.isEmpty || pass.isEmpty) {
      AppToast.info(context, "Please enter your email/username and password.");
      return;
    }

    setState(() => loading = true);
    try {
      final result = await _authService.login(input, pass);
      // ✅ แปลง role เป็นตัวพิมพ์เล็กก่อนตรวจสอบ
      final role = (result['role'] ?? '').toString().toLowerCase();

      AppToast.success(context, 'Login successful.');

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
    } on AuthException catch (e) {
      AppToast.error(context, e.message);
    } catch (_) {
      AppToast.error(context, "Invalid credentials. Please try again.");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomInput(controller: emailCtrl, label: "Email or Username"),
            const SizedBox(height: 20),
            CustomInput(
              controller: passCtrl,
              label: "Password",
              obscure: obscure,
              onSubmitted: _login,
              suffixIcon: IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => obscure = !obscure),
              ),
            ),
            // ✅ ปุ่ม "Forgot password?"
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push('/forgot'),
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    color: Color.fromARGB(255, 150, 150, 150),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            CustomButton(
              text: "Log In",
              loading: loading,
              onPressed: _login,
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
          ],
        ),
      ),
    );
  }
}