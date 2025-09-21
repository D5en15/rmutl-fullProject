import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserEditFormPage extends StatefulWidget {
  const UserEditFormPage({
    super.key,
    required this.userId,
    required this.email,
  });
  final String userId;
  final String email;

  @override
  State<UserEditFormPage> createState() => _UserEditFormPageState();
}

class _UserEditFormPageState extends State<UserEditFormPage> {
  static const _primary = Color(0xFF3D5CFF);
  final _form = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();
  String? _classValue;
  String _role = 'student';
  String? _selectedAvatar;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _username.text = data['username'] ?? '';
          _name.text = data['displayName'] ?? '';
          _studentId.text = data['studentId'] ?? '';
          _classValue = data['className'];
          _role = data['role'] ?? 'student';
          _selectedAvatar = data['avatar'] ?? '1.png';
        });
      }
    } catch (e) {
      debugPrint("Error load user: $e");
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _email.dispose();
    _studentId.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label,
      {bool readOnly = false, Color? fillColor}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: fillColor ?? Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .update({
        'username': _username.text.trim(),
        'displayName': _name.text.trim(),
        'studentId': _studentId.text.trim(),
        'className': _classValue,
        'avatar': _selectedAvatar,
        'role': _role, // ✅ update role ด้วย
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('เกิดข้อผิดพลาด: $e')),
        );
      }
    }
  }

  void _pickAvatar() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('เลือก Avatar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 20,
            itemBuilder: (context, index) {
              final path = '${index + 1}.png';
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, path),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/avatars/$path'),
                  radius: 30,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (chosen != null) {
      setState(() => _selectedAvatar = chosen);
    }
  }

  // -------------------- DELETE USER (Firestore doc) --------------------
  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบผู้ใช้งาน'),
        content: const Text('ยืนยันการลบผู้ใช้งานคนนี้หรือไม่?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ยกเลิก')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('ลบ', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ลบผู้ใช้งานเรียบร้อย')),
      );
      context.pop(); // กลับไปหน้ารายชื่อ
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
    }
  }
  // ---------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    const double headerH = 180;
    const double avatarR = 44;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            Column(
              children: [
                // ✅ Blue header
                Container(
                  height: headerH,
                  width: double.infinity,
                  color: _primary,
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
                      // ✅ ปุ่มลบ (มุมขวาบน)
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.white),
                          onPressed: _confirmAndDelete,
                          tooltip: 'ลบผู้ใช้งาน',
                        ),
                      ),
                    ],
                  ),
                ),
                // ✅ Form body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, avatarR + 24, 16, 24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _username,
                            decoration: _decoration("Username"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _name,
                            decoration: _decoration("Name"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "Required" : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _email,
                            readOnly: true,
                            decoration: _decoration(
                              "Email",
                              readOnly: true,
                              fillColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (_role == 'student') ...[
                            TextFormField(
                              controller: _studentId,
                              decoration: _decoration("Student ID"),
                            ),
                            const SizedBox(height: 14),
                            DropdownButtonFormField<String>(
                              value: _classValue,
                              decoration: _decoration("Class"),
                              items: const [
                                DropdownMenuItem(
                                    value: 'SE-3/1', child: Text('SE-3/1')),
                                DropdownMenuItem(
                                    value: 'SE-3/2', child: Text('SE-3/2')),
                                DropdownMenuItem(
                                    value: 'SE-4/1', child: Text('SE-4/1')),
                              ],
                              onChanged: (v) =>
                                  setState(() => _classValue = v),
                            ),
                            const SizedBox(height: 14),
                          ],

                          // Role dropdown (admin เปลี่ยนได้)
                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: _decoration("Role"),
                            items: const [
                              DropdownMenuItem(
                                  value: 'student', child: Text('Student')),
                              DropdownMenuItem(
                                  value: 'teacher', child: Text('Teacher')),
                              DropdownMenuItem(
                                  value: 'admin', child: Text('Admin')),
                            ],
                            onChanged: (v) => setState(() => _role = v ?? _role),
                          ),
                          const SizedBox(height: 20),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _primary,
                                foregroundColor: Colors.white,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Submit"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ✅ Avatar + ปุ่มแก้ไข
            Positioned(
              top: headerH - avatarR,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarR,
                      backgroundImage: _selectedAvatar != null
                          ? AssetImage('assets/avatars/$_selectedAvatar')
                          : null,
                      backgroundColor: const Color(0xFFE9ECFF),
                      child: _selectedAvatar == null
                          ? const Icon(Icons.person,
                              size: 34, color: Color(0xFF4B5563))
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: InkWell(
                        onTap: _pickAvatar,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit,
                              size: 18, color: _primary),
                        ),
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}