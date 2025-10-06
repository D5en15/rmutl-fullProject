import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/edit_profile_initial.dart';
import '../../services/edit_profile_service.dart';
import '../../widgets/custom_input.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/app_toast.dart';

class EditProfilePage extends StatefulWidget {
  final String role;
  final EditProfileInitial? initial;

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

  Future<void> _pickAvatar(BuildContext context) async {
    try {
      final url = await _service.pickAndUploadAvatar(context);
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
      body: Stack(
        children: [
          // 🔹 พื้นหลังสีน้ำเงิน
          Container(
            height: 130,
            width: double.infinity,
            color: const Color(0xFF1E63E9),
          ),

          // 🔹 เนื้อหาหลักทั้งหมด
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  // ✅ รูปโปรไฟล์ + ปุ่มแก้ไข
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      GestureDetector(
                        onTap: () => _pickAvatar(context),
                        child: AvatarWidget(
                          imageUrl: _avatarUrl,
                          radius: 55,
                        ),
                      ),
                      Positioned(
                        bottom: 2,
                        right: 2,
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.edit,
                                size: 20, color: Colors.blueAccent),
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                            onPressed: () => _pickAvatar(context),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 🔹 ฟอร์มโปรไฟล์
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomInput(controller: _username, label: "Username"),
                        const SizedBox(height: 16),
                        CustomInput(controller: _fullname, label: "Full Name"),
                        const SizedBox(height: 16),
                        CustomInput(
                          controller: _email,
                          label: "Email",
                          readOnly: true,
                        ),
                        const SizedBox(height: 16),

                        if (isStudent) ...[
                          CustomInput(
                              controller: _studentId, label: "Student ID"),
                          const SizedBox(height: 16),

                          // 🔹 Label Class ด้านนอก
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Class",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 🔹 กล่อง Dropdown ใช้สไตล์เดียวกับ CustomInput
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.black54, // ✅ สีเข้มเหมือนช่องอื่น
                                width: 1.3,
                              ),
                              borderRadius:
                                  const BorderRadius.all(Radius.circular(12)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _classValue,
                                isExpanded: true,
                                items: _classes
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _classValue = v),
                                hint: const Text("Select Class"),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        CustomButton(
                          text: "Save Changes",
                          loading: _loading,
                          onPressed: _saveProfile,
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🔹 ปุ่ม Back (แยก SafeArea ชั้นบนสุด — ไม่ถูก Stack บัง)
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: Material(
                color: Colors.transparent,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}