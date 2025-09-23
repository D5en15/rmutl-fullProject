// lib/ui/admin/subjects_manage_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectsManagePage extends StatefulWidget {
  const SubjectsManagePage({super.key});

  @override
  State<SubjectsManagePage> createState() => _SubjectsManagePageState();

  // design tokens
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);
}

class _SubjectsManagePageState extends State<SubjectsManagePage> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Subjects Management'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'), // ✅ กลับ Dashboard
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: SubjectsManagePage._primary,
        onPressed: () => context.go('/admin/config/subjects/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),

      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 🔍 ช่องค้นหา
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหารายวิชา...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),

            // 📜 รายการวิชา
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subjects')
                    .orderBy('code')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("ยังไม่มีรายวิชา"));
                  }

                  final query = _searchCtrl.text.toLowerCase();
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final code = (data['code'] ?? '').toString().toLowerCase();
                    final nameTh =
                        (data['name_th'] ?? '').toString().toLowerCase();
                    final nameEn =
                        (data['name_en'] ?? '').toString().toLowerCase();
                    return code.contains(query) ||
                        nameTh.contains(query) ||
                        nameEn.contains(query);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("ไม่พบรายวิชา"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title = "${data['code']} • ${data['name_en'] ?? ''}";
                      final subtitle =
                          "${data['name_th'] ?? ''} • ${data['credits'] ?? ''}";

                      return _SubjectTile(
                        title: title,
                        subtitle: subtitle,
                        icon: Icons.menu_book_outlined,
                        onTap: () =>
                            context.go('/admin/config/subjects/$id/edit'),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const _primary = SubjectsManagePage._primary;
  static const _soft = SubjectsManagePage._soft;
  static const _border = SubjectsManagePage._border;
  static const _shadow = SubjectsManagePage._shadow;
  static const _muted = SubjectsManagePage._muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: _shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap, // ✅ กดได้ทั้งแถว
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(color: _shadow, blurRadius: 12, offset: Offset(0, 4)),
            ],
            color: Colors.white,
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            leading: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _soft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _primary, size: 26),
            ),
            title: Text(title,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(subtitle, style: const TextStyle(color: _muted)),
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onTap, // ✅ ปุ่มดินสอก็ไปหน้าแก้ไขเหมือนกัน
            ),
          ),
        ),
      ),
    );
  }
}