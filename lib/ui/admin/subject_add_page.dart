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
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _code = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _credits = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Add Subject"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go("/admin/config/subjects"),
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
                _fieldLabel("Subject Code"),
                TextFormField(
                  controller: _code,
                  decoration: _boxDeco(),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel("Name (TH)"),
                TextFormField(
                  controller: _nameTh,
                  decoration: _boxDeco(),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel("Name (EN)"),
                TextFormField(
                  controller: _nameEn,
                  decoration: _boxDeco(),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
                ),
                const SizedBox(height: 14),

                _fieldLabel("Credits"),
                TextFormField(
                  controller: _credits,
                  decoration: _boxDeco(),
                  validator: (v) => v == null || v.isEmpty ? "Required" : null,
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
                          fontWeight: FontWeight.bold, color: Colors.black87),
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
                    child: const Text("Add"),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance.collection("subjects").add({
      "code": _code.text.trim(),
      "name_th": _nameTh.text.trim(),
      "name_en": _nameEn.text.trim(),
      "credits": _credits.text.trim(),
      "subplo": _selectedSubPLOs,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject added")),
    );

    context.go("/admin/config/subjects");
  }
}