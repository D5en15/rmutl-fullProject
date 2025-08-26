import 'package:flutter/material.dart';
import '../common/page_template.dart';

class CareerConfigPage extends StatefulWidget {
  const CareerConfigPage({super.key});
  @override
  State<CareerConfigPage> createState() => _CareerConfigPageState();
}

class _CareerConfigPageState extends State<CareerConfigPage> {
  final _form = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _min = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _min.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Career Config',
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Career Title'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _min,
              decoration: const InputDecoration(
                labelText: 'Min Average (0-100)',
              ),
              validator: _num,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _save, child: const Text('Add/Update')),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  String? _num(String? v) {
    final x = double.tryParse(v ?? '');
    if (x == null || x < 0 || x > 100) return '0-100 only';
    return null;
  }

  void _save() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Saved (mock)')));
    _title.clear();
    _min.clear();
  }
}
