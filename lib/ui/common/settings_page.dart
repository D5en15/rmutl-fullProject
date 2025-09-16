import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// ใช้ EditProfileInitial จากหน้า edit_profile_page.dart
import 'edit_profile_page.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  // THEME TOKENS (เฉพาะหน้านี้)
  static const _primary = Color(0xFF3D5CFF);
  static const _muted   = Color(0xFF858597);

  void _logout(BuildContext context) {
    // TODO: เคลียร์ state/session ที่ใช้งานจริงก่อน
    context.go('/login');
  }

  /// เดา role จากเส้นทางปัจจุบัน
  String _detectRole(BuildContext context) {
    final uri = GoRouterState.of(context).uri.toString();
    if (uri.startsWith('/teacher')) return 'teacher';
    if (uri.startsWith('/admin')) return 'admin';
    return 'student';
  }

  /// เส้นทาง base ของ role
  String _roleBasePath(String role) => switch (role) {
        'teacher' => '/teacher',
        'admin'   => '/admin',
        _         => '/student',
      };

  /// ค่าฟอร์มเริ่มต้นตาม role
  EditProfileInitial _buildInitial(String role) => switch (role) {
        'teacher' => const EditProfileInitial(
          name: 'Mr. A',
          email: 'a@rmutl.ac.th',
          phone: '09xxxxxxx',
          teacherId: 'T-0123',
        ),
        'admin' => const EditProfileInitial(
          name: 'Admin',
          email: 'admin@rmutl.ac.th',
          phone: '0xxxxxxxxx',
        ),
        _ => const EditProfileInitial(
          name: 'Smith',
          email: 'smith@example.com',
          phone: '08xxxxxxx',
          studentId: '66SE001',
          className: 'SE-3/1',
        ),
      };

  @override
  Widget build(BuildContext context) {
    final role    = _detectRole(context);
    final base    = _roleBasePath(role);
    final initial = _buildInitial(role);
    final cs      = Theme.of(context).colorScheme;

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
                    backgroundColor: _primary,
                    child: const CircleAvatar(
                      radius: 34,
                      // ถ้ามีรูปจริงให้เปลี่ยนเป็น NetworkImage/AssetImage
                      child: Icon(Icons.person, size: 34, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    initial.name ?? 'User',
                    style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  if ((initial.email ?? '').isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(initial.email!, style: const TextStyle(color: _muted)),
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
                extra: {'role': role, 'initial': initial},
              ),
            ),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.lock_reset_outlined,
              title: 'Change password',
              subtitle: 'Update your account password',
              onTap: () => context.push('/password/change'),
            ),
            const SizedBox(height: 10),
            _SettingTile(
              icon: Icons.notifications_outlined,
              title: 'Notifications',
              subtitle: 'View app notifications & messages',
              // ใช้ path ตาม role เพื่ออยู่ใน flow เดียวกัน (push เพื่อให้ back ได้)
              onTap: () => context.push('$base/notifications'),
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
                          style: const TextStyle(
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
