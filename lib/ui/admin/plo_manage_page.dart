import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PLOManagePage extends StatefulWidget {
  const PLOManagePage({super.key});

  @override
  State<PLOManagePage> createState() => _PLOManagePageState();

  // 🎨 Design tokens
  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);
}

class _PLOManagePageState extends State<PLOManagePage> {
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
        title: const Text("PLO Management"),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: PLOManagePage._primary,
        onPressed: () => context.go('/admin/config/plo/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 🔍 Search box
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'ค้นหา PLO...',
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
            // 📜 PLO list
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('plo')
                    .orderBy('plo_id')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("ยังไม่มี PLO"));
                  }

                  final query = _searchCtrl.text.toLowerCase();
                  final docs = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final id =
                        (data['plo_id'] ?? '').toString().toLowerCase();
                    final desc =
                        (data['plo_description'] ?? '').toString().toLowerCase();
                    return id.contains(query) || desc.contains(query);
                  }).toList();

                  if (docs.isEmpty) {
                    return const Center(child: Text("ไม่พบ PLO"));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      final id = docs[i].id;
                      final title = data['plo_id'] ?? '';
                      final subtitle = data['plo_description'] ?? '';

                      return _PLOTile(
                        title: title,
                        subtitle: subtitle,
                        icon: Icons.check_circle_outline,
                        onTap: () =>
                            context.go('/admin/config/plo/$id/edit'),
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

class _PLOTile extends StatelessWidget {
  const _PLOTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  static const _primary = PLOManagePage._primary;
  static const _soft = PLOManagePage._soft;
  static const _border = PLOManagePage._border;
  static const _shadow = PLOManagePage._shadow;
  static const _muted = PLOManagePage._muted;

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
            subtitle: Text(subtitle,
                style: const TextStyle(color: _muted), maxLines: 2),
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