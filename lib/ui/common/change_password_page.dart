import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../widgets/custom_button.dart';
import '../../widgets/custom_input.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _submitting = false;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    setState(() => _submitting = true);
    try {
      // Mock change password flow
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted) return;
      context.pop(true);
    } finally {
      if (mounted) setState(() => _submitting = false);
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
                'Change Password',
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
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomInput(
                controller: _currentCtrl,
                label: "Current Password",
                obscure: _obscureCurrent,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Please enter your current password" : null,
                onSubmitted: _submit,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureCurrent ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureCurrent = !_obscureCurrent),
                ),
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: _newCtrl,
                label: "New Password",
                obscure: _obscureNew,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Please enter a new password";
                  }
                  if (v.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
                onSubmitted: _submit,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 20),
              CustomInput(
                controller: _confirmCtrl,
                label: "Confirm Password",
                obscure: _obscureConfirm,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return "Please confirm your new password";
                  }
                  if (v != _newCtrl.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
                onSubmitted: _submit,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              const SizedBox(height: 30),
              CustomButton(
                text: "Change Password",
                loading: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
