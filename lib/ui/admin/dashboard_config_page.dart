import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DashboardConfigPage extends StatelessWidget {
  const DashboardConfigPage({super.key});

  // Theme token
  static const _primary = Color(0xFF3D5CFF);
  static const _muted   = Color(0xFF858597);
  static const _soft    = Color(0xFFF6F7FF);
  static const _border  = Color(0xFFEFF1F7);
  static const _shadow  = Color(0x0D000000);

  @override
  Widget build(BuildContext context) {
    Widget tile({
      required IconData icon,
      required String title,
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
          subtitle: Text(subtitle, style: const TextStyle(color: _muted)),
          trailing: ElevatedButton(
            onPressed: onManage,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: const Text('manage'),
          ),
        ),
      );
    }

    Widget warn(String text) => Container(
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

    return Scaffold(
      backgroundColor: Colors.white, // ✅ พื้นหลังทั้งหน้าขาว
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
        child: SingleChildScrollView(
          child: Column(
            children: [
              tile(
                icon: Icons.menu_book_outlined,
                title: 'Subjects',
                subtitle: '19 subjects',
                onManage: () => context.go('/admin/config/subjects'),
              ),
              tile(
                icon: Icons.auto_graph_outlined,
                title: 'Skills',
                subtitle: '10 skills',
                onManage: () => context.go('/admin/config/skills'),
              ),
              tile(
                icon: Icons.work_outline,
                title: 'Careers',
                subtitle: '5 careers',
                onManage: () => context.go('/admin/config/careers'),
              ),
              const SizedBox(height: 8),
              warn('1 subject is not assigned to a skill'),
              warn('1 skill is not used in any subject'),
            ],
          ),
        ),
      ),
    );
  }
}
