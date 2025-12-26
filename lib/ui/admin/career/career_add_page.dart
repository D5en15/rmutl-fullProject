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

  bool _loading = false;

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
        border: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
          borderSide: BorderSide(color: _border),
        ),
      );

  /// ✅ สร้าง career_id อัตโนมัติ
  Future<String> _generateCareerId() async {
    final snapshot =
        await FirebaseFirestore.instance.collection('career').get();

    if (snapshot.docs.isEmpty) {
      return "cr01";
    }

    // หา career_id ล่าสุด (เรียงลำดับ)
    final ids = snapshot.docs
        .map((d) => d['career_id'] as String? ?? "")
        .where((id) => id.startsWith("cr"))
        .toList();

    ids.sort();

    final lastId = ids.isNotEmpty ? ids.last : "cr00";
    final num = int.tryParse(lastId.replaceAll("cr", "")) ?? 0;
    final nextNum = num + 1;
    return "cr${nextNum.toString().padLeft(2, '0')}";
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    final id = await _generateCareerId();

    await FirebaseFirestore.instance.collection('career').doc(id).set({
      'career_id': id,
      'career_thname': _nameTh.text.trim(),
      'career_enname': _nameEn.text.trim(),
    });

    if (!mounted) return;
    setState(() => _loading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('✅ Career $id added')),
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
                decoration: _deco(hint: "นักประกันคุณภาพซอฟต์แวร์"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("Career name (EN)",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameEn,
                decoration: _deco(hint: "Software Quality Assurance"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 48,
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}