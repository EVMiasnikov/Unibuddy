import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

/// Holds the list of buddies currently available in a given city -
/// used by the main-screen "available buddies" bar.
class BuddyDirectoryController extends ChangeNotifier {
  final UserService _userService = UserService();

  List<User> _buddies = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<User> get buddies => _buddies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadAvailableBuddies(String city, {String? excludeUserId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _buddies = await _userService
          .getAvailableBuddies(city, excludeUserId: excludeUserId)
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      _errorMessage = 'Could not reach the server.';
    } catch (e) {
      _errorMessage = 'Could not load available buddies.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
