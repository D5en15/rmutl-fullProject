// lib/ui/admin/user_add_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserAddPage extends StatefulWidget {
  const UserAddPage({super.key});

  @override
  State<UserAddPage> createState() => _UserAddPageState();
}

class _UserAddPageState extends State<UserAddPage> {
  static const _primary = Color(0xFF3D5CFF);
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _fullname = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _className = TextEditingController();
  final _userCode = TextEditingController();
  String _role = "Student";
  bool _loading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final userRef = FirebaseFirestore.instance.collection('user');

      // ✅ หา user_id ล่าสุด แล้ว +1
      final last = await userRef.orderBy('user_id', descending: true).limit(1).get();
      int nextId = 1;
      if (last.docs.isNotEmpty) {
        final lastId = int.tryParse(last.docs.first['user_id'].toString());
        nextId = (lastId ?? 0) + 1;
      }
      final newUserId = nextId.toString().padLeft(5, '0');

      // ✅ เพิ่มข้อมูลผู้ใช้ใหม่
      await userRef.add({
        'user_id': newUserId,
        'user_code': _userCode.text.trim(),
        'user_name': _username.text.trim(),
        'user_fullname': _fullname.text.trim(),
        'user_email': _email.text.trim(),
        'user_password': _password.text.trim(),
        'user_role': _role,
        'user_class': _className.text.trim(),
        'user_img': 'https://example.com/default-avatar.png', // ตั้งค่าเริ่มต้น
        'created_at': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ เพิ่มผู้ใช้งานสำเร็จ")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("เกิดข้อผิดพลาด: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _fullname.dispose();
    _email.dispose();
    _password.dispose();
    _className.dispose();
    _userCode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("เพิ่มผู้ใช้งานใหม่"),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _userCode,
                  decoration: const InputDecoration(labelText: "รหัสผู้ใช้ (User Code)"),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: "ชื่อบัญชีผู้ใช้ (Username)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "กรุณากรอกชื่อบัญชี" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fullname,
                  decoration: const InputDecoration(labelText: "ชื่อ-นามสกุล"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "กรุณากรอกชื่อจริง" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: "อีเมล (Email)"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "กรุณากรอกอีเมล" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: "รหัสผ่าน (Password)"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? "รหัสผ่านต้อง ≥ 6 ตัวอักษร" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _className,
                  decoration: const InputDecoration(labelText: "ห้องเรียน (Class)"),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: "บทบาทผู้ใช้ (Role)"),
                  items: const [
                    DropdownMenuItem(value: "Student", child: Text("Student")),
                    DropdownMenuItem(value: "Teacher", child: Text("Teacher")),
                    DropdownMenuItem(value: "Admin", child: Text("Admin")),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? "Student"),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("เพิ่มผู้ใช้งาน"),
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