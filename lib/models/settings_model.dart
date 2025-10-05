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

class EditProfileInitial {
  final String? username;
  final String? name;
  final String? email;
  final String? studentId;
  final String? className;
  final String? avatar;

  const EditProfileInitial({
    this.username,
    this.name,
    this.email,
    this.studentId,
    this.className,
    this.avatar,
  });

  factory EditProfileInitial.fromMap(Map<String, dynamic> map) {
    return EditProfileInitial(
      username: map['user_name'] as String?,
      name: map['user_fullname'] as String?,
      email: map['user_email'] as String?,
      studentId: map['user_code'] as String?,
      className: map['user_class'] as String?,
      avatar: map['user_img'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'user_name': username,
        'user_fullname': name,
        'user_email': email,
        'user_code': studentId,
        'user_class': className,
        'user_img': avatar,
      };
}