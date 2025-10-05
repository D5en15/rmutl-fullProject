import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/edit_profile_model.dart';
import '../../services/edit_profile_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/app_toast.dart';

class EditProfilePage extends StatefulWidget {
  final String role;
  final EditProfileModel? initial;

  const EditProfilePage({
    super.key,
    required this.role,
    this.initial,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _service = EditProfileService();
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();
  final _fullname = TextEditingController();
  final _email = TextEditingController();
  final _studentId = TextEditingController();

  String? _classValue;
  String? _avatarUrl;
  bool _loading = false;
  String? _docId;

  final List<String> _classes = ['SE-3/1', 'SE-3/2', 'SE-4/1'];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _loading = true);
    try {
      final data = await _service.loadProfile();
      if (data == null) return;

      setState(() {
        _username.text = data['user_name'] ?? '';
        _fullname.text = data['user_fullname'] ?? '';
        _email.text = data['user_email'] ?? '';
        _studentId.text = data['user_code'] ?? '';
        _classValue = data['user_class'];
        _avatarUrl = data['user_img'];
        _docId = data['id'] ?? data['docId'];
      });
    } catch (e) {
      AppToast.error(context, 'Failed to load profile: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final url = await _service.pickAndUploadAvatar();
      if (url == null) return;
      setState(() => _avatarUrl = url);
      AppToast.success(context, "Profile picture updated successfully!");
    } catch (e) {
      AppToast.error(context, "Upload failed: $e");
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_docId == null) return AppToast.error(context, "Missing user document.");

    final data = {
      'user_name': _username.text.trim(),
      'user_fullname': _fullname.text.trim(),
      'user_code': _studentId.text.trim(),
      'user_class': _classValue,
      'user_img': _avatarUrl,
    };

    try {
      await _service.updateProfile(_docId!, data);
      AppToast.success(context, "Profile updated successfully!");
      if (mounted) context.pop();
    } catch (e) {
      AppToast.error(context, "Failed to update profile: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role.toLowerCase() == 'student';

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // ✅ Header
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => context.pop(),
                            icon: const Icon(Icons.arrow_back_ios_new_rounded),
                          ),
                          const Text(
                            "Edit Profile",
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ✅ Avatar Widget — รองรับได้ทั้ง mobile/web
                      GestureDetector(
                        onTap: _pickAvatar,
                        child: AvatarWidget(
                          imageUrl: _avatarUrl,
                          radius: 45,
                        ),
                      ),

                      const SizedBox(height: 24),

                      CustomInput(controller: _username, label: "Username"),
                      const SizedBox(height: 16),
                      CustomInput(controller: _fullname, label: "Full Name"),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: _email,
                        label: "Email",
                        readOnly: true, // ✅ ใช้ชื่อจริงใน custom_input
                      ),
                      const SizedBox(height: 16),

                      if (isStudent) ...[
                        CustomInput(
                            controller: _studentId, label: "Student ID"),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _classValue,
                          items: _classes
                              .map((c) =>
                                  DropdownMenuItem(value: c, child: Text(c)))
                              .toList(),
                          decoration: const InputDecoration(
                            labelText: "Class",
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          onChanged: (v) => setState(() => _classValue = v),
                        ),
                        const SizedBox(height: 24),
                      ],

                      CustomButton(
                        text: "Save Changes",
                        loading: _loading,
                        onPressed: _saveProfile,
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}