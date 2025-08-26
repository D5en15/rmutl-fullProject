import 'package:flutter/foundation.dart';

enum UserRole { student, teacher, admin }

class AuthService extends ChangeNotifier {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  String? _email;
  UserRole? _role;

  String? get email => _email;
  UserRole? get role => _role;

  Future<void> signIn({
    required String email,
    required String password,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _email = email;
    _role = role;
    notifyListeners();
  }

  void signOut() {
    _email = null;
    _role = null;
    notifyListeners();
  }
}
