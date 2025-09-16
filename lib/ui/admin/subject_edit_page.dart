import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class SubjectEditPage extends StatefulWidget {
  const SubjectEditPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  State<SubjectEditPage> createState() => _SubjectEditPageState();
}

class _SubjectEditPageState extends State<SubjectEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border  = Color(0xFFEFF1F7);
  static const _shadow  = Color(0x0D000000);

  final _form = GlobalKey<FormState>();

  String? _name = 'Programming 101';
  final _credits = TextEditingController(text: '3');
  final _gpa     = TextEditingController(text: '4.0');
  final _skill   = TextEditingController(text: 'Programming');

  @override
  void dispose() {
    _credits.dispose();
    _gpa.dispose();
    _skill.dispose();
    super.dispose();
  }

  InputDecoration _boxDeco({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  Widget _fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(text,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, color: Colors.black87)),
        ),
      );

  void _goBackToSubjects() => context.go('/admin/config/subjects');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Edit Subjects'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBackToSubjects,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fieldLabel('Subject name'),
                DropdownButtonFormField<String>(
                  value: _name,
                  decoration: _boxDeco(),
                  items: const [
                    'Programming 101',
                    'Linear Algebra',
                    'Physics for Engineer'
                  ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (v) => setState(() => _name = v),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Please select subject'
                      : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel('Credits'),
                TextFormField(
                  controller: _credits,
                  decoration: _boxDeco(),
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel('Grade point'),
                TextFormField(
                  controller: _gpa,
                  decoration: _boxDeco(),
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel('Skill'),
                TextFormField(
                  controller: _skill,
                  decoration: _boxDeco(),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 22),

                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Submit'),
                  ),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  height: 48,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _delete,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved (mock)')),
    );
    _goBackToSubjects();
  }

  void _delete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted (mock)')),
    );
    _goBackToSubjects();
  }
}
