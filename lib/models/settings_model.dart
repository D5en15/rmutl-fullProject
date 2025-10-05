class SettingsModel {
  final String? name;
  final String? email;
  final String? username;
  final String? role;
  final String? className;
  final String? userId;
  final String? avatarUrl;

  const SettingsModel({
    this.name,
    this.email,
    this.username,
    this.role,
    this.className,
    this.userId,
    this.avatarUrl,
  });

  factory SettingsModel.fromMap(Map<String, dynamic> data) {
    return SettingsModel(
      name: data['user_fullname'] as String?,
      email: data['user_email'] as String?,
      username: data['user_name'] as String?,
      role: data['user_role'] as String?,
      className: data['user_class'] as String?,
      userId: data['user_id']?.toString(),
      avatarUrl: data['user_img'] as String?,
    );
  }
}