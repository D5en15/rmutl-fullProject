import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFE1E5F2);

  final _formKey = GlobalKey<FormState>();
  String? _subjectId;
  String? _semester;
  String? _grade;

  String? _userId; // จากตาราง user

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
      setState(() {
        _userId = snap.docs.first.data()["user_id"].toString();
      });
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubjects(String filter) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subject').orderBy('subject_id').get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'subject_id': doc['subject_id'],
              'subject_thname': doc['subject_thname'],
              'subject_enname': doc['subject_enname'],
              'subject_credits': doc['subject_credits'],
            })
        .where((s) =>
            s['subject_id'].toString().toLowerCase().contains(filter.toLowerCase()) ||
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

    // ✅ สร้าง enrollment record
    await FirebaseFirestore.instance.collection('enrollment').add({
      'user_id': _userId,
      'subject_id': _subjectId,
      'enrollment_semester': _semester,
      'enrollment_grade': _grade,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ เพิ่มรายวิชาเรียบร้อย')),
    );
    context.pop();
  }

  InputDecoration _boxDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มรายวิชา'),
        backgroundColor: const Color(0xFFF1F2F6),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: _userId == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _label('เลือกรายวิชา'),
                    DropdownSearch<Map<String, dynamic>>(
                      asyncItems: (filter) => _fetchSubjects(filter),
                      itemAsString: (item) =>
                          "${item['subject_id']} • ${item['subject_thname']} (${item['subject_enname']})",
                      onChanged: (v) => setState(() => _subjectId = v?['subject_id']),
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
                    const SizedBox(height: 16),

                    _label('เลือกเทอม'),
                    DropdownButtonFormField<String>(
                      value: _semester,
                      decoration: _boxDeco(),
                      items: _semesters
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _semester = v),
                      validator: (v) => v == null ? 'กรุณาเลือกเทอม' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('เลือกเกรด'),
                    DropdownButtonFormField<String>(
                      value: _grade,
                      decoration: _boxDeco(),
                      items: _grades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _grade = v),
                      validator: (v) => v == null ? 'กรุณาเลือกเกรด' : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submit,
                        child: const Text('เพิ่มรายวิชา'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}