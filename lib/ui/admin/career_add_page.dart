// lib/ui/admin/career_add_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerAddPage extends StatefulWidget {
  const CareerAddPage({super.key});

  @override
  State<CareerAddPage> createState() => _CareerAddPageState();
}

class _CareerAddPageState extends State<CareerAddPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();

  @override
  void dispose() {
    _nameTh.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  InputDecoration _deco() => const InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _border),
        ),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance.collection('careers').add({
      'name_th': _nameTh.text.trim(),
      'name_en': _nameEn.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Career added')),
    );

    context.go('/admin/config/careers');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config/careers'),
        ),
        title: const Text('Add Career'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Career name (TH)",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameTh,
                decoration: _deco(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("Career name (EN)",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameEn,
                decoration: _deco(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

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
    );
  }
}