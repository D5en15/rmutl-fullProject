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
  final _id = TextEditingController();
  final _nameTh = TextEditingController();
  final _nameEn = TextEditingController();
  final _credits = TextEditingController();

  bool _loading = true;
  List<String> _selectedSubPLOs = [];
  Map<String, List<Map<String, dynamic>>> _ploMap = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    // โหลดข้อมูลรายวิชา
    final doc = await FirebaseFirestore.instance
        .collection("subject") // ✅ ใช้ subject (ไม่มี s)
        .doc(widget.subjectId)
        .get();

    // โหลด PLO และ SubPLO
    final ploSnap = await FirebaseFirestore.instance.collection("plo").get();
    final subploSnap =
        await FirebaseFirestore.instance.collection("subplo").get();

    // map subplo -> description
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

    if (doc.exists) {
      final data = doc.data()!;
      _id.text = data["subject_id"] ?? "";
      _nameTh.text = data["subject_thname"] ?? "";
      _nameEn.text = data["subject_enname"] ?? "";
      _credits.text = data["subject_credits"] ?? "";
      _selectedSubPLOs = List<String>.from(data["subplo_id"] ?? []);
    }

    setState(() {
      _ploMap = map;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _id.dispose();
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
            borderSide: const BorderSide(color: _border)),
      );

  Widget _fieldLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
              fontWeight: FontWeight.w600, color: Colors.black87),
        ),
      );

  void _goBack() => context.go("/admin/config/subjects");

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
                    _fieldLabel("Subject ID"),
                    TextFormField(
                      controller: _id,
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

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    await FirebaseFirestore.instance
        .collection("subject") // ✅ ใช้ subject (ไม่มี s)
        .doc(widget.subjectId)
        .update({
      "subject_id": _id.text.trim(),
      "subject_thname": _nameTh.text.trim(),
      "subject_enname": _nameEn.text.trim(),
      "subject_credits": _credits.text.trim(),
      "subplo_id": _selectedSubPLOs,
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject updated")));
    _goBack();
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection("subject") // ✅ ใช้ subject (ไม่มี s)
        .doc(widget.subjectId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subject deleted")));
    _goBack();
  }
}