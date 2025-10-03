// lib/ui/student/edit_subject_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditSubjectPage extends StatefulWidget {
  const EditSubjectPage({super.key, required this.enrollmentId});
  final String enrollmentId; // ใช้ enrollment_id

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _headerBG = Color(0xFFF2F3F7);
  static const _label = Color(0xFF6B6F7E);
  static const _border = Color(0xFFE1E5F2);
  static const _errorRed = Color(0xFFE53935);

  final _formKey = GlobalKey<FormState>();
  String? _subjectId;
  String? _semester;
  String? _grade;
  bool _loading = true;

  String? _userId; // มาจากตาราง user

  final _semesters = const [
    "ปี 1 เทอม 1",
    "ปี 1 เทอม 2",
    "ปี 2 เทอม 1",
    "ปี 2 เทอม 2",
    "ปี 3 เทอม 1",
    "ปี 3 เทอม 2",
    "ปี 4 เทอม 1",
    "ปี 4 เทอม 2",
  ];

  final _grades = const [
    "A", "B+", "B", "C+", "C", "D+", "D", "F",
    "W", "I", "S", "U", "AU"
  ];

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
      _userId = snap.docs.first.data()["user_id"].toString();
      _loadEnrollment();
    }
  }

  Future<void> _loadEnrollment() async {
    final doc = await FirebaseFirestore.instance
        .collection('enrollment')
        .doc(widget.enrollmentId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _subjectId = data['subject_id'];
        _semester = data['enrollment_semester'];
        _grade = data['enrollment_grade'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjects(String filter) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subject').orderBy('subject_id').get();

    return snapshot.docs
        .map((doc) => {
              'id': doc['subject_id'],
              'subject_thname': doc['subject_thname'],
              'subject_enname': doc['subject_enname'],
            })
        .where((s) =>
            s['id'].toString().toLowerCase().contains(filter.toLowerCase()) ||
            s['subject_thname'].toString().toLowerCase().contains(filter.toLowerCase()) ||
            s['subject_enname'].toString().toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_subjectId == null || _semester == null || _grade == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกข้อมูลให้ครบ')),
      );
      return;
    }

    await FirebaseFirestore.instance
        .collection('enrollment')
        .doc(widget.enrollmentId)
        .update({
      'user_id': _userId,
      'subject_id': _subjectId,
      'enrollment_semester': _semester,
      'enrollment_grade': _grade,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('✅ แก้ไขรายวิชาเรียบร้อย')));
    context.pop();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('enrollment')
        .doc(widget.enrollmentId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('🗑️ ลบรายวิชาแล้ว')));
    context.pop({'deleted': true});
  }

  InputDecoration _boxDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(text,
              style: const TextStyle(color: _label, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Subject"),
        backgroundColor: _headerBG,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _fieldLabel("Subject"),
              DropdownSearch<Map<String, dynamic>>(
                asyncItems: (filter) => _fetchSubjects(filter),
                itemAsString: (item) =>
                    "${item['id']} • ${item['subject_thname']} (${item['subject_enname']})",
                selectedItem: _subjectId != null
                    ? {'id': _subjectId!, 'subject_thname': '', 'subject_enname': ''}
                    : null,
                onChanged: (v) => setState(() => _subjectId = v?['id']),
                validator: (v) => v == null ? 'กรุณาเลือกรายวิชา' : null,
                dropdownDecoratorProps: DropDownDecoratorProps(
                  dropdownSearchDecoration:
                      _boxDeco().copyWith(hintText: "พิมพ์ค้นหารายวิชา..."),
                ),
                popupProps: const PopupProps.dialog(
                  showSearchBox: true,
                  searchFieldProps: TextFieldProps(
                    decoration: InputDecoration(
                      hintText: "ค้นหารายวิชา...",
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Semester"),
              DropdownButtonFormField<String>(
                value: _semester,
                decoration: _boxDeco(),
                items: _semesters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _semester = v),
                validator: (v) => v == null ? 'กรุณาเลือกเทอม' : null,
              ),
              const SizedBox(height: 14),

              _fieldLabel("Grade"),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: _boxDeco(),
                items: _grades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'กรุณาเลือกเกรด' : null,
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text("บันทึกการแก้ไข"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _delete,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _errorRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text("ลบรายวิชา"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}