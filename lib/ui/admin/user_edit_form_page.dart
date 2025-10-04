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

  final _userName = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _className = TextEditingController();
  String _role = 'Student';
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
          .collection('user')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userName.text = data['user_name'] ?? '';
          _fullName.text = data['user_fullname'] ?? '';
          _className.text = data['user_class'] ?? '';
          _role = data['user_role'] ?? 'Student';
          _selectedAvatar = data['user_img'] ?? '';
        });
      }
    } catch (e) {
      debugPrint("Error loading user: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("เกิดข้อผิดพลาดในการโหลดข้อมูล: $e")),
      );
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .update({
        'user_name': _userName.text.trim(),
        'user_fullname': _fullName.text.trim(),
        'user_class': _className.text.trim(),
        'user_role': _role,
        'user_img': _selectedAvatar ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกข้อมูลสำเร็จ ✅')),
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

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบผู้ใช้งาน'),
        content: const Text('คุณต้องการลบผู้ใช้งานคนนี้หรือไม่?'),
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
          .collection('user')
          .doc(widget.userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบผู้ใช้งานเรียบร้อย ✅')),
        );
        context.pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ลบไม่สำเร็จ: $e')),
      );
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
                // 🔹 Blue Header
                Container(
                  height: headerH,
                  width: double.infinity,
                  color: _primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Stack(
                    children: [
                      Align(
                        alignment: Alignment.topLeft,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => context.pop(),
                        ),
                      ),
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

                // 🔹 Form Body
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(16, avatarR + 24, 16, 24),
                    child: Form(
                      key: _form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _userName,
                            decoration: _decoration("ชื่อบัญชีผู้ใช้ (Username)"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "จำเป็นต้องกรอก" : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _fullName,
                            decoration: _decoration("ชื่อ-นามสกุล"),
                            validator: (v) =>
                                v == null || v.isEmpty ? "จำเป็นต้องกรอก" : null,
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _email,
                            readOnly: true,
                            decoration: _decoration(
                              "อีเมล (Email)",
                              readOnly: true,
                              fillColor: Colors.grey.shade200,
                            ),
                          ),
                          const SizedBox(height: 14),

                          TextFormField(
                            controller: _className,
                            decoration: _decoration("ห้องเรียน (Class)"),
                          ),
                          const SizedBox(height: 14),

                          DropdownButtonFormField<String>(
                            value: _role,
                            decoration: _decoration("บทบาทผู้ใช้ (Role)"),
                            items: const [
                              DropdownMenuItem(value: 'Student', child: Text('Student')),
                              DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                              DropdownMenuItem(value: 'Admin', child: Text('Admin')),
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
                              child: const Text("บันทึกข้อมูล"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 🔹 Avatar + ปุ่มเปลี่ยน
            Positioned(
              top: headerH - avatarR,
              left: 0,
              right: 0,
              child: Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: avatarR,
                      backgroundImage: _selectedAvatar != null &&
                              _selectedAvatar!.isNotEmpty
                          ? (_selectedAvatar!.startsWith('http')
                              ? NetworkImage(_selectedAvatar!)
                              : AssetImage('assets/avatars/$_selectedAvatar'))
                          : null as ImageProvider?,
                      backgroundColor: const Color(0xFFE9ECFF),
                      child: (_selectedAvatar == null ||
                              _selectedAvatar!.isEmpty)
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
                          child:
                              const Icon(Icons.edit, size: 18, color: _primary),
                        ),
                      ),
                    ),
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