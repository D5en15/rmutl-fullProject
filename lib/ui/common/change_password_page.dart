import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  // THEME TOKENS
  static const _primary  = Color(0xFF3D5CFF);
  static const _headerBg = Color(0xFFF2F3F7);
  static const _border   = Color(0xFFE1E5F2);

  final _formKey  = GlobalKey<FormState>();
  final _oldCtrl  = TextEditingController();
  final _newCtrl  = TextEditingController();
  final _confCtrl = TextEditingController();

  // focus: next/submit ง่ายขึ้น
  final _oldNode  = FocusNode();
  final _newNode  = FocusNode();
  final _confNode = FocusNode();

  bool _showOld  = false;
  bool _showNew  = false;
  bool _showConf = false;

  bool _loading = false;

  @override
  void dispose() {
    _oldCtrl.dispose();
    _newCtrl.dispose();
    _confCtrl.dispose();
    _oldNode.dispose();
    _newNode.dispose();
    _confNode.dispose();
    super.dispose();
  }

  // ---- Validators -----------------------------------------------------------
  static const int _minLen = 6;

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill out this field';
    if (v.length < _minLen) return 'Must be at least $_minLen characters';
    return null;
  }

  String? _confirmValidator(String? v) {
    final base = _required(v);
    if (base != null) return base;
    if (v != _newCtrl.text) return 'Password confirmation does not match';
    return null;
  }

  // ---- Submit ---------------------------------------------------------------
  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    // simulate calling service
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 900));
    setState(() => _loading = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Password changed successfully')),
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    const double headerHeight     = 160;
    const double formTopPadding   = 32;
    const double labelToFieldGap  = 8;
    const double fieldGroupGap    = 18;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              // ---------- Header สีเทา ----------
              Container(
                width: double.infinity,
                height: headerHeight,
                decoration: const BoxDecoration(
                  color: _headerBg,
                  border: Border(
                    bottom: BorderSide(color: _border, width: 1),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(8, 18, 16, 16),
                child: Align(
                  alignment: Alignment.bottomLeft,
                  child: Row(
                    // ✅ ใช้ const list ได้ เพราะ _BackBtn มี const constructor และ Text ก็เป็น const
                    children: const [
                      _BackBtn(),
                      SizedBox(width: 8),
                      Text(
                        'Change password',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ---------- ฟอร์ม ----------
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, formTopPadding, 16, 28),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _FieldLabel('old password'),
                        const SizedBox(height: labelToFieldGap),
                        TextFormField(
                          controller: _oldCtrl,
                          focusNode: _oldNode,
                          obscureText: !_showOld,
                          obscuringCharacter: '•',
                          validator: _required,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _newNode.requestFocus(),
                          inputFormatters: [LengthLimitingTextInputFormatter(64)],
                          autofillHints: const [AutofillHints.password],
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          decoration: _pwdDecoration(
                            isVisible: _showOld,
                            onToggle: () => setState(() => _showOld = !_showOld),
                          ),
                        ),
                        const SizedBox(height: fieldGroupGap),

                        const _FieldLabel('New password'),
                        const SizedBox(height: labelToFieldGap),
                        TextFormField(
                          controller: _newCtrl,
                          focusNode: _newNode,
                          obscureText: !_showNew,
                          obscuringCharacter: '•',
                          validator: _required,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) => _confNode.requestFocus(),
                          onChanged: (_) => _formKey.currentState?.validate(),
                          inputFormatters: [LengthLimitingTextInputFormatter(64)],
                          autofillHints: const [AutofillHints.newPassword],
                          scrollPadding: const EdgeInsets.only(bottom: 120),
                          decoration: _pwdDecoration(
                            isVisible: _showNew,
                            onToggle: () => setState(() => _showNew = !_showNew),
                          ),
                        ),
                        const SizedBox(height: fieldGroupGap),

                        const _FieldLabel('Confirm password'),
                        const SizedBox(height: labelToFieldGap),
                        TextFormField(
                          controller: _confCtrl,
                          focusNode: _confNode,
                          obscureText: !_showConf,
                          obscuringCharacter: '•',
                          validator: _confirmValidator,
                          enableSuggestions: false,
                          autocorrect: false,
                          keyboardType: TextInputType.text,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _submit(),
                          onChanged: (_) => _formKey.currentState?.validate(),
                          inputFormatters: [LengthLimitingTextInputFormatter(64)],
                          autofillHints: const [AutofillHints.newPassword],
                          scrollPadding: const EdgeInsets.only(bottom: 160),
                          decoration: _pwdDecoration(
                            isVisible: _showConf,
                            onToggle: () => setState(() => _showConf = !_showConf),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Submit
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: _primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white,
                                    ))
                                : const Text('Submit', style: TextStyle(fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Decorations ----------
  static InputDecoration _pwdDecoration({
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return InputDecoration(
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _primary, width: 1.5),
      ),
      suffixIconConstraints: const BoxConstraints(minHeight: 40, minWidth: 40),

      // true = แสดงรหัส -> ไอคอน "ตาเปิด"
      suffixIcon: IconButton(
        onPressed: onToggle,
        icon: Icon(
          isVisible ? Icons.visibility : Icons.visibility_off,
          color: Colors.black54,
        ),
        tooltip: isVisible ? 'Hide password' : 'Show password',
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF707070),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ✅ เพิ่มคลาส _BackBtn (มี const constructor)
class _BackBtn extends StatelessWidget {
  const _BackBtn({super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.pop(),
      child: const Padding(
        padding: EdgeInsets.only(right: 4),
        child: Icon(Icons.arrow_back_ios_new_rounded, size: 22),
      ),
    );
  }
}
