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
  final _id = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _credits = TextEditingController();

  List<String> _selectedSubPLOs = [];
  Map<String, List<Map<String, dynamic>>> _ploMap = {}; // PLO -> SubPLO

  @override
  void initState() {
    super.initState();
    _loadPLOs();
  }

  Future<void> _loadPLOs() async {
    final ploSnap = await FirebaseFirestore.instance.collection("plo").get();
    final subploSnap =
        await FirebaseFirestore.instance.collection("subplo").get();

    final subs = {for (var d in subploSnap.docs) d.id: d.data()};
    final map = <String, List<Map<String, dynamic>>>{};

    for (var p in ploSnap.docs) {
      final subIds = List<String>.from(p["subplo_id"] ?? []);
      map[p.id] = subIds.map((sid) {
        return {
          "id": sid,
          "desc": subs[sid]?["subplo_description"] ?? "",
        };
      }).toList();
    }

    setState(() => _ploMap = map);
  }

  @override
  void dispose() {
    _id.dispose();
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
      body: _ploMap.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _fieldLabel("Subject ID"),
                    TextFormField(
                      controller: _id,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Name (TH)"),
                    TextFormField(
                      controller: _nameTh,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Name (EN)"),
                    TextFormField(
                      controller: _nameEn,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 14),

                    _fieldLabel("Credits"),
                    TextFormField(
                      controller: _credits,
                      decoration: _boxDeco(),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? "Required" : null,
                    ),
                    const SizedBox(height: 20),

                    _fieldLabel("Select SubPLOs"),
                    ..._ploMap.entries.map((entry) {
                      final ploId = entry.key;
                      final subItems = entry.value;
                      return ExpansionTile(
                        title: Text(
                          ploId,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87),
                        ),
                        children: subItems.map((item) {
                          final sid = item["id"]!;
                          final desc = item["desc"]!;
                          final selected = _selectedSubPLOs.contains(sid);
                          return CheckboxListTile(
                            title: Text("$sid • $desc"),
                            value: selected,
                            onChanged: (checked) {
                              setState(() {
                                if (checked == true) {
                                  _selectedSubPLOs.add(sid);
                                } else {
                                  _selectedSubPLOs.remove(sid);
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
    );
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance.collection("subject").add({
      "subject_id": _id.text.trim(),
      "subject_thname": _nameTh.text.trim(),
      "subject_enname": _nameEn.text.trim(),
      "subject_credits": _credits.text.trim(),
      "subplo_id": _selectedSubPLOs,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Subject added")),
    );
    context.go("/admin/config/subjects");
  }
}