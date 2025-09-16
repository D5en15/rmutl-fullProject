// lib/ui/common/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditProfileInitial {
  final String? name;
  final String? email;
  final String? phone;
  final String? studentId;
  final String? className;
  final String? teacherId;
  const EditProfileInitial({
    this.name,
    this.email,
    this.phone,
    this.studentId,
    this.className,
    this.teacherId,
  });
}

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.role,          // 'student' | 'teacher' | 'admin'
    this.initial,
    this.onSubmit,               // hook ต่อ service ภายนอกได้
  });

  final String role;
  final EditProfileInitial? initial;
  final Future<void> Function(Map<String, dynamic> data)? onSubmit;

  // THEME TOKENS
  static const _primary = Color(0xFF3D5CFF);
  static const _label   = Color(0xFF8C8FA1);
  static const _border  = Color(0xFFE5E7F0);

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  // Header + Avatar
  static const double _headerH  = 200;   // ความสูงแถบสีน้ำเงิน
  static const double _avatarR  = 44;    // รัศมีรูปโปรไฟล์

  final _formKey = GlobalKey<FormState>();

  // controllers
  late final TextEditingController _name    = TextEditingController(text: widget.initial?.name ?? '');
  late final TextEditingController _email   = TextEditingController(text: widget.initial?.email ?? '');
  late final TextEditingController _phone   = TextEditingController(text: widget.initial?.phone ?? '');
  late final TextEditingController _stuId   = TextEditingController(text: widget.initial?.studentId ?? '');
  late final TextEditingController _teaId   = TextEditingController(text: widget.initial?.teacherId ?? '');
  String? _classValue;

  @override
  void initState() {
    super.initState();
    _classValue = widget.initial?.className;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _stuId.dispose();
    _teaId.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'กรุณากรอกข้อมูล';
    return null;
  }

  InputDecoration _decoration(String hint) => InputDecoration(
        hintText: hint,
        isDense: true,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EditProfilePage._border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EditProfilePage._border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: EditProfilePage._primary, width: 1.5),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontSize: 12.5, color: EditProfilePage._label, fontWeight: FontWeight.w600),
        ),
      );

  Future<void> _submit() async {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;

    final payload = <String, dynamic>{
      'role'      : widget.role,
      'name'      : _name.text.trim(),
      'email'     : _email.text.trim(),
      'phone'     : _phone.text.trim(),
      'studentId' : _stuId.text.trim().isEmpty ? null : _stuId.text.trim(),
      'teacherId' : _teaId.text.trim().isEmpty ? null : _teaId.text.trim(),
      'className' : _classValue,
    };

    if (widget.onSubmit != null) {
      await widget.onSubmit!(payload);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role == 'student';
    final isTeacher = widget.role == 'teacher';
    // admin = อื่นๆ

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // ---------- โครงหลัก ----------
            Column(
              children: [
                // Header สีน้ำเงิน + ปุ่ม back
                Container(
                  height: _headerH,
                  width: double.infinity,
                  color: EditProfilePage._primary,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                ),

                // เนื้อหา: เผื่อพื้นที่ให้ avatar ลอย (ระยะ = avatarR + margin)
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, _avatarR + 24, 16, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Name'),
                          TextFormField(controller: _name, validator: _required, decoration: _decoration('Name')),
                          const SizedBox(height: 14),

                          _label('Email'),
                          TextFormField(
                            controller: _email,
                            validator: _required,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _decoration('Email'),
                          ),
                          const SizedBox(height: 14),

                          _label('Phone number'),
                          TextFormField(
                            controller: _phone,
                            validator: _required,
                            keyboardType: TextInputType.phone,
                            decoration: _decoration('Phone number'),
                          ),
                          const SizedBox(height: 14),

                          if (isStudent) ...[
                            _label('Student ID'),
                            TextFormField(controller: _stuId, validator: _required, decoration: _decoration('Student ID')),
                            const SizedBox(height: 14),

                            _label('Class'),
                            DropdownButtonFormField<String>(
                              value: _classValue,
                              decoration: _decoration('Class'),
                              items: const [
                                DropdownMenuItem(value: 'SE-3/1', child: Text('SE-3/1')),
                                DropdownMenuItem(value: 'SE-3/2', child: Text('SE-3/2')),
                                DropdownMenuItem(value: 'SE-4/1', child: Text('SE-4/1')),
                              ],
                              onChanged: (v) => setState(() => _classValue = v),
                              validator: (v) => (v == null || v.isEmpty) ? 'กรุณาเลือกชั้นเรียน' : null,
                            ),
                            const SizedBox(height: 18),
                          ],

                          if (isTeacher) ...[
                            _label('Teacher ID'),
                            TextFormField(controller: _teaId, validator: _required, decoration: _decoration('Teacher ID')),
                            const SizedBox(height: 18),
                          ],

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: EditProfilePage._primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: _submit,
                              child: const Text('Submit', style: TextStyle(fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ---------- Avatar (ลอยซ้อนกึ่งกลาง) ----------
            Positioned(
              top: _headerH - _avatarR,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  width: (_avatarR * 2) + 12,
                  height: (_avatarR * 2) + 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(.08),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: CircleAvatar(
                    radius: _avatarR,
                    backgroundColor: const Color(0xFFE9ECFF),
                    child: const Icon(Icons.person, size: 34, color: Color(0xFF4B5563)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
