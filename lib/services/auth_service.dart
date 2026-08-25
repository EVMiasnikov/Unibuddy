import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import '../models/user.dart';
 
/// Handles the raw "getting data" work for authentication.
/// Talks to Firebase Auth directly - the rest of the app never
/// touches FirebaseAuth itself, only this Service.
class AuthService {
  final fb_auth.FirebaseAuth _firebaseAuth = fb_auth.FirebaseAuth.instance;
 
  User _mapFirebaseUser(fb_auth.User firebaseUser) {
    return User(
      id: firebaseUser.uid,
      name: firebaseUser.displayName ?? 'No name set',
      email: firebaseUser.email ?? '',
    );
  }
 
  Future<User> login(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    }
  }
 
  Future<User> register(String email, String password) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _mapFirebaseUser(credential.user!);
    } on fb_auth.FirebaseAuthException catch (e) {
      throw Exception(_friendlyError(e.code));
    }
  }
 
  Future<void> logout() async {
    await _firebaseAuth.signOut();
  }
 
  /// Turns Firebase's error codes into messages you can show in the UI.
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found for that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'invalid-email':
        return 'That email address looks invalid.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}