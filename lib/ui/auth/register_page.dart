import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../services/register_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/otp_button.dart';
import '../../widgets/app_toast.dart'; // ✅ ระบบแจ้งเตือนแบบ Toast

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _service = RegisterService();
  final _form = GlobalKey<FormState>();

  final _studentId = TextEditingController();
  final _fullname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();

  bool _loading = false;
  bool _otpSent = false;
  bool _otpVerified = false;

  /// 🔹 ส่ง OTP
  Future<void> _getOtp() async {
    final email = _email.text.trim().toLowerCase();
    if (email.isEmpty) {
      AppToast.error(context, 'Please enter your email first.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.sendOtp(email);
      setState(() {
        _otpSent = true;
        _otpVerified = false;
      });
      AppToast.success(context, 'OTP has been sent to your email.');
    } catch (e) {
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🔹 ตรวจสอบ OTP
  Future<void> _verifyOtp() async {
    final email = _email.text.trim().toLowerCase();
    final code = _otp.text.trim();

    if (email.isEmpty) {
      AppToast.error(context, 'Please enter your email first.');
      return;
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      AppToast.info(context, 'Please enter a 6-digit OTP.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.verifyOtp(email, code);
      setState(() => _otpVerified = true);
      AppToast.success(context, 'OTP verified successfully.');
    } catch (e) {
      AppToast.error(context, e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  /// 🔹 สมัครสมาชิก
  Future<void> _register() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (!_otpVerified) {
      AppToast.info(context, 'Please verify your OTP first.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _service.register(
        studentId: _studentId.text.trim(),
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

  String? _requiredValidator(String? value, String message) {
    if (value == null || value.trim().isEmpty) return message;
    return null;
  }

  String? _passwordValidator(String? value) {
    final password = value ?? '';
    if (password.isEmpty) {
      return 'Password is required.';
    }
    final hasUpper = RegExp(r'[A-Z]').hasMatch(password);
    final hasLower = RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'[0-9]').hasMatch(password);
    if (password.length < 8 || !hasUpper || !hasLower || !hasDigit) {
      return 'Password must be at least 8 characters and contain upper, lower case letters and digits.';
    }
    return null;
  }

  String? _confirmPasswordValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password.';
    }
    if (value != _password.text) {
      return 'Passwords do not match.';
    }
    return null;
  }

  @override
  void dispose() {
    _studentId.dispose();
    _fullname.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    _otp.dispose();
    super.dispose();
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomInput(
                  controller: _studentId,
                  label: 'Student ID',
                  validator: (v) =>
                      _requiredValidator(v, 'Student ID is required.'),
                ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: _fullname,
                  label: 'Full name',
                  validator: (v) =>
                      _requiredValidator(v, 'Full name is required.'),
                ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: _email,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) =>
                      _requiredValidator(v, 'Email is required.'),
                ),
                const SizedBox(height: 16),

                /// 🔹 ช่อง OTP + ปุ่ม
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: CustomInput(
                        controller: _otp,
                        label: 'OTP (6 digits)',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      height: 48,
                      child: OtpButton(
                        text: _otpSent ? 'Verify' : 'Get OTP',
                        loading: _loading,
                        onPressed: _otpSent ? _verifyOtp : _getOtp,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                CustomInput(
                  controller: _password,
                  label: 'Password',
                  obscure: true,
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 16),
                CustomInput(
                  controller: _confirm,
                  label: 'Confirm Password',
                  obscure: true,
                  validator: _confirmPasswordValidator,
                ),
                const SizedBox(height: 20),

                /// 🔹 ปุ่มสมัครสมาชิก
                CustomButton(
                  text: 'Create Account',
                  loading: _loading,
                  onPressed: _register,
                ),

                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Already have an account? '),
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
      ),
    );
  }
}
