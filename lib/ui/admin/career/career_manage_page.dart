// lib/ui/admin/career_manage_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerManagePage extends StatefulWidget {
  const CareerManagePage({super.key});

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);

  @override
  State<CareerManagePage> createState() => _CareerManagePageState();
}

class _CareerManagePageState extends State<CareerManagePage> {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
        title: const Text('Career Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: CareerManagePage._primary,
        onPressed: () => context.go('/admin/config/careers/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // 🔍 Search box
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'ค้นหาอาชีพ...',
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

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('career')
                  .orderBy('career_id')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("ยังไม่มีอาชีพ"));
                }

                final query = _searchCtrl.text.toLowerCase();
                final docs = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final th = (data['career_thname'] ?? '').toString().toLowerCase();
                  final en = (data['career_enname'] ?? '').toString().toLowerCase();
                  return th.contains(query) || en.contains(query);
                }).toList();

                if (docs.isEmpty) {
                  return const Center(child: Text("ไม่พบอาชีพที่ค้นหา"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;
                    final nameTh = data['career_thname'] ?? '';
                    final nameEn = data['career_enname'] ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CareerManagePage._border),
                        boxShadow: const [
                          BoxShadow(
                              color: CareerManagePage._shadow,
                              blurRadius: 12,
                              offset: Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: CareerManagePage._soft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.work_outline,
                              color: CareerManagePage._primary, size: 26),
                        ),
                        title: Text(
                          nameTh,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          nameEn,
                          style: const TextStyle(color: CareerManagePage._muted),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              context.go('/admin/config/careers/$id/edit'),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}