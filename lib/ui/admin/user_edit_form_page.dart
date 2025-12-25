import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  final _userIdCtrl = TextEditingController();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  String _role = 'Student';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _email.text = widget.email;
    _loadUser();
  }

  @override
  void dispose() {
    _userIdCtrl.dispose();
    _fullName.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          _userIdCtrl.text = (data['user_id'] ?? '').toString();
          _fullName.text = (data['user_fullname'] ?? '').toString();
          if ((data['user_email'] ?? '').toString().isNotEmpty) {
            _email.text = (data['user_email'] ?? '').toString();
          }
          _role = (data['user_role'] ?? 'Student').toString();
          _avatarUrl = (data['user_img'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint('Error loading user: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load user: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .update({
        'user_id': _userIdCtrl.text.trim(),
        'user_fullname': _fullName.text.trim(),
        'user_email': _email.text.trim(),
        'user_role': _role,
        'user_img': _avatarUrl ?? '',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e')),
        );
      }
    }
  }

  Future<void> _confirmAndDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete user'),
        content: const Text('This action cannot be undone. Delete this user?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await FirebaseFirestore.instance
          .collection('user')
          .doc(widget.userId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User deleted')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: $e')),
        );
      }
    }
  }

  void _pickAvatar() async {
    final chosen = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select avatar'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 20,
            itemBuilder: (context, index) {
              final path = '${index + 1}.png';
              return GestureDetector(
                onTap: () => Navigator.pop(ctx, path),
                child: CircleAvatar(
                  backgroundImage: AssetImage('assets/avatars/$path'),
                  radius: 30,
                ),
              );
            },
          ),
        ),
      ),
    );

    if (chosen != null) {
      setState(() => _avatarUrl = chosen);
    }
  }

  InputDecoration _decoration(String label, {bool readOnly = false}) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE5E7F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit user',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: _confirmAndDelete,
            tooltip: 'Delete user',
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 44,
                        backgroundColor: const Color(0xFFE9ECFF),
                        backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                            ? (_avatarUrl!.startsWith('http')
                                ? NetworkImage(_avatarUrl!)
                                : AssetImage('assets/avatars/$_avatarUrl'))
                            : null as ImageProvider?,
                        child: (_avatarUrl == null || _avatarUrl!.isEmpty)
                            ? const Icon(Icons.person,
                                size: 36, color: Color(0xFF4B5563))
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, size: 18, color: _primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                TextFormField(
                  controller: _userIdCtrl,
                  decoration: _decoration('ID'),
                  validator: (v) => v == null || v.isEmpty ? 'ID is required' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _fullName,
                  decoration: _decoration('Full name'),
                  validator: (v) => v == null || v.isEmpty ? 'Full name is required' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _email,
                  readOnly: true,
                  decoration: _decoration('Email', readOnly: true),
                ),
                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: _decoration('User role'),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(value: 'Teacher', child: Text('Teacher')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? _role),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Save changes'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
