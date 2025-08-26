import 'package:flutter/material.dart';
import '../common/page_template.dart';

class EditGradePage extends StatefulWidget {
  const EditGradePage({super.key});

  @override
  State<EditGradePage> createState() => _EditGradePageState();
}

class _EditGradePageState extends State<EditGradePage> {
  final _form = GlobalKey<FormState>();
  final code = TextEditingController();
  final name = TextEditingController();
  final score = TextEditingController();

  @override
  void dispose() {
    code.dispose();
    name.dispose();
    score.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Edit Grade',
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: code,
              decoration: const InputDecoration(labelText: 'Subject Code'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Subject Name'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: score,
              decoration: const InputDecoration(labelText: 'Score 0-100'),
              validator: _num,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _num(String? v) {
    if (v == null || v.trim().isEmpty) return 'Required';
    final x = double.tryParse(v);
    if (x == null || x < 0 || x > 100) return '0-100 only';
    return null;
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved (mock)')));
    Navigator.of(context).pop();
  }
}
