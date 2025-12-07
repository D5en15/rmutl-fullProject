// lib/ui/common/edit_profile_page.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:cloud_firestore/cloud_firestore.dart'; // <- ไม่ได้ใช้ เลยลบออกได้
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
  bool _pickingAvatar = false;
  bool _loading = false;
  String? _docId;

  String? _computedYearValue;
  String? _computedYearLabel;

  @override
  void initState() {
    super.initState();
    _studentId.addListener(_handleStudentIdChange);
    _loadUserData();
  }

  @override
  void dispose() {
    _username.dispose();
    _fullname.dispose();
    _email.dispose();
    _studentId.removeListener(_handleStudentIdChange);
    _studentId.dispose();
    super.dispose();
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
        _updateYearFromId();
      });
    } catch (e) {
      AppToast.error(context, 'Failed to load profile: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickAvatar(BuildContext context) async {
    if (_pickingAvatar) return;
    setState(() => _pickingAvatar = true);
    try {
      final url = await _service.pickAndUploadAvatar(context);
      if (url != null) {
        setState(() => _avatarUrl = url);
        AppToast.success(context, "Profile picture updated successfully!");
      }
    } catch (e) {
      AppToast.error(context, "Upload failed: $e");
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_docId == null) {
      AppToast.error(context, "Missing user document.");
      return;
    }

    final isStudent = widget.role.toLowerCase() == 'student';

    final data = <String, dynamic>{
      'user_fullname': _fullname.text.trim(),
      'user_class': isStudent ? _computedYearValue : _classValue,
      'user_img': _avatarUrl,
    };

    if (isStudent) {
      data['user_code'] = _studentId.text.trim();
    } else {
      data['user_name'] = _username.text.trim();
    }

    try {
      await _service.updateProfile(_docId!, data);
      AppToast.success(context, "Profile updated successfully!");
      if (mounted) context.pop();
    } catch (e) {
      AppToast.error(context, "Failed to update profile: $e");
    }
  }

  void _handleStudentIdChange() {
    _updateYearFromId();
  }

  void _updateYearFromId() {
    if (widget.role.toLowerCase() != 'student') return;
    final id = _studentId.text.trim();
    if (id.length >= 2) {
      final prefix = id.substring(0, 2);
      setState(() {
        _computedYearValue = prefix;
        _computedYearLabel = "Year $prefix";
      });
    } else {
      setState(() {
        _computedYearValue = null;
        _computedYearLabel = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStudent = widget.role.toLowerCase() == 'student';
    final statusBar = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeroSection(statusBar),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (!isStudent) ...[
                        CustomInput(
                          controller: _username,
                          label: "Username",
                        ),
                        const SizedBox(height: 16),
                      ],
                      CustomInput(
                        controller: _fullname,
                        label: "Full Name",
                      ),
                      const SizedBox(height: 16),
                      CustomInput(
                        controller: _email,
                        label: "Email",
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),
                      if (isStudent) ...[
                        CustomInput(
                          controller: _studentId,
                          label: "Student ID",
                        ),
                        const SizedBox(height: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Class year",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                              child: Text(
                                _computedYearLabel ?? "Enter ID to detect.",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _computedYearLabel != null
                                      ? Colors.black87
                                      : Colors.grey,
                                ),
                              ),
                            ),
                          ],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection(double statusBar) {
    const double heroHeight = 170;
    const double avatarSize = 128;

    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: heroHeight + statusBar,
              width: double.infinity,
              color: const Color(0xFF1E63E9),
            ),
            Positioned(
              top: statusBar + 8,
              left: 8,
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
            Positioned(
              bottom: -avatarSize / 2,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _pickingAvatar ? null : () => _pickAvatar(context),
                  child: Container(
                    width: avatarSize,
                    height: avatarSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 5,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 14,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: AvatarWidget(
                        imageUrl: _avatarUrl,
                        radius: avatarSize / 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 25),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            foregroundColor: Colors.black,
            backgroundColor: Colors.white,
            side: const BorderSide(color: Colors.black),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          ),
          onPressed: _pickingAvatar ? null : () => _pickAvatar(context),
          child: const Text(
            "Edit profile",
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
