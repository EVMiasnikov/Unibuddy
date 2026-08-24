import '../models/user.dart';

/// Handles the raw "getting data" work for authentication.
/// Right now it's a placeholder - later this is where you'd call
/// your real backend (Firebase Auth, REST API, etc).
class AuthService {
  Future<User> login(String email, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // TODO: replace with a real API/auth call
    return User(
      id: '1',
      name: 'Placeholder User',
      email: email,
    );
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 300));
    // TODO: clear tokens/session
  }
}