import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserAddPage extends StatefulWidget {
  const UserAddPage({super.key});

  @override
  State<UserAddPage> createState() => _UserAddPageState();
}

class _UserAddPageState extends State<UserAddPage> {
  static const _primary = Color(0xFF3D5CFF);
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String _role = "teacher"; // ค่า default
  bool _loading = false;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;
    final currentEmail = currentUser?.email;
    final currentToken = await currentUser?.getIdToken(true);

    try {
      // ✅ สร้าง user ใหม่
      final newUser = await auth.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _password.text.trim(),
      );

      // ✅ บันทึก Firestore
      await FirebaseFirestore.instance.collection("users").doc(newUser.user!.uid).set({
        "username": _username.text.trim(),
        "email": _email.text.trim(),
        "role": _role,
        "displayName": _username.text.trim(),
        "createdAt": FieldValue.serverTimestamp(),
      });

      // ✅ กลับมา login เป็น admin เดิม
      if (currentEmail != null && currentToken != null) {
        // ต้องเก็บรหัสผ่าน admin ไว้ด้วย (ตรงนี้ต้อง hardcode / input เอง)
        await auth.signInWithEmailAndPassword(
          email: currentEmail,
          password: "ADMIN_PASSWORD_HERE", // 👈 ต้องใส่รหัสจริงของ admin
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("เพิ่มผู้ใช้สำเร็จ และกลับมาเป็น admin แล้ว")),
        );
        Navigator.pop(context);
      }
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("เพิ่มผู้ใช้งาน")),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(labelText: "Username"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "กรุณากรอก Username" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  decoration: const InputDecoration(labelText: "Email"),
                  validator: (v) =>
                      v == null || v.isEmpty ? "กรุณากรอก Email" : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _password,
                  decoration: const InputDecoration(labelText: "Password"),
                  obscureText: true,
                  validator: (v) =>
                      v == null || v.length < 6 ? "รหัสผ่าน ≥ 6 ตัว" : null,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: const [
                    DropdownMenuItem(value: "teacher", child: Text("Teacher")),
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? "teacher"),
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
                        : const Text("เพิ่มผู้ใช้"),
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