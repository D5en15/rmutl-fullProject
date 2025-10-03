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
  String? _userId; // user_id จากตาราง user
  String _search = "";

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("user")
        .where("user_email", isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      setState(() {
        _userId = snap.docs.first.data()["user_id"].toString();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _loadEnrollments() {
    if (_userId == null) {
      return const Stream.empty();
    }

    return FirebaseFirestore.instance
        .collection("enrollment")
        .where("user_id", isEqualTo: _userId)
        .snapshots()
        .asyncMap((enrollSnap) async {
      List<Map<String, dynamic>> results = [];
      for (var e in enrollSnap.docs) {
        final enroll = e.data();
        final subjectId = enroll["subject_id"];
        if (subjectId == null) continue;

        final subjDoc = await FirebaseFirestore.instance
            .collection("subject")
            .doc(subjectId)
            .get();

        if (subjDoc.exists) {
          final subject = subjDoc.data()!;
          results.add({
            "id": e.id, // enrollment document id
            "subject_id": subject["subject_id"],
            "subject_thname": subject["subject_thname"],
            "subject_enname": subject["subject_enname"],
            "subject_credits": subject["subject_credits"],
            "enrollment_semester": enroll["enrollment_semester"],
            "enrollment_grade": enroll["enrollment_grade"],
          });
        }
      }
      return results;
    });
  }

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

      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _loadEnrollments(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("ยังไม่มีรายวิชา"));
                }

                final docs = snapshot.data!.where((data) {
                  final code = (data['subject_id'] ?? '').toString().toLowerCase();
                  final nameTh = (data['subject_thname'] ?? '').toString().toLowerCase();
                  final nameEn = (data['subject_enname'] ?? '').toString().toLowerCase();
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
                    final data = docs[i];
                    return _SubjectTile(
                      id: data["id"],
                      name:
                          "${data['subject_id']} • ${data['subject_thname']} (${data['subject_enname']})",
                      grade: data['enrollment_grade'] ?? '',
                      credits: data['subject_credits']?.toString() ?? '',
                      semester: data['enrollment_semester'] ?? '',
                      onEdit: () =>
                          context.push('/student/subjects/${data["id"]}/edit', extra: data),
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