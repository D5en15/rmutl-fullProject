import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../models/settings_model.dart';
import '../../models/edit_profile_initial.dart';
import '../../services/settings_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/setting_title.dart';
import '../../widgets/avatar_widget.dart';
import '../../widgets/app_toast.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _service = SettingsService();
  SettingsModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _service.loadUserData();
      setState(() {
        _user = user;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      AppToast.error(context, "Failed to load user data: $e");
    }
  }

  Future<void> _resetPassword() async {
    final email = _user?.email;
    if (email == null || email.isEmpty) {
      AppToast.error(context, "No email found for this account.");
      return;
    }

    try {
      await _service.sendResetEmail(email);
      AppToast.success(context, "Password reset link sent to $email");
    } catch (e) {
      AppToast.error(context, "Failed to send reset link: $e");
    }
  }

  Future<void> _logout() async {
    try {
      await _service.logout();
      AppToast.info(context, "You have been logged out successfully.");
      if (mounted) context.go('/login');
    } catch (e) {
      AppToast.error(context, "Logout failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✅ Header “Account”
                    const Text(
                      "Account",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ✅ Profile section
                    if (user != null)
                      Center(
                        child: Column(
                          children: [
                            AvatarWidget(imageUrl: user.avatarUrl),
                            const SizedBox(height: 12),
                            Text(
                              user.name ?? "User",
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (user.email != null)
                              Text(
                                user.email!,
                                style: TextStyle(
                                  color: cs.onSurface.withOpacity(0.6),
                                ),
                              ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                    // ✅ Menu list
                    Expanded(
                      child: ListView(
                        children: [
                          SettingTile(
                            icon: Icons.edit_outlined,
                            title: 'Edit Account',
                            subtitle: 'Update your personal information',
                            onTap: () => context.push(
                              '/profile/edit',
                              extra: {
                                'role': user?.role ?? 'Student',
                                'initial': EditProfileInitial(
                                  username: user?.username,
                                  name: user?.name,
                                  email: user?.email,
                                  studentId: user?.userId,
                                  className: user?.className,
                                  avatar: user?.avatarUrl,
                                ),
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          SettingTile(
                            icon: Icons.lock_reset_outlined,
                            title: 'Change Password',
                            subtitle: 'Send reset link to your email',
                            onTap: _resetPassword,
                          ),
                          const SizedBox(height: 24),
                          CustomButton(
                            text: "Logout",
                            loading: false,
                            color: cs.error,
                            onPressed: _logout,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}