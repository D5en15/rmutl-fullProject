import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? _name;        // ← user_fullname
  String? _email;       // ← user_email (fallback: FirebaseAuth.email)
  String? _role;        // ← user_role
  String? _username;    // ← user_name
  String? _className;   // ← user_class
  String? _userId;      // ← user_id (int -> string)
  String? _avatarUrl;   // ← user_img (อาจเป็น URL หรือ asset path)
  ImageProvider? _avatarImage;

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      setState(() => _loading = true);

      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) {
        if (!mounted) return;
        setState(() => _loading = false);
        return;
      }

      final authEmail = authUser.email;
      if (authEmail == null || authEmail.isEmpty) {
        if (!mounted) return;
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบอีเมลของผู้ใช้จาก FirebaseAuth')),
        );
        return;
      }

      // 🔎 สคีมาใหม่: ใช้คอลเลกชัน 'user' และค้นหาด้วย user_email
      final query = await FirebaseFirestore.instance
          .collection('user')
          .where('user_email', isEqualTo: authEmail)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        if (!mounted) return;
        setState(() {
          _email = authEmail; // แสดงอย่างน้อยอีเมลจาก Auth
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ไม่พบข้อมูลผู้ใช้ในฐานข้อมูลใหม่')),
        );
        return;
      }

      final data = query.docs.first.data();

      final fullname  = data['user_fullname'] as String?;
      final username  = data['user_name'] as String?;
      final email     = data['user_email'] as String?;
      final role      = data['user_role'] as String?;
      final className = data['user_class'] as String?;
      final userId    = data['user_id']?.toString(); // int → string
      final img       = data['user_img'] as String?;

      ImageProvider? avatarProvider;
      if (img != null && img.trim().isNotEmpty) {
        final v = img.trim();
        if (v.startsWith('http://') || v.startsWith('https://')) {
          avatarProvider = NetworkImage(v);
        } else if (v.startsWith('assets/')) {
          avatarProvider = AssetImage(v);
        } else {
          // เก็บเป็น key สั้น ๆ → ชี้ไปโฟลเดอร์ assets/avatars/
          avatarProvider = AssetImage('assets/avatars/$v');
        }
      }

      if (!mounted) return;
      setState(() {
        _name = fullname ?? 'User';
        _username = username;
        _email = email ?? authEmail;
        _role = role;
        _className = className;
        _userId = userId;
        _avatarUrl = img;
        _avatarImage = avatarProvider;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดข้อมูลบัญชีไม่สำเร็จ: $e')),
      );
    }
  }

  void _logout(BuildContext context) {
    FirebaseAuth.instance.signOut();
    context.go('/login');
  }

  void _showResetDialog(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email;
    if (email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ไม่พบอีเมลผู้ใช้")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "ยืนยันการเปลี่ยนรหัสผ่าน",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                "คุณต้องการส่งลิงก์เปลี่ยนรหัสผ่านไปยัง\n$email ใช่หรือไม่?",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SettingsPage._primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    try {
                      await FirebaseAuth.instance
                          .sendPasswordResetEmail(email: email);
                      if (mounted) {
                        Navigator.pop(ctx); // ปิด dialog
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text("📩 ลิงก์เปลี่ยนรหัสผ่านถูกส่งไปที่ $email"),
                          ),
                        );
                      }
                    } on FirebaseAuthException catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error: ${e.message}")),
                      );
                    }
                  },
                  child: const Text(
                    "ส่งลิงก์ไปยังอีเมล",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  // ---------- Header ----------
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: SettingsPage._primary,
                          backgroundImage: _avatarImage,
                          child: _avatarImage == null
                              ? const Icon(Icons.person,
                                  size: 40, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _name ?? 'User',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800),
                        ),
                        if ((_username ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_username!,
                              style: TextStyle(color: SettingsPage._muted)),
                        ],
                        if ((_email ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(_email!,
                              style: TextStyle(color: SettingsPage._muted)),
                        ],
                        if ((_role ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _role!,
                            style: TextStyle(
                              color: cs.primary.withOpacity(0.7),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                        if ((_className ?? '').isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            _className!,
                            style: TextStyle(color: SettingsPage._muted),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ---------- Tiles ----------
                  _SettingTile(
                    icon: Icons.edit_outlined,
                    title: 'Edit Account',
                    subtitle: 'Update your personal information',
                    onTap: () => context.push(
                      '/profile/edit',
                      extra: {
                        // ส่งข้อมูลตรงจาก DB ใหม่
                        'role': _role ?? 'Student',
                        'initial': EditProfileInitial(
                          username: _username,
                          name: _name,
                          email: _email,
                          studentId: _userId,    // ใช้ user_id เป็นรหัสภายใน
                          className: _className, // user_class
                          avatar: _avatarUrl,    // raw (URL/asset) ให้หน้า edit ตัดสินใจต่อ
                        ),
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  _SettingTile(
                    icon: Icons.lock_reset_outlined,
                    title: 'Change password',
                    subtitle: 'Send reset link to your email',
                    onTap: () => _showResetDialog(context),
                  ),

                  const SizedBox(height: 24),

                  // ---------- Logout ----------
                  FilledButton.icon(
                    onPressed: () => _logout(context),
                    style: FilledButton.styleFrom(
                      backgroundColor: cs.error,
                      foregroundColor: cs.onError,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.logout),
                    label:
                        const Text('Logout', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: SettingsPage._primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    if (subtitle != null) ...[
                      const SizedBox(height: 3),
                      Text(subtitle!,
                          style: TextStyle(
                              color: SettingsPage._muted, fontSize: 12.5)),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
