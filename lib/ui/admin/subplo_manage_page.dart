// lib/ui/admin/subplo_manage_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubPLOManagePage extends StatefulWidget {
  const SubPLOManagePage({super.key});

  @override
  State<SubPLOManagePage> createState() => _SubPLOManagePageState();

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);
}

class _SubPLOManagePageState extends State<SubPLOManagePage> {
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
        title: const Text('SubPLO Management'),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: SubPLOManagePage._primary,
        onPressed: () => context.go('/admin/config/subplo/add'), // add page
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหา SubPLO...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: const Color(0xFFF5F6FA),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('subplo')
                    .orderBy('subplo_id')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                        child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData ||
                      snapshot.data!.docs.isEmpty) {
                    return const Center(
                        child: Text("ยังไม่มี SubPLO"));
                  }

                  final query = _searchCtrl.text.toLowerCase();
                  final docs = snapshot.data!.docs.where((doc) {
                    final data =
                        doc.data() as Map<String, dynamic>;
                    final id = (data['subplo_id'] ?? '')
                        .toString()
                        .toLowerCase();
                    final desc = (data['subplo_description'] ?? '')
                        .toString()
                        .toLowerCase();
                    return id.contains(query) || desc.contains(query);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("ไม่พบ SubPLO"));
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final data =
                          docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title =
                          "${data['subplo_id']} • ${data['subplo_description'] ?? ''}";

                      return _SubPLOTile(
                        title: title,
                        icon: Icons.extension_outlined,
                        onTap: () => context
                            .go('/admin/config/subplo/$id/edit'),
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

class _SubPLOTile extends StatelessWidget {
  const _SubPLOTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  static const _primary = SubPLOManagePage._primary;
  static const _soft = SubPLOManagePage._soft;
  static const _border = SubPLOManagePage._border;
  static const _shadow = SubPLOManagePage._shadow;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: _shadow,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                  color: _shadow,
                  blurRadius: 12,
                  offset: Offset(0, 4)),
            ],
            color: Colors.white,
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
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
            trailing: IconButton(
              icon: const Icon(Icons.edit_outlined),
              onPressed: onTap,
            ),
          ),
        ),
      ),
    );
  }
}