import 'package:flutter/material.dart';
import '../common/page_template.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});
  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _form = GlobalKey<FormState>();
  final _target = TextEditingController();
  final _msg = TextEditingController();

  @override
  void dispose() {
    _target.dispose();
    _msg.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageTemplate(
      title: 'Feedback',
      child: Form(
        key: _form,
        child: Column(
          children: [
            TextFormField(
              controller: _target,
              decoration: const InputDecoration(labelText: 'Student ID'),
              validator: _req,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _msg,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Message'),
              validator: _req,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _submit, child: const Text('Send')),
          ],
        ),
      ),
    );
  }

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;
  void _submit() {
    if (!(_form.currentState?.validate() ?? false)) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Feedback sent (mock)')));
    _form.currentState?.reset();
    _target.clear();
    _msg.clear();
  }
}
