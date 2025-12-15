import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminHomePage extends StatefulWidget {
  const AdminHomePage({super.key});

  @override
  State<AdminHomePage> createState() => _AdminHomePageState();
}

class _AdminHomePageState extends State<AdminHomePage> {
  int _total = 0;
  int _students = 0;
  int _teachers = 0;
  int _admins = 0;
  String? _avatarUrl;

  String _selectedRole = 'เลือกบทบาท'; // ค่า default

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    // ✅ ใช้ collection 'user' (ไม่มี s)
    final snap = await FirebaseFirestore.instance.collection('user').get();
    int students = 0, teachers = 0, admins = 0;
    String? avatarUrl;
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();

    for (var doc in snap.docs) {
      final data = doc.data();
      final role = (data['user_role'] ?? '').toString().toLowerCase();

      if (role == 'student') students++;
      if (role == 'teacher') teachers++;
      if (role == 'admin') admins++;

      final email = (data['user_email'] ?? '').toString().toLowerCase();
      if (currentEmail != null && email == currentEmail) {
        avatarUrl = (data['user_img'] as String?)?.trim();
      }
    }

    setState(() {
      _students = students;
      _teachers = teachers;
      _admins = admins;
      _total = students + teachers + admins;
      _avatarUrl = avatarUrl;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _BlueHeader(
                roleLabel: 'Administrator',
                subtitle:
                    'Configure the platform and keep every workflow aligned.',
                photoUrl: _avatarUrl,
                onProfileTap: () => context.push(
                  '/profile/edit',
                  extra: const {'role': 'admin'},
                ),
              ),
              _Body(
                total: _total,
                students: _students,
                teachers: _teachers,
                admins: _admins,
                selectedRole: _selectedRole,
                onRoleChanged: (role) {
                  setState(() => _selectedRole = role);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------- Design tokens ----------
class _T {
  static const primary = Color(0xFF3D5CFF);
  static const muted = Color(0xFF858597);
  static const cardBorder = Color(0xFFEFF1F7);
  static const soft = Color(0xFFF6F7FF);
  static const shadow = Color(0x0D000000);
}

/// ---------- BLUE HEADER ----------
class _BlueHeader extends StatelessWidget {
  const _BlueHeader({
    required this.roleLabel,
    required this.subtitle,
    required this.photoUrl,
    required this.onProfileTap,
  });
  final String roleLabel;
  final String subtitle;
  final String? photoUrl;
  final VoidCallback onProfileTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: _T.primary,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                roleLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .2,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => context.go('/admin/messages?tab=notifications'),
              borderRadius: BorderRadius.circular(24),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.notifications_none_rounded,
                    color: Colors.white, size: 26),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: InkWell(
              onTap: onProfileTap,
              borderRadius: BorderRadius.circular(24),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white,
                backgroundImage: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? NetworkImage(photoUrl!)
                    : null,
                child: (photoUrl == null || photoUrl!.isEmpty)
                    ? const Icon(Icons.person, color: Colors.black54, size: 20)
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------- BODY ----------
class _Body extends StatelessWidget {
  const _Body({
    required this.total,
    required this.students,
    required this.teachers,
    required this.admins,
    required this.selectedRole,
    required this.onRoleChanged,
  });

  final int total, students, teachers, admins;
  final String selectedRole;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.groups_2_outlined,
                  value: '$total',
                  label: 'Total users',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.person_outline,
                  value: '$students',
                  label: 'Students',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                  icon: Icons.school_outlined,
                  value: '$teachers',
                  label: 'Teachers',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                  icon: Icons.admin_panel_settings_outlined,
                  value: '$admins',
                  label: 'Admins',
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),
          const Text('Select role',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),

          // Dropdown
          Container(
            decoration: BoxDecoration(
              color: _T.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedRole,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                isExpanded: true,
                items: const [
                  'เลือกบทบาท',
                  'Student',
                  'Teacher',
                  'Admin',
                ]
                    .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onRoleChanged(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // CTA
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (selectedRole == 'เลือกบทบาท') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("กรุณาเลือกบทบาทก่อน")),
                  );
                  return;
                }

                String? roleKey;
                if (selectedRole == 'Student') roleKey = 'Student';
                else if (selectedRole == 'Teacher') roleKey = 'Teacher';
                else if (selectedRole == 'Admin') roleKey = 'Admin';

                context.push(
                  '/admin/users',
                  extra: {'filterRole': roleKey},
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go to User List'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard(
      {required this.icon, required this.value, required this.label});
  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 86,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _T.cardBorder),
        boxShadow: const [
          BoxShadow(color: _T.shadow, blurRadius: 12, offset: Offset(0, 4))
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: _T.soft, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: _T.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(label, style: const TextStyle(color: _T.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
