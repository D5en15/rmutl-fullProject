// lib/ui/admin/subject_add_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectAddPage extends StatefulWidget {
  const SubjectAddPage({super.key});

  @override
  State<SubjectAddPage> createState() => _SubjectAddPageState();
}

class _SubjectAddPageState extends State<SubjectAddPage> {
  // design tokens
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);
  static const _shadow = Color(0x0D000000);

  final _form = GlobalKey<FormState>();

  final _code = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _credits = TextEditingController();

  @override
  void dispose() {
    _code.dispose();
    _nameTh.dispose();
    _nameEn.dispose();
    _credits.dispose();
    super.dispose();
  }

  InputDecoration _boxDeco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Subject'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          // ✅ กลับไปหน้า Subjects list
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
                    _fieldLabel('Subject Code'),
                    TextFormField(
                      controller: _code,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Name (TH)'),
                    TextFormField(
                      controller: _nameTh,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Name (EN)'),
                    TextFormField(
                      controller: _nameEn,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel('Credits'),
                    TextFormField(
                      controller: _credits,
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

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance.collection('subjects').add({
      'code': _code.text.trim(),
      'name_th': _nameTh.text.trim(),
      'name_en': _nameEn.text.trim(),
      'credits': _credits.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Subject added')),
    );

    context.go('/admin/config/subjects');
  }
}