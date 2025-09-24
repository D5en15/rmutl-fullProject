// lib/ui/admin/skills_manage_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillsManagePage extends StatelessWidget {
  const SkillsManagePage({super.key});

  static const _primary = Color(0xFF3D5CFF);
  static const _muted = Color(0xFF858597);
  static const _soft = Color(0xFFF6F7FF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config'),
        ),
        title: const Text('PLO / SubPLO Management'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () => context.go('/admin/config/skills/add'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('skills')
            .orderBy('name') // ✅ ใช้ name แทน id
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("ยังไม่มี PLO / SubPLO"));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;

              final skillName = data['name'] ?? '';
              final type = data['type'] ?? '';
              final desc = data['description'] ?? '';
              final parentPLO = data['plo'] ?? '';

              final title = "$skillName ($type)";
              final subtitle = type == 'SubPLO'
                  ? "$desc • PLO: $parentPLO"
                  : desc;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _border),
                  boxShadow: const [
                    BoxShadow(
                        color: _shadow, blurRadius: 12, offset: Offset(0, 4)),
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
                    child: const Icon(Icons.school, color: _primary, size: 26),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(color: _muted),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () =>
                        context.go('/admin/config/skills/$id/edit'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}