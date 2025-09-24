// lib/ui/admin/dashboard_config_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardConfigPage extends StatelessWidget {
  const DashboardConfigPage({super.key});

  // Theme token
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);

  Future<int> _countDocs(String collection) async {
    final snap =
        await FirebaseFirestore.instance.collection(collection).get();
    return snap.docs.length;
  }

  Widget _tile({
    required IconData icon,
    required String title,
    required int count,
    required String subtitle,
    required VoidCallback onManage,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _soft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: _primary, size: 26),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Text(
          "$count $subtitle",
          style: const TextStyle(color: _muted),
        ),
        trailing: ElevatedButton(
          onPressed: onManage,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text('manage'),
        ),
      ),
    );
  }

  Widget _warn(String text) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: _border),
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 3)),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Colors.black87),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false, // ❌ ไม่มีปุ่มย้อนกลับ
        title: const Text('Config'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: FutureBuilder(
          future: Future.wait([
            _countDocs('subjects'),
            _countDocs('skills'),
            _countDocs('careers'),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("No data"));
            }

            final counts = snapshot.data as List<int>;
            final subjectsCount = counts[0];
            final skillsCount = counts[1];
            final careersCount = counts[2];

            return SingleChildScrollView(
              child: Column(
                children: [
                  _tile(
                    icon: Icons.menu_book_outlined,
                    title: 'Subjects',
                    count: subjectsCount,
                    subtitle: 'subjects',
                    onManage: () => context.go('/admin/config/subjects'),
                  ),
                  _tile(
                    icon: Icons.auto_graph_outlined,
                    title: 'Skills',
                    count: skillsCount,
                    subtitle: 'skills',
                    onManage: () => context.go('/admin/config/skills'),
                  ),
                  _tile(
                    icon: Icons.work_outline,
                    title: 'Careers',
                    count: careersCount,
                    subtitle: 'careers',
                    onManage: () => context.go('/admin/config/careers'),
                  ),
                  const SizedBox(height: 8),
                  // ✅ ตัวอย่าง warn จริง (ปรับตาม logic ได้)
                  if (subjectsCount == 0)
                    _warn('ยังไม่มีวิชาในระบบ'),
                  if (skillsCount == 0)
                    _warn('ยังไม่มีทักษะในระบบ'),
                  if (careersCount == 0)
                    _warn('ยังไม่มีอาชีพในระบบ'),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}