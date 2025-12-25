// lib/ui/student/edit_subject_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  static const Map<String, String> _legacySemesterMap = {
    "ปี 1 เทอม 1": "Year 1 Term 1",
    "ปี 1 เทอม 2": "Year 1 Term 2",
    "ปี 2 เทอม 1": "Year 2 Term 1",
    "ปี 2 เทอม 2": "Year 2 Term 2",
    "ปี 3 เทอม 1": "Year 3 Term 1",
    "ปี 3 เทอม 2": "Year 3 Term 2",
    "ปี 4 เทอม 1": "Year 4 Term 1",
    "ปี 4 เทอม 2": "Year 4 Term 2",
  };

  final _formKey = GlobalKey<FormState>();
  String? _subjectId;
  String? _semester;
  String? _grade;
  Map<String, dynamic>? _selectedSubject;
  bool _loading = true;
  late final TextEditingController _subjectDisplayController;

  String? _userId; // มาจากตาราง user

  final _semesters = const [
    "Year 1 Term 1",
    "Year 1 Term 2",
    "Year 2 Term 1",
    "Year 2 Term 2",
    "Year 3 Term 1",
    "Year 3 Term 2",
    "Year 4 Term 1",
    "Year 4 Term 2",
  ];

  final _grades = const [
    "A", "B+", "B", "C+", "C", "D+", "D", "F",
    "W", "I", "S", "U", "AU"
  ];

  @override
  void initState() {
    super.initState();
    _subjectDisplayController = TextEditingController();
    _loadUserId();
  }

  @override
  void dispose() {
    _subjectDisplayController.dispose();
    super.dispose();
  }

  Future<void> _loadUserId() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    final authUid = FirebaseAuth.instance.currentUser?.uid;
    if (email == null && authUid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection("user")
        .where("user_email", isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty) {
      final doc = snap.docs.first;
      final data = doc.data();
      final rawId = (data["user_id"] ?? '').toString().trim();
      _userId = rawId.isNotEmpty ? rawId : doc.id;
      _loadEnrollment();
    } else if (authUid != null) {
      _userId = authUid;
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
      final subjectInfo = await _resolveSubjectInfo(data['subject_id']);
      if (!mounted) return;
      setState(() {
        _subjectId = data['subject_id'];
        _semester = _normalizeSemester(data['enrollment_semester']);
        _grade = data['enrollment_grade'];
        _selectedSubject = subjectInfo ??
            {
              'id': data['subject_id'],
              'subject_thname': '',
              'subject_enname': '',
            };
        _loading = false;
        _subjectDisplayController.text = _subjectLabel();
      });
    } else {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<Map<String, dynamic>?> _resolveSubjectInfo(String? subjectId) async {
    if (subjectId == null) return null;
    try {
      final directDoc =
          await FirebaseFirestore.instance.collection('subject').doc(subjectId).get();
      if (directDoc.exists && directDoc.data() != null) {
        final data = directDoc.data()!;
        return {
          'id': data['subject_id'],
          'subject_thname': data['subject_thname'],
          'subject_enname': data['subject_enname'],
        };
      }

      final query = await FirebaseFirestore.instance
          .collection('subject')
          .where('subject_id', isEqualTo: subjectId)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) {
        final data = query.docs.first.data();
        return {
          'id': data['subject_id'],
          'subject_thname': data['subject_thname'],
          'subject_enname': data['subject_enname'],
        };
      }
    } catch (_) {
      // ignore and fallback to null
    }
    return null;
  }

  String? _normalizeSemester(String? value) {
    if (value == null) return null;
    if (_semesters.contains(value)) return value;
    final mapped = _legacySemesterMap[value];
    if (mapped != null && _semesters.contains(mapped)) {
      return mapped;
    }
    return null;
  }

  String _subjectLabel() {
    if (_selectedSubject != null) {
      final id = (_selectedSubject?['id'] ?? '').toString();
      final th = (_selectedSubject?['subject_thname'] ?? '').toString();
      final en = (_selectedSubject?['subject_enname'] ?? '').toString();
      if (th.isEmpty && en.isEmpty) return id;
      return "$id • $th ($en)";
    }
    return _subjectId ?? '';
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_subjectId == null || _semester == null || _grade == null || _userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete all fields')),
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

    await _triggerRecalc();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Subject updated successfully')));
    context.pop();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('enrollment')
        .doc(widget.enrollmentId)
        .delete();

    await _triggerRecalc();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Subject removed')));
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

  Future<void> _triggerRecalc() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return;
    try {
      await http.post(
        Uri.parse("https://calculatestudentmetrics-hifpdjd5kq-uc.a.run.app"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email}),
      );
    } catch (_) {
      // ถ้าคำนวณไม่ทัน server trigger จะประมวลผลเมื่อ enrollment เปลี่ยนแล้ว
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Subject"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _fieldLabel("Subject"),
              TextFormField(
                controller: _subjectDisplayController,
                readOnly: true,
                decoration: _boxDeco(),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Semester"),
              DropdownButtonFormField<String>(
                value: _semester,
                decoration: _boxDeco(),
                items: _semesters.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _semester = v),
                validator: (v) => v == null ? 'Please select a term' : null,
              ),
              const SizedBox(height: 14),

              _fieldLabel("Grade"),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: _boxDeco(),
                items: _grades.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'Please select a grade' : null,
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
                child: const Text("Save changes"),
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
                child: const Text("Delete subject"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
