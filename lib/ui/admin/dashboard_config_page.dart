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
    try {
      final snap = await FirebaseFirestore.instance.collection(collection).get();
      return snap.docs.length;
    } catch (e) {
      debugPrint("⚠️ Error loading $collection: $e");
      return 0;
    }
  }
  Future<Map<String, int>> _countSubjectMappings() async {
    try {
      final snap = await FirebaseFirestore.instance.collection("subject").get();
      final total = snap.docs.length;
      final mapped = snap.docs
          .where((doc) => (doc.data()["subplo_id"] ?? "").toString().isNotEmpty)
          .length;
      return {"mapped": mapped, "total": total};
    } catch (e) {
      debugPrint("⚠️ Error loading subject mapping: $e");
      return {"mapped": 0, "total": 0};
    }
  }
  Future<Map<String, int>> _countPloMappings() async {
    try {
      final snap = await FirebaseFirestore.instance.collection("plo").get();
      final total = snap.docs.length;
      final mapped = snap.docs
          .where((doc) => (doc.data()["subplo_id"] ?? "").toString().isNotEmpty)
          .length;
      return {"mapped": mapped, "total": total};
    } catch (e) {
      debugPrint("⚠️ Error loading plo mapping: $e");
      return {"mapped": 0, "total": 0};
    }
  }
  Widget _tile({
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
        subtitle: Text(
          subtitle,
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          ),
          child: const Text('manage'),
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            _countDocs('subject'),
            _countDocs('subplo'),
            _countDocs('plo'),
            _countDocs('career'),
            _countDocs('career_mapping'),
            _countSubjectMappings(),
            _countPloMappings(),
          ]),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData) {
              return const Center(child: Text("No data"));
            }
            final results = snapshot.data as List<dynamic>;
            final subjectsCount = results[0] as int;
            final subploCount = results[1] as int;
            final ploCount = results[2] as int;
            final careersCount = results[3] as int;
            final mappingCount = results[4] as int;
                        final subjectMapping = results[5] as Map<String, int>;
            final ploMapping = results[6] as Map<String, int>;
            final subjectMapped = subjectMapping["mapped"]!;
            final subjectTotal = subjectMapping["total"]!;
            final ploMapped = ploMapping["mapped"]!;
            final ploTotal = ploMapping["total"]!;
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("📘 Academic",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  _tile(
                    icon: Icons.menu_book_outlined,
                    title: 'Subjects',
                    subtitle: "$subjectsCount subjects",
                    onManage: () => context.go('/admin/config/subjects'),
                  ),
                  _tile(
                    icon: Icons.extension_outlined,
                    title: 'SubPLO',
                    subtitle: "$subploCount sub skills",
                    onManage: () => context.go('/admin/config/subplo'),
                  ),
                  _tile(
                    icon: Icons.layers_outlined,
                    title: 'PLO',
                    subtitle: "$ploCount main skills",
                    onManage: () => context.go('/admin/config/plo'),
                  ),
                  _tile(
                    icon: Icons.school_outlined,
                    title: 'Subject ↔ SubPLO',
                    subtitle: "Manage subject-subplo mapping",
                    onManage: () =>
                        context.go('/admin/config/subject-subplo-mapping'),
                  ),
                  _tile(
                    icon: Icons.account_tree_outlined,
                    title: 'PLO ↔ SubPLO',
                    subtitle: "Manage plo-subplo mapping",
                    onManage: () =>
                        context.go('/admin/config/plo-subplo-mapping'),
                  ),
                  const SizedBox(height: 16),
                  const Text("👨‍💻 Careers",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 6),
                  _tile(
                    icon: Icons.work_outline,
                    title: 'Careers',
                    subtitle: "$careersCount careers",
                    onManage: () => context.go('/admin/config/careers'),
                  ),
                  _tile(
                    icon: Icons.share_outlined,
                    title: 'Career Mapping',
                    subtitle: "Manage career mapping",
                    onManage: () => context.go('/admin/config/mappings'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

