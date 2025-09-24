// lib/ui/admin/skill_edit_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SkillEditPage extends StatefulWidget {
  const SkillEditPage({super.key, required this.skillId});
  final String skillId;

  @override
  State<SkillEditPage> createState() => _SkillEditPageState();
}

class _SkillEditPageState extends State<SkillEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _desc = TextEditingController();
  String _type = "PLO";
  String? _selectedPLO;

  @override
  void initState() {
    super.initState();
    _loadSkill();
  }

  Future<void> _loadSkill() async {
    final doc =
        await FirebaseFirestore.instance
            .collection('skills')
            .doc(widget.skillId)
            .get();
    final data = doc.data()!;
    setState(() {
      _name.text = data['name'] ?? '';
      _desc.text = data['description'] ?? '';
      _type = data['type'] ?? 'PLO';
      _selectedPLO = data['plo'];
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  InputDecoration _boxDeco({String? hint}) => InputDecoration(
    hintText: hint,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _border),
    ),
    enabledBorder: OutlineInputBorder(
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

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;

    final data = {
      'name': _name.text.trim(),
      'description': _desc.text.trim(),
      'type': _type,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (_type == "SubPLO" && _selectedPLO != null) {
      data['plo'] = _selectedPLO as String;
    }

    await FirebaseFirestore.instance
        .collection('skills')
        .doc(widget.skillId)
        .update(data);

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Skill updated')));

    context.go('/admin/config/skills');
  }

  Future<void> _delete() async {
    await FirebaseFirestore.instance
        .collection('skills')
        .doc(widget.skillId)
        .delete();

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Skill deleted')));

    context.go('/admin/config/skills');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config/skills'),
        ),
        title: const Text('Edit Skill'),
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
              _fieldLabel("Skill name"),
              TextFormField(
                controller: _name,
                decoration: _boxDeco(),
                validator:
                    (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),

              _fieldLabel("Description"),
              TextFormField(
                controller: _desc,
                maxLines: 2,
                decoration: _boxDeco(),
              ),
              const SizedBox(height: 14),

              _fieldLabel("Type"),
              DropdownButtonFormField<String>(
                value: _type,
                items: const [
                  DropdownMenuItem(value: "PLO", child: Text("PLO")),
                  DropdownMenuItem(value: "SubPLO", child: Text("SubPLO")),
                ],
                onChanged: (v) => setState(() => _type = v ?? "PLO"),
                decoration: _boxDeco(),
              ),
              const SizedBox(height: 14),

              if (_type == "SubPLO")
                FutureBuilder<QuerySnapshot>(
                  future:
                      FirebaseFirestore.instance
                          .collection('skills')
                          .where('type', isEqualTo: 'PLO')
                          .get(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final ploDocs = snapshot.data!.docs;
                    return DropdownButtonFormField<String>(
                      value: _selectedPLO,
                      items:
                          ploDocs
                              .map(
                                (doc) => DropdownMenuItem<String>(
                                  value: doc['name'] as String,
                                  child: Text(doc['name'] as String),
                                ),
                              )
                              .toList(),
                      onChanged: (v) => setState(() => _selectedPLO = v),
                      decoration: _boxDeco(hint: "Select PLO"),
                    );
                  },
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
                  child: const Text('Submit'),
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
