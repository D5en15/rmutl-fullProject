// lib/ui/student/add_subject_page.dart
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

  Future<List<Map<String, dynamic>>> _fetchSubjects(String filter) async {
    final snapshot =
        await FirebaseFirestore.instance.collection('subjects').orderBy('code').get();

    return snapshot.docs
        .map((doc) => {
              'id': doc.id,
              'code': doc['code'],
              'name_th': doc['name_th'],
            })
        .where((s) =>
            s['code'].toString().toLowerCase().contains(filter.toLowerCase()) ||
            s['name_th'].toString().toLowerCase().contains(filter.toLowerCase()))
        .toList();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_subjectId == null || _semester == null || _grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form')),
      );
      return;
    }

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final subjectDoc =
        await FirebaseFirestore.instance.collection('subjects').doc(_subjectId).get();

    if (!subjectDoc.exists) return;

    final data = subjectDoc.data()!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('subjects')
        .add({
      'subjectId': _subjectId,
      'code': data['code'],
      'name_th': data['name_th'],
      'name_en': data['name_en'],
      'credits': data['credits'],
      'semester': _semester,
      'grade': _grade,
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject added')),
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
        title: const Text('Add subject'),
        backgroundColor: const Color(0xFFF1F2F6),
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _label('Subject name'),
              DropdownSearch<Map<String, dynamic>>(
                asyncItems: (filter) => _fetchSubjects(filter),
                itemAsString: (item) => "${item['code']} • ${item['name_th']}",
                onChanged: (v) => setState(() => _subjectId = v?['id']),
                validator: (v) => v == null ? 'Please select subject' : null,
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

              _label('Semester'),
              DropdownButtonFormField<String>(
                value: _semester,
                decoration: _boxDeco(),
                items: _semesters
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _semester = v),
                validator: (v) => v == null ? 'Please select semester' : null,
              ),
              const SizedBox(height: 16),

              _label('Grade'),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: _boxDeco(),
                items: _grades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'Please select grade' : null,
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
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}