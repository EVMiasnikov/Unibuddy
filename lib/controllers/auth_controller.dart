import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';

/// Controller: decides what the View should show.
/// It talks to the Services to get data, holds state,
/// and notifies the View whenever that state changes.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();

  User? _currentUser;
  bool _isLoading = false;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _currentUser != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authUser = await _authService.login(email, password);
      _currentUser = await _mergeWithProfile(authUser);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final authUser = await _authService.register(email, password);
      // Brand new account - no profile document yet, that's expected.
      _currentUser = authUser;
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Called by ProfileSetupScreen once the profile has been saved,
  /// so the rest of the app immediately sees the completed profile.
  void setCurrentUser(User user) {
    _currentUser = user;
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  /// After identity login, fetch the extra profile fields (if any)
  /// and merge them onto the basic auth user.
  Future<User> _mergeWithProfile(User authUser) async {
    final profile = await _userService.getProfile(authUser.id, authUser.email);
    return profile ?? authUser;
  }
}