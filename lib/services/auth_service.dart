import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>> login(String input, String password) async {
    try {
      // 🟦 Check if input is email or username
      String email = input;
      Map<String, dynamic>? userData;
      if (!input.contains('@')) {
        var snap = await _db
            .collection('user')
            .where('user_id', isEqualTo: input)
            .limit(1)
            .get();

        if (snap.docs.isEmpty) {
          snap = await _db
              .collection('user')
              .where('user_name', isEqualTo: input)
              .limit(1)
              .get();
        }

        if (snap.docs.isEmpty) throw AuthException('User account not found.');
        userData = snap.docs.first.data();
        email = userData['user_email'];
      }

      // 🟩 Firebase Auth login
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = cred.user;
      if (user == null) throw AuthException('Unable to sign in.');

      // 🟨 Get user role from Firestore
      userData ??= await _fetchUserByEmail(email);
      final role = (userData['user_role'] ?? 'student').toString();
      return {
        'email': email,
        'role': role,
        'userId': userData['user_id'],
      };
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

  Future<Map<String, dynamic>?> getCurrentUserWithRole() async {
    try {
      final current = _auth.currentUser;
      if (current == null) return null;

      Map<String, dynamic>? data;
      final doc = await _db.collection('user').doc(current.uid).get();
      if (doc.exists) {
        data = doc.data();
      } else if (current.email != null) {
        final snap = await _db
            .collection('user')
            .where('user_email', isEqualTo: current.email)
            .limit(1)
            .get();
        if (snap.docs.isNotEmpty) data = snap.docs.first.data();
      }

      if (data == null) return null;
      return {
        'email': data['user_email'] ?? current.email,
        'role': (data['user_role'] ?? 'student').toString(),
        'userId': data['user_id'],
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> _fetchUserByEmail(String email) async {
    final snap = await _db
        .collection('user')
        .where('user_email', isEqualTo: email)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) {
      throw AuthException('User not found in database.');
    }
    return snap.docs.first.data();
  }
}

/// ✅ Custom Auth Exception for controlled error messages
class AuthException implements Exception {
  final String message;
  AuthException(this.message);

  @override
  String toString() => message;
}
