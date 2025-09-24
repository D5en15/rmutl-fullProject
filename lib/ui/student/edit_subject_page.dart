// lib/ui/student/edit_subject_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dropdown_search/dropdown_search.dart';

class EditSubjectPage extends StatefulWidget {
  const EditSubjectPage({super.key, required this.subjectId});
  final String subjectId;

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

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

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
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('subjects')
        .doc(widget.subjectId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      setState(() {
        _subjectId = data['subjectId'];
        _semester = data['semester'];
        _grade = data['grade'];
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

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

    final subjectDoc =
        await FirebaseFirestore.instance.collection('subjects').doc(_subjectId).get();

    if (!subjectDoc.exists) return;

    final data = subjectDoc.data()!;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('subjects')
        .doc(widget.subjectId)
        .update({
      'subjectId': _subjectId,
      'code': data['code'],
      'name_th': data['name_th'],
      'name_en': data['name_en'],
      'credits': data['credits'],
      'semester': _semester,
      'grade': _grade,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Subject updated')));
    context.pop();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .collection('subjects')
        .doc(widget.subjectId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Subject deleted')));
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
              _fieldLabel("Subject name"),
              DropdownSearch<Map<String, dynamic>>(
                asyncItems: (filter) => _fetchSubjects(filter),
                itemAsString: (item) => "${item['code']} • ${item['name_th']}",
                selectedItem: _subjectId != null
                    ? {'id': _subjectId!, 'code': '', 'name_th': ''}
                    : null,
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
              const SizedBox(height: 14),

              _fieldLabel("Semester"),
              DropdownButtonFormField<String>(
                value: _semester,
                decoration: _boxDeco(),
                items: _semesters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _semester = v),
                validator: (v) => v == null ? 'Please select semester' : null,
              ),
              const SizedBox(height: 14),

              _fieldLabel("Grade"),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: _boxDeco(),
                items: _grades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'Please select grade' : null,
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
                child: const Text("Submit"),
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
                child: const Text("Delete"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}