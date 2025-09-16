import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UserEditFormPage extends StatefulWidget {
  const UserEditFormPage({super.key, required this.userId, required this.email});
  final String userId;
  final String email;

  @override
  State<UserEditFormPage> createState() => _UserEditFormPageState();
}

class _UserEditFormPageState extends State<UserEditFormPage> {
  static const _primary = Color(0xFF3D5CFF);
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(text: 'Michael Brown');
  final _email = TextEditingController();
  final _phone = TextEditingController(text: '+1 234 567 890');
  final _uid = TextEditingController();
  String _role = 'Teacher';

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
    _uid.text = widget.userId;
  }

  @override
  void dispose() {
    _name.dispose(); _email.dispose(); _phone.dispose(); _uid.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Blue header + back
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 140, color: _primary,
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                    ),
                    const Center(
                      child: CircleAvatar(
                        radius: 34,
                        backgroundColor: Color(0xFFFFE3B5),
                        child: Icon(Icons.person, color: Colors.black54, size: 36),
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Form(
                  key: _form,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(labelText: 'Name'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(labelText: 'Email'),
                        validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        decoration: const InputDecoration(labelText: 'Phone number'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _uid,
                        decoration: const InputDecoration(labelText: 'User ID'),
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: 'Role'),
                        value: _role,
                        items: const ['Student', 'Teacher', 'Admin']
                            .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                            .toList(),
                        onChanged: (v) => setState(() => _role = v ?? _role),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 48, width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primary, foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Submit'),
                        ),
                      ),
                    ],
                  ),
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
    context.pop(); // กลับหน้าโปรไฟล์
  }
}
