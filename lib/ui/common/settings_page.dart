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
  String? _name;
  String? _email;
  String? _role;
  String? _username;
  String? _avatar; // ✅ เก็บ path avatar

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return;

    setState(() {
      _name = data['displayName'];
      _email = data['email'];
      _role = data['role'];
      _username = data['username'];
      _avatar = data['avatar']; // ✅ ดึง avatar จาก Firestore
    });
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            // ---------- Header ----------
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: SettingsPage._primary,
                    backgroundImage: _avatar != null
                        ? AssetImage('assets/avatars/$_avatar')
                        : null,
                    child: _avatar == null
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
                    Text(_username!, style: TextStyle(color: SettingsPage._muted)),
                  ],
                  if ((_email ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(_email!, style: TextStyle(color: SettingsPage._muted)),
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
                  'role': 'student',
                  'initial': EditProfileInitial(
                    username: _username,
                    name: _name,
                    email: _email,
                    studentId: null,
                    className: null,
                    avatar: _avatar, // ✅ ส่ง avatar ไปด้วย
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
              label: const Text('Logout', style: TextStyle(fontSize: 16)),
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