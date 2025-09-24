// lib/ui/admin/career_edit_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CareerEditPage extends StatefulWidget {
  const CareerEditPage({super.key, required this.careerId});
  final String careerId;

  @override
  State<CareerEditPage> createState() => _CareerEditPageState();
}

class _CareerEditPageState extends State<CareerEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await FirebaseFirestore.instance
        .collection('careers')
        .doc(widget.careerId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _nameTh.text = data['name_th'] ?? '';
      _nameEn.text = data['name_en'] ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _nameTh.dispose();
    _nameEn.dispose();
    super.dispose();
  }

  InputDecoration _deco({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance
        .collection('careers')
        .doc(widget.careerId)
        .update({
      'name_th': _nameTh.text.trim(),
      'name_en': _nameEn.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Career updated')),
    );
    context.go('/admin/config/careers');
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('careers')
        .doc(widget.careerId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Career deleted')),
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
        title: const Text('Edit Career'),
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
              const SizedBox(height: 20),

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
                  child: const Text('Save'),
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
    );
  }
}