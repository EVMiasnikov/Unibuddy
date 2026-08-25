import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
 
/// Controller: decides what the View should show.
/// It talks to the Service to get data, holds state,
/// and notifies the View whenever that state changes.
class AuthController extends ChangeNotifier {
  final AuthService _authService = AuthService();
 
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
      _currentUser = await _authService.login(email, password);
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
      _currentUser = await _authService.register(email, password);
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
 
  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }
}