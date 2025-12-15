import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ---------- Design tokens ----------
class _T {
  static const primary = Color(0xFF3D5CFF);
  static const muted = Color(0xFF858597);
  static const cardBorder = Color(0xFFEFF1F7);
  static const soft = Color(0xFFF6F7FF);
  static const shadow = Color(0x0D000000);
}

class TeacherHomePage extends StatefulWidget {
  const TeacherHomePage({super.key});
  @override
  State<TeacherHomePage> createState() => _TeacherHomePageState();
}

class _TeacherHomePageState extends State<TeacherHomePage> {
  int _total = 0;
  int _students = 0;
  int _teachers = 0;
  int _admins = 0;
  String? _avatarUrl;

  String? _selectedYear;
  List<String> _years = [];

  @override
  void initState() {
    super.initState();
    _loadCounts();
    _loadYears();
  }

  Future<void> _loadCounts() async {
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

  Future<void> _loadYears() async {
    final snap = await FirebaseFirestore.instance.collection('user').get();

    final set = <String>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final role = (data['user_role'] ?? '').toString().toLowerCase();
      if (role != 'student') continue;

      final uid = (data['user_id'] ?? '').toString();
      if (uid.length >= 2) {
        set.add(uid.substring(0, 2));
      }
    }
    final sorted = set.toList()..sort();
    setState(() {
      _years = sorted;
      if (_selectedYear != null && !_years.contains(_selectedYear)) {
        _selectedYear = null;
      }
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
                roleLabel: 'Teacher',
                subtitle:
                    'Monitor student performance and guide their growth.',
                photoUrl: _avatarUrl,
                onProfileTap: () => context.push(
                  '/profile/edit',
                  extra: const {'role': 'teacher'},
                ),
              ),
              _Body(
                total: _total,
                students: _students,
                teachers: _teachers,
                admins: _admins,
                years: _years,
                selectedYear: _selectedYear,
                onYearChanged: (v) => setState(() => _selectedYear = v),
              ),
            ],
          ),
        ),
      ),
    );
  }
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
      height: 188,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: const BoxDecoration(color: _T.primary),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () =>
                    context.go('/teacher/messages?tab=notifications'),
                child: const Padding(
                  padding: EdgeInsets.all(6),
                  child: Icon(Icons.notifications_none_rounded,
                      color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      roleLabel,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onProfileTap,
                child: Builder(builder: (context) {
                  final trimmed = photoUrl?.trim() ?? '';
                  final hasPhoto = trimmed.isNotEmpty;
                  return CircleAvatar(
                    radius: 22,
                    backgroundColor: Colors.white,
                    backgroundImage: hasPhoto ? NetworkImage(trimmed) : null,
                    child: hasPhoto
                        ? null
                        : const Icon(Icons.person,
                            color: Colors.black54, size: 22),
                  );
                }),
              ),
            ],
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
    required this.years,
    required this.selectedYear,
    required this.onYearChanged,
  });

  final int total, students, teachers, admins;
  final List<String> years;
  final String? selectedYear;
  final ValueChanged<String?> onYearChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top stats 2x2
          Row(
            children: [
              Expanded(
                child: _InfoCard(
                    icon: Icons.groups_2_outlined,
                    value: '$total',
                    label: 'Total users'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                    icon: Icons.person_outline,
                    value: '$students',
                    label: 'Students'),
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
                    label: 'Teachers'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _InfoCard(
                    icon: Icons.admin_panel_settings_outlined,
                    value: '$admins',
                    label: 'Admins'),
              ),
            ],
          ),
          const SizedBox(height: 18),

          const Text('Select student tracker',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),

          // ✅ Dropdown: เลือกชั้นปีจากรหัสนักศึกษา (2 ตัวแรก)
          Container(
            decoration: BoxDecoration(
              color: _T.soft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.cardBorder),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedYear,
                hint: const Text('-'),
                dropdownColor: _T.soft,
                icon: const Icon(Icons.keyboard_arrow_down_rounded),
                isExpanded: true,
                items: years
                    .map((y) => DropdownMenuItem(
                        value: y, child: Text('Year $y')))
                    .toList(),
                onChanged: (v) {
                  onYearChanged(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ ปุ่มดูนักเรียนเฉพาะห้อง
          SizedBox(
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                if (selectedYear == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text("Please select a student year first")),
                  );
                  return;
                }
                context.push('/teacher/students',
                    extra: {'year': selectedYear});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _T.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Go to Student List'),
            ),
          ),

          const SizedBox(height: 12),

          // ✅ ปุ่มดูนักศึกษาทั้งหมด
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/teacher/students',
                  extra: const {'year': null, 'all': true}),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: _T.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.people_outline, color: _T.primary),
              label: const Text(
                "View All Students",
                style: TextStyle(color: _T.primary, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.value,
    required this.label,
  });

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
          BoxShadow(color: _T.shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _T.soft,
              borderRadius: BorderRadius.circular(10),
            ),
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
