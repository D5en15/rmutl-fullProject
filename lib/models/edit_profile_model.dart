class EditProfileModel {
  final String? username;
  final String? name;
  final String? email;
  final String? studentId;
  final String? className;
  final String? avatarUrl;

  EditProfileModel({
    this.username,
    this.name,
    this.email,
    this.studentId,
    this.className,
    this.avatarUrl,
  });

  Map<String, dynamic> toMap() => {
        'user_name': username,
        'user_fullname': name,
        'user_email': email,
        'user_code': studentId,
        'user_class': className,
        'user_img': avatarUrl,
      };
}