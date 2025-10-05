import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/register_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_button.dart';
import '../../widgets/app_toast.dart'; // ✅ นำเข้าระบบแจ้งเตือนใหม่

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _service = RegisterService();
  final _form = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _fullname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();

  bool _loading = false;
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _agree = false;

  Future<void> _getOtp() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) return AppToast.error(context, 'Please enter your email first.');
    setState(() => _loading = true);
    try {
      await _service.sendOtp(email);
      _otpSent = true;
      AppToast.success(context, 'OTP has been sent to your email.');
    } catch (e) {
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final email = _email.text.trim().toLowerCase();
    final code = _otp.text.trim();
    if (code.length != 6) return AppToast.info(context, 'Please enter a 6-digit OTP.');
    setState(() => _loading = true);
    try {
      await _service.verifyOtp(email, code);
      _otpVerified = true;
      AppToast.success(context, 'OTP verified successfully.');
    } catch (e) {
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _register() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_agree) return AppToast.info(context, 'Please accept terms & conditions.');
    if (!_otpVerified) return AppToast.info(context, 'Please verify your OTP first.');

    setState(() => _loading = true);
    try {
      await _service.register(
        username: _username.text.trim(),
        fullname: _fullname.text.trim(),
        email: _email.text.trim().toLowerCase(),
        password: _password.text,
      );
      AppToast.success(context, 'Account created successfully.');
      if (mounted) context.go('/login');
    } catch (e) {
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
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
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomInput(controller: _username, label: "Username"),
              const SizedBox(height: 16),
              CustomInput(controller: _fullname, label: "Full name"),
              const SizedBox(height: 16),
              CustomInput(controller: _email, label: "Email"),
              const SizedBox(height: 16),

              // ✅ ปรับปุ่ม OTP ให้อยู่ระดับเดียวกับช่องกรอก
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: CustomInput(
                      controller: _otp,
                      label: "OTP (6 digits)",
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: OtpButton(
                      text: _otpSent ? "Verify" : "Get OTP",
                      loading: _loading,
                      onPressed: _otpSent ? _verifyOtp : _getOtp,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              CustomInput(controller: _password, label: "Password", obscure: true),
              const SizedBox(height: 16),
              CustomInput(
                controller: _confirm,
                label: "Confirm Password",
                obscure: true,
                validator: (v) => v != _password.text ? "Passwords do not match" : null,
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
                      "By creating an account you agree to our Terms & Conditions.",
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: "Create Account",
                loading: _loading,
                onPressed: _register,
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Already have an account? "),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF3D5CFF),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Log in',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}