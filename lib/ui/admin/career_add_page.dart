import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'career_mock.dart';

class CareerAddPage extends StatefulWidget {
  const CareerAddPage({super.key});

  @override
  State<CareerAddPage> createState() => _CareerAddPageState();
}

class _CareerAddPageState extends State<CareerAddPage> {
  static const _primary = Color(0xFF3D5CFF);
  static const _border  = Color(0xFFEFF1F7);

  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String? _skillReq;

  final _skills = const [
    'Digital Communication',
    'Programming',
    'Calculus',
    'Math',
    'Data Analysis',
  ];

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  InputDecoration _deco() => InputDecoration(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
      );

  void _submit() {
    final ok = _form.currentState?.validate() ?? false;
    if (!ok || _skillReq == null) return;

    final c = Career(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _name.text.trim(),
      skillRequirement: _skillReq!,
    );
    CareerStore.upsert(c);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added (mock)')),
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
              const Text("Career name",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _name,
                decoration: _deco(),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              const Text("Skill Requirement",
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: _skillReq,
                decoration: _deco(),
                items: _skills
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _skillReq = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
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
                  child: const Text('Add'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
