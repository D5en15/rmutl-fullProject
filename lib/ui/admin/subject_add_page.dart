import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/services.dart';

class SubjectAddPage extends StatefulWidget {
  const SubjectAddPage({super.key});

  @override
  State<SubjectAddPage> createState() => _SubjectAddPageState();
}

class _SubjectAddPageState extends State<SubjectAddPage> {
  // design tokens
  static const _primary = Color(0xFF3D5CFF);
  static const _border  = Color(0xFFEFF1F7);
  static const _shadow  = Color(0x0D000000);

  final _form = GlobalKey<FormState>();

  String? _name;
  final _credits = TextEditingController();
  final _gpa     = TextEditingController();
  final _skill   = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Subjects'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          // ✅ กลับไปหน้า Dashboard → Subjects list
          onPressed: () => context.go('/admin/config/subjects'),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            elevation: 0,
            shadowColor: _shadow,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
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
                      ]
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _name = v),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Please select subject'
                          : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Credits'),
                    TextFormField(
                      controller: _credits,
                      decoration: _boxDeco(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9]'))
                      ],
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
                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))
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
                        child: const Text('Add'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added (mock)')),
    );

    context.go('/admin/config/subjects');
  }
}
