// lib/ui/admin/subject_edit_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectEditPage extends StatefulWidget {
  const SubjectEditPage({super.key, required this.subjectId});
  final String subjectId;

  @override
  State<SubjectEditPage> createState() => _SubjectEditPageState();
}

class _SubjectEditPageState extends State<SubjectEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _credits = TextEditingController();

  bool _loading = true;
  List<String> _selectedSubPLOs = [];

  // ✅ SubPLO mapping
  final Map<String, List<String>> _subploGroups = {
    "PLO1": ["1A", "1B", "1C", "1D", "1E", "1F"],
    "PLO2": ["2A", "2B", "2C"],
    "PLO3": ["3A", "3B", "3C", "3D", "3E", "3F"],
    "PLO4": ["4A", "4B", "4C", "4D"],
    "PLO5": ["5A", "5B", "5C", "5D", "5E", "5F", "5G"],
  };

  @override
  void initState() {
    super.initState();
    _loadSubject();
  }

  Future<void> _loadSubject() async {
    final doc = await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      _code.text = data["code"] ?? "";
      _nameTh.text = data["name_th"] ?? "";
      _nameEn.text = data["name_en"] ?? "";
      _credits.text = data["credits"] ?? "";
      _selectedSubPLOs = List<String>.from(data["subplo"] ?? []);
    }
    setState(() => _loading = false);
  }

  @override
  void dispose() {
    _code.dispose();
    _nameTh.dispose();
    _nameEn.dispose();
    _credits.dispose();
    super.dispose();
  }

  InputDecoration _boxDeco({String? hint}) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      );

  void _goBackToSubjects() => context.go("/admin/config/subjects");

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Subject"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: _goBackToSubjects,
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
                    _fieldLabel("Subject Code"),
                    TextFormField(
                      controller: _code,
                      decoration: _boxDeco(hint: "ENGSE101"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Name (TH)"),
                    TextFormField(
                      controller: _nameTh,
                      decoration: _boxDeco(hint: "ชื่อวิชาภาษาไทย"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Name (EN)"),
                    TextFormField(
                      controller: _nameEn,
                      decoration: _boxDeco(hint: "Subject name in English"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Credits"),
                    TextFormField(
                      controller: _credits,
                      decoration: _boxDeco(hint: "3(3-0-6)"),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    _fieldLabel("Select SubPLOs"),
                    ..._subploGroups.entries.map((entry) {
                      final plo = entry.key;
                      final items = entry.value;
                      return ExpansionTile(
                        title: Text(
                          plo,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        children: items.map((id) {
                          final selected = _selectedSubPLOs.contains(id);
                          return CheckboxListTile(
                            title: Text(id),
                            value: selected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSubPLOs.add(id);
                                } else {
                                  _selectedSubPLOs.remove(id);
                                }
                              });
                            },
                          );
                        }).toList(),
                      );
                    }),

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
                        child: const Text("Submit"),
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
                        child: const Text("Delete"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .update({
      "code": _code.text.trim(),
      "name_th": _nameTh.text.trim(),
      "name_en": _nameEn.text.trim(),
      "credits": _credits.text.trim(),
      "subplo": _selectedSubPLOs,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject updated")),
    );
    _goBackToSubjects();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection("subjects")
        .doc(widget.subjectId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject deleted")),
    );
    _goBackToSubjects();
  }
}