import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../services/user_service.dart';

class ProfileController extends ChangeNotifier {
  final UserService _userService = UserService();

  bool _isSaving = false;
  String? _errorMessage;

  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  /// Uploads the photo (if provided) then saves the full profile.
  /// Takes raw bytes instead of a dart:io File so this works on
  /// web too - the web has no filesystem, only in-memory bytes.
  Future<User?> saveProfile(User baseUser, {Uint8List? photoBytes}) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? photoUrl = baseUser.photoUrl;
      if (photoBytes != null) {
        photoUrl = await _userService
            .uploadProfilePhoto(baseUser.id, photoBytes)
            .timeout(const Duration(seconds: 15));
      }

      final updatedUser = baseUser.copyWith(photoUrl: photoUrl);
      await _userService.saveProfile(updatedUser).timeout(const Duration(seconds: 15));

      _isSaving = false;
      notifyListeners();
      return updatedUser;
    } on TimeoutException {
      _errorMessage = 'This is taking too long. Check your connection and try again.';
      _isSaving = false;
      notifyListeners();
      return null;
    } catch (e) {
      _errorMessage = 'Could not save your profile. Please try again.';
      _isSaving = false;
      notifyListeners();
      return null;
    }
  }
}
