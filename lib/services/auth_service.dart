import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(String input, String password) async {
    try {
      // 🟦 Check if input is email or username
      String email = input;
      if (!input.contains('@')) {
        final snap = await _db
            .collection('user')
            .where('user_name', isEqualTo: input)
            .limit(1)
            .get();
        if (snap.docs.isEmpty) throw AuthException('User account not found.');
        email = snap.docs.first['user_email'];
      }

      // 🟩 Firebase Auth login
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw AuthException('Unable to sign in.');

      // 🟨 Get user role from Firestore
      final snap = await _db
          .collection('user')
          .where('user_email', isEqualTo: email)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) throw AuthException('User not found in database.');

      final role = snap.docs.first['user_role'] ?? 'student';
      return {'email': email, 'role': role};
    } on FirebaseAuthException catch (e) {
      // 🟥 Handle common FirebaseAuth errors in user-friendly English
      String msg;
      switch (e.code) {
        case 'user-not-found':
          msg = 'No account found. Please check your email or username.';
          break;
        case 'wrong-password':
          msg = 'Incorrect password. Please try again.';
          break;
        case 'invalid-email':
          msg = 'Invalid email format.';
          break;
        case 'too-many-requests':
          msg = 'Too many attempts. Please try again later.';
          break;
        default:
          msg = 'Login failed. Please try again.';
      }
      throw AuthException(msg);
    } catch (_) {
      throw AuthException('Incorrect information. Please try again.');
    }
  }
}

/// ✅ Custom Auth Exception for controlled error messages
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}