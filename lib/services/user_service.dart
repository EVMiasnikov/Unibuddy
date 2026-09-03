import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/user.dart';

/// Handles the raw "getting/storing data" work for user profiles.
/// AuthService deals with identity (email/password/uid).
/// UserService deals with everything else about the user.
class UserService {
  // FirebaseFirestore.instance always points at the "(default)" database.
  // This project's Firestore database is named "unibuddy", not "(default)",
  // so we must explicitly target it - otherwise every request goes to a
  // database that doesn't exist and just hangs/retries forever.
  static final FirebaseFirestore _db = _buildFirestore();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  static FirebaseFirestore _buildFirestore() {
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'unibuddy',
    );
    if (kIsWeb) {
      // Some networks/proxies/antivirus interfere with Firestore's default
      // streaming transport on web - long-polling avoids that.
      db.settings = const Settings(webExperimentalForceLongPolling: true);
    }
    return db;
  }

  /// Fetches the extra profile fields for a given uid.
  /// Returns null if no profile document exists yet
  /// (e.g. user registered but never finished profile setup).
  Future<User?> getProfile(String uid, String email) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return User.fromMap(uid, doc.data()!);
  }
  /// Fetch user profile only by uid.
Future<User?> getUserById(String uid) async {
  final doc =
      await _db.collection('users').doc(uid).get();

  if (!doc.exists || doc.data() == null) {
    return null;
  }

  return User.fromMap(
    uid,
    doc.data()!,
  );
}

  /// Saves/overwrites the profile document for this user.
  Future<void> saveProfile(User user) async {
    await _db.collection('users').doc(user.id).set(
          user.toMap(),
          SetOptions(merge: true),
        );
  }

  /// Uploads a profile photo from raw bytes and returns its download URL.
  /// Using bytes (rather than a dart:io File) works on web, mobile, and desktop alike.
  Future<String> uploadProfilePhoto(String uid, Uint8List photoBytes) async {
    final ref = _storage.ref().child('profile_photos').child('$uid.jpg');
    await ref.putData(photoBytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  /// Finds other students in [city] who currently have their
  /// "accepting buddy requests" status turned on.
  /// Used both for the main-screen "available buddies" bar and
  /// (should be) anywhere else a specific buddy can be picked.
  Future<List<User>> getAvailableBuddies(
    String city, {
    String? excludeUserId,
    int limit = 20,
  }) async {
    final snapshot = await _db
        .collection('users')
        .where('isAcceptingBuddyRequests', isEqualTo: true)
        .where('city', isEqualTo: city)
        .limit(limit)
        .get();

    return snapshot.docs
        .where((doc) => doc.id != excludeUserId)
        .map((doc) => User.fromMap(doc.id, doc.data()))
        .toList();
  }
}
