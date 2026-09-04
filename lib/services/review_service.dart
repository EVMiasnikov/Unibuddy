import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/buddy_request.dart';
import '../models/profile_review.dart';

class ReviewService {
  static final FirebaseFirestore _db =
      _buildFirestore();

  static FirebaseFirestore _buildFirestore() {
    final db =
        FirebaseFirestore.instanceFor(
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

  CollectionReference<Map<String, dynamic>>
      get _requests =>
          _db.collection('requests');

  // =========================================================
  // GET ALL REVIEWS RECEIVED BY ONE USER
  // =========================================================

  Future<List<ProfileReview>>
      getReviewsForUser(
    String userId,
  ) async {
    final reviews = <ProfileReview>[];

    // ---------------------------------------------------------
    // Case 1:
    // This user was the REQUESTER.
    //
    // Buddy reviewed them, so use:
    // buddyRating / buddyFeedback
    // ---------------------------------------------------------

    final requesterSnapshot =
        await _requests
            .where(
              'requesterId',
              isEqualTo: userId,
            )
            .get();

    for (final document
        in requesterSnapshot.docs) {
      final request =
          BuddyRequest.fromMap(
        document.id,
        document.data(),
      );

      final rating =
          request.buddyRating;

      final reviewerId =
          request.acceptedBuddyId;

      if (rating != null &&
          reviewerId != null) {
        reviews.add(
          ProfileReview(
            requestId: document.id,
            reviewerId: reviewerId,
            rating: rating,
            comment:
                request.buddyFeedback ?? '',
            createdAt:
                request.buddyFeedbackAt,
          ),
        );
      }
    }

    // ---------------------------------------------------------
    // Case 2:
    // This user was the BUDDY.
    //
    // Requester reviewed them, so use:
    // requesterRating / requesterFeedback
    // ---------------------------------------------------------

    final buddySnapshot =
        await _requests
            .where(
              'acceptedBuddyId',
              isEqualTo: userId,
            )
            .get();

    for (final document
        in buddySnapshot.docs) {
      final request =
          BuddyRequest.fromMap(
        document.id,
        document.data(),
      );

      final rating =
          request.requesterRating;

      if (rating != null) {
        reviews.add(
          ProfileReview(
            requestId: document.id,
            reviewerId:
                request.requesterId,
            rating: rating,
            comment:
                request.requesterFeedback ??
                    '',
            createdAt:
                request.requesterFeedbackAt,
          ),
        );
      }
    }

    // Newest reviews first.
    reviews.sort((a, b) {
      final aDate = a.createdAt;
      final bDate = b.createdAt;

      if (aDate == null &&
          bDate == null) {
        return 0;
      }

      if (aDate == null) {
        return 1;
      }

      if (bDate == null) {
        return -1;
      }

      return bDate.compareTo(aDate);
    });

    return reviews;
  }
}