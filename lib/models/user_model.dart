class UserModel {
  final String userId;
  final String? userCode;
  final String userName;
  final String fullName;
  final String email;
  final String role;
  final String? userClass;
  final String? userImg;

  UserModel({
    required this.userId,
    required this.userName,
    required this.fullName,
    required this.email,
    required this.role,
    this.userCode,
    this.userClass,
    this.userImg,
  });

  Map<String, dynamic> toMap() => {
        'user_id': userId,
        'user_code': userCode,
        'user_name': userName,
        'user_fullname': fullName,
        'user_email': email,
        'user_role': role,
        'user_class': userClass,
        'user_img': userImg ?? '',
      };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
        userId: map['user_id'],
        userCode: map['user_code'],
        userName: map['user_name'],
        fullName: map['user_fullname'],
        email: map['user_email'],
        role: map['user_role'],
        userClass: map['user_class'],
        userImg: map['user_img'],
      );
}