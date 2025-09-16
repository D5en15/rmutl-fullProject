import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

// ใช้ Subject/SubjectStore จาก subjects_page.dart
import 'subjects_page.dart';

class EditSubjectPage extends StatefulWidget {
  const EditSubjectPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  State<EditSubjectPage> createState() => _EditSubjectPageState();
}

class _EditSubjectPageState extends State<EditSubjectPage> {
  // ---------- Design tokens ----------
  static const _primary   = Color(0xFF3D5CFF);
  static const _headerBG  = Color(0xFFF2F3F7);
  static const _label     = Color(0xFF6B6F7E);
  static const _border    = Color(0xFFE1E5F2);
  static const _errorRed  = Color(0xFFE53935);

  final _formKey  = GlobalKey<FormState>();
  final _credits  = TextEditingController();
  final _semester = TextEditingController();

  final _fCredits  = FocusNode();
  final _fSemester = FocusNode();
  final _fGrade    = FocusNode();

  // mock choices
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
  Subject? _current;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_current != null) return;

    final extra = GoRouterState.of(context).extra;
    if (extra is Subject) {
      _current = extra;
    } else {
      _current = SubjectStore.byId(widget.subjectId);
    }

    // ถ้าไม่เจอ ให้ mock ค่าเริ่มต้นสำหรับแก้ไข
    _current ??= Subject(
      id: widget.subjectId,
      name: _subjectNames.first,
      credits: 3,
      semester: '1/2567',
      grade: 'B',
    );

    _subjectName   = _current!.name;
    _credits.text  = _current!.credits.toString();
    _semester.text = _current!.semester;
    _grade         = _current!.grade;
  }

  @override
  void dispose() {
    _credits.dispose();
    _semester.dispose();
    _fCredits.dispose();
    _fSemester.dispose();
    _fGrade.dispose();
    super.dispose();
  }

  String? _required(String? v) {
    if (v == null || v.trim().isEmpty) return 'Please fill out this field';
    return null;
  }

  void _submit() {
    final ok = _formKey.currentState?.validate() ?? false;
    if (!ok || _subjectName == null || _grade == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please complete the form')),
      );
      return;
    }

    final updated = _current!.copyWith(
      name: _subjectName!,
      credits: int.tryParse(_credits.text.trim()) ?? _current!.credits,
      semester: _semester.text.trim(),
      grade: _grade!,
    );

    SubjectStore.upsert(updated);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Saved (mock)')));
    context.pop(updated);
  }

  void _delete() {
    SubjectStore.delete(widget.subjectId);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Deleted (mock)')));
    context.pop({'deleted': true});
  }

  // ---------- UI helpers ----------
  InputDecoration _boxDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
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

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            style: const TextStyle(
              color: _label,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );

  Widget _blueButton(String text, VoidCallback onTap) => SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );

  Widget _redButton(String text, VoidCallback onTap) => SizedBox(
        height: 50,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: _errorRed,
            foregroundColor: Colors.white,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (_current == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      // ----- HEADER เทา + หัวข้อใหญ่ -----
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Container(
              color: _headerBG,
              padding: const EdgeInsets.fromLTRB(6, 8, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  _BackBtn(),
                  SizedBox(width: 4),
                  Text(
                    'Edit Subject',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF171725),
                      letterSpacing: .2,
                    ),
                  ),
                ],
              ),
            ),
            // ----- BODY -----
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Subject name
                      _fieldLabel('Subject name'),
                      DropdownButtonFormField<String>(
                        value: _subjectName,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _boxDeco(),
                        items: _subjectNames
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _subjectName = v),
                        validator: (v) =>
                            v == null ? 'Please select subject' : null,
                      ),
                      const SizedBox(height: 14),

                      // credits
                      _fieldLabel('credits'),
                      TextFormField(
                        focusNode: _fCredits,
                        controller: _credits,
                        validator: _required,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _fSemester.requestFocus(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        decoration: _boxDeco(),
                      ),
                      const SizedBox(height: 14),

                      // Semester
                      _fieldLabel('Semester'),
                      TextFormField(
                        focusNode: _fSemester,
                        controller: _semester,
                        validator: _required,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (_) => _fGrade.requestFocus(),
                        decoration: _boxDeco(),
                      ),
                      const SizedBox(height: 14),

                      // Grade
                      _fieldLabel('Grade'),
                      DropdownButtonFormField<String>(
                        focusNode: _fGrade,
                        value: _grade,
                        isDense: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        decoration: _boxDeco(),
                        items: _grades
                            .map((e) =>
                                DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _grade = v),
                        validator: (v) =>
                            v == null ? 'Please select grade' : null,
                      ),
                      const SizedBox(height: 24),

                      _blueButton('Submit', _submit),
                      const SizedBox(height: 12),
                      _redButton('Delete', _delete),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackBtn extends StatelessWidget {
  const _BackBtn();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => context.pop(),
      icon: const Icon(Icons.arrow_back_ios_new_rounded),
      color: Colors.black87,
    );
  }
}
