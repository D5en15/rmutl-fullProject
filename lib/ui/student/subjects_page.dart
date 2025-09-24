// lib/ui/student/subjects_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SubjectsPage extends StatefulWidget {
  const SubjectsPage({super.key});
  static const _primary = Color(0xFF3D5CFF);

  @override
  State<SubjectsPage> createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        title: const Text('Subjects'),
        backgroundColor: const Color(0xFFF1F2F6),
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: "ค้นหารายวิชา (รหัส/ชื่อวิชา)...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(_uid)
            .collection('subjects')
            .orderBy('semester')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No subjects yet"));
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final code = (data['code'] ?? '').toString().toLowerCase();
            final nameTh = (data['name_th'] ?? '').toString().toLowerCase();
            final nameEn = (data['name_en'] ?? '').toString().toLowerCase();
            return code.contains(_search) ||
                nameTh.contains(_search) ||
                nameEn.contains(_search);
          }).toList();

          if (docs.isEmpty) {
            return const Center(child: Text("ไม่พบรายวิชาที่ค้นหา"));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final id = docs[i].id;
              return _SubjectTile(
                id: id,
                name: "${data['code']} • ${data['name_th']}",
                grade: data['grade'] ?? '',
                credits: data['credits']?.toString() ?? '',
                semester: data['semester'] ?? '',
                onEdit: () =>
                    context.push('/student/subjects/$id/edit', extra: data),
              );
            },
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/student/subjects/add'),
        backgroundColor: SubjectsPage._primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class _SubjectTile extends StatelessWidget {
  const _SubjectTile({
    required this.id,
    required this.name,
    required this.grade,
    required this.credits,
    required this.semester,
    required this.onEdit,
  });

  final String id;
  final String name;
  final String grade;
  final String credits;
  final String semester;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return PhysicalModel(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF2FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu_book_outlined,
                  color: Color(0xFF3D5CFF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Grade $grade • $credits credits • $semester',
                      style: const TextStyle(
                        color: Color(0xFF8B90A0),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Edit',
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}