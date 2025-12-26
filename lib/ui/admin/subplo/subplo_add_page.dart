// lib/ui/admin/subplo_add_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubPLOAddPage extends StatefulWidget {
  const SubPLOAddPage({super.key});

  @override
  State<SubPLOAddPage> createState() => _SubPLOAddPageState();
}

class _SubPLOAddPageState extends State<SubPLOAddPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _desc = TextEditingController();

  @override
  void dispose() {
    _id.dispose();
    _desc.dispose();
    super.dispose();
  }

  InputDecoration _boxDeco({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _border)),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text,
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black87)),
      );

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    final subploId = _id.text.trim();

    await FirebaseFirestore.instance
        .collection("subplo")
        .doc(subploId) // ✅ ใช้ subplo_id เป็น Document ID
        .set({
      "subplo_id": subploId,
      "subplo_description": _desc.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ SubPLO added")));
    context.go("/admin/config/subplo");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add SubPLO"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go("/admin/config/subplo"),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Form(
          key: _form,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _fieldLabel("SubPLO ID"),
              TextFormField(
                controller: _id,
                decoration: _boxDeco(hint: "1A"),
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Required" : null,
              ),
              const SizedBox(height: 14),
              _fieldLabel("Description"),
              TextFormField(
                controller: _desc,
                decoration: _boxDeco(hint: "คำอธิบายทักษะรอง"),
                maxLines: 2,
                validator: (v) =>
                    (v == null || v.isEmpty) ? "Required" : null,
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
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Add"),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}