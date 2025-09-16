import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ใช้ Subject/SubjectStore จาก subjects_page.dart หรือ mock
import 'subject_mock.dart';

class AddSubjectPage extends StatefulWidget {
  const AddSubjectPage({super.key});

  @override
  State<AddSubjectPage> createState() => _AddSubjectPageState();
}

class _AddSubjectPageState extends State<AddSubjectPage> {
  // Theme token
  static const _primary = Color(0xFF3D5CFF);
  static const _border  = Color(0xFFE1E5F2);

  final _formKey  = GlobalKey<FormState>();
  final _credits  = TextEditingController();
  final _semester = TextEditingController();

  final _subjectNames = const [
    'Programming 101',
    'Linear Algebra',
    'Physics for Engineer',
    'Data Structures',
    'Database Systems',
  ];
  final _grades = const ['A', 'B+', 'B', 'C+', 'C', 'D', 'F'];

  String? _subjectName;
  String? _grade;

  @override
  void dispose() {
    _credits.dispose();
    _semester.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill out this field';
    return null;
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok) return;
    if (_subjectName == null || _grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form')),
      );
      return;
    }

    final s = Subject(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _subjectName!,
      credits: int.tryParse(_credits.text.trim()) ?? 0,
      semester: _semester.text.trim(),
      grade: _grade!,
    );

    SubjectStore.upsert(s);
    context.pop(s);
  }

  /// กล่องฟอร์ม “ไม่มี label/hint” — label จะอยู่เป็น Text ด้านบนแทน
  InputDecoration _boxDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _primary, width: 1.5),
        ),
      );

  /// Label สไตล์เทาอ่อน อยู่ “เหนือกล่อง”
  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add subject'),
        backgroundColor: const Color(0xFFF1F2F6), // เทาอ่อน ให้ดูเหมือนดีไซน์
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ---- Subject name ----
              _label('Subject name'),
              DropdownButtonFormField<String>(
                value: _subjectName,
                decoration: _boxDeco(),
                items: _subjectNames
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _subjectName = v),
                validator: (v) => v == null ? 'Please select subject' : null,
              ),
              const SizedBox(height: 16),

              // ---- Credits ----
              _label('Credits'),
              TextFormField(
                controller: _credits,
                validator: _required,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(2),
                ],
                decoration: _boxDeco(),
              ),
              const SizedBox(height: 16),

              // ---- Semester ----
              _label('Semester'),
              TextFormField(
                controller: _semester,
                validator: _required,
                decoration: _boxDeco(),
              ),
              const SizedBox(height: 16),

              // ---- Grade ----
              _label('Grade'),
              DropdownButtonFormField<String>(
                value: _grade,
                decoration: _boxDeco(),
                items: _grades
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _grade = v),
                validator: (v) => v == null ? 'Please select grade' : null,
              ),
              const SizedBox(height: 24),

              // ADD button
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
