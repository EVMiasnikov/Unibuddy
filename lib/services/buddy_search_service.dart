import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class BuddySearchResult {
  final String id;
  final String fullName;
  final String? university;
  final String? city;
  final String? photoUrl;

  const BuddySearchResult({
    required this.id,
    required this.fullName,
    this.university,
    this.city,
    this.photoUrl,
  });
}

class BuddySearchService {
  static FirebaseFirestore _buildFirestore() {
    final db = FirebaseFirestore.instanceFor(
      app: Firebase.app(),
      databaseId: 'unibuddy',
    );

    if (kIsWeb) {
      db.settings = const Settings(
        webExperimentalForceLongPolling: true,
      );
    }

    return db;
  }

  final FirebaseFirestore _db =
      _buildFirestore();

  CollectionReference<Map<String, dynamic>>
      get _users =>
          _db.collection('users');

  Future<List<BuddySearchResult>>
      searchBuddies({
    required String query,
    required String city,
    required String currentUserId,
  }) async {
    final searchText =
        query.trim().toLowerCase();

    final targetCity =
        city.trim().toLowerCase();

    if (searchText.isEmpty) {
      return [];
    }

    final snapshot =
        await _users.get().timeout(
      const Duration(seconds: 10),
    );

    final results =
        <BuddySearchResult>[];

    for (final document
        in snapshot.docs) {
      if (document.id ==
          currentUserId) {
        continue;
      }

      final data = document.data();

      final name =
          (data['name'] ?? '')
              .toString()
              .trim();

      final surname =
          (data['surname'] ?? '')
              .toString()
              .trim();

      final fullName =
          '$name $surname'.trim();

      final userCity =
          (data['city'] ?? '')
              .toString()
              .trim();

      if (userCity.toLowerCase() !=
          targetCity) {
        continue;
      }

      if (!fullName
          .toLowerCase()
          .contains(searchText)) {
        continue;
      }

      results.add(
        BuddySearchResult(
          id: document.id,
          fullName:
              fullName.isNotEmpty
                  ? fullName
                  : 'User',
          university:
              data['university']
                  ?.toString(),
          city:
              data['city']
                  ?.toString(),
          photoUrl:
              data['photoUrl']
                  ?.toString(),
        ),
      );
    }

    results.sort(
      (a, b) => a.fullName
          .compareTo(b.fullName),
    );

    return results;
  }
}