import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SkillEditPage extends StatefulWidget {
  const SkillEditPage({super.key, required this.skillId});
  final String skillId;

  @override
  State<SkillEditPage> createState() => _SkillEditPageState();
}

class _SkillEditPageState extends State<SkillEditPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border  = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Programming');

  // mock “Used in”
  final _usedIn = const ['Programming', 'Linear Algebra'];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // ⬅️ ใช้ hintText + label แยกด้านบน
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

  Widget _fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            text,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go('/admin/config/skills'), // ↩ กลับ Skill list
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
                decoration: _boxDeco(hint: "Enter skill name"),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              _fieldLabel("Used in"),
              const SizedBox(height: 8),
              ..._usedIn.map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text("• $s",
                        style: const TextStyle(color: Colors.black87)),
                  )),

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

  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saved (mock)')),
    );
    context.go('/admin/config/skills'); // กลับ Skill list
  }

  void _delete() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deleted (mock)')),
    );
    context.go('/admin/config/skills'); // กลับ Skill list
  }
}
