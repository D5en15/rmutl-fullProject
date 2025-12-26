// lib/ui/admin/subplo_edit_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubPLOEditPage extends StatefulWidget {
  const SubPLOEditPage({super.key, required this.subploId});
  final String subploId;

  @override
  State<SubPLOEditPage> createState() => _SubPLOEditPageState();
}

class _SubPLOEditPageState extends State<SubPLOEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _id = TextEditingController();
  final _desc = TextEditingController();

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final doc = await FirebaseFirestore.instance
        .collection("subplo")
        .doc(widget.subploId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _id.text = data["subplo_id"] ?? "";
      _desc.text = data["subplo_description"] ?? "";
    }
    setState(() => _loading = false);
  }

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

  void _goBack() => context.go("/admin/config/subplo");

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance
        .collection("subplo")
        .doc(widget.subploId)
        .update({
      "subplo_id": _id.text.trim(),
      "subplo_description": _desc.text.trim(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ SubPLO updated")));
    _goBack();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection("subplo")
        .doc(widget.subploId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("🗑️ SubPLO deleted")));
    _goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit SubPLO"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBack,
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _primary,
                          foregroundColor: Colors.white),
                      child: const Text("Submit"),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _delete,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white),
                      child: const Text("Delete"),
                    )
                  ],
                ),
              ),
            ),
    );
  }
}