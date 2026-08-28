import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/buddy_request.dart';

class RequestService {
  static final FirebaseFirestore _db = _buildFirestore();

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

  CollectionReference<Map<String, dynamic>> get _requests =>
      _db.collection('requests');

  // =========================================================
  // CREATE REQUEST
  // =========================================================

  Future<String> createRequest(BuddyRequest request) async {
    try {
      final document = await _requests
          .add(request.toMap())
          .timeout(const Duration(seconds: 10));

      return document.id;
    } on TimeoutException {
      throw Exception(
        'Firestore write timed out. Please check the network connection.',
      );
    } on FirebaseException {
      rethrow;
    }
  }
/// Load requests accepted by the current buddy.
/// Load all requests that have been accepted
/// by the current buddy.
Future<List<BuddyRequest>> getMyTasks(
  String buddyId,
) async {
  final snapshot = await _requests
      .where(
        'acceptedBuddyId',
        isEqualTo: buddyId,
      )
      .get()
      .timeout(const Duration(seconds: 10));

  final tasks = snapshot.docs
      .map(
        (document) => BuddyRequest.fromMap(
          document.id,
          document.data(),
        ),
      )
      .toList();

  // Help needed soonest appears first.
  tasks.sort(
  (a, b) => b.createdAt.compareTo(a.createdAt),
);

  return tasks;
}
  // =========================================================
  // MY REQUESTS
  // =========================================================

  Future<List<BuddyRequest>> getMyRequests(
    String requesterId,
  ) async {
    final snapshot = await _requests
        .where(
          'requesterId',
          isEqualTo: requesterId,
        )
        .get()
        .timeout(const Duration(seconds: 10));

    final requests = snapshot.docs.map((document) {
      return BuddyRequest.fromMap(
        document.id,
        document.data(),
      );
    }).toList();

    // Newest requests appear first.
    requests.sort(
      (a, b) => b.createdAt.compareTo(a.createdAt),
    );

    return requests;
  }

  // =========================================================
  // OFFERS
  // =========================================================

  Future<List<BuddyRequest>>
    getPublicRequests(
  String currentUserId,
  String? currentUserCity,
) async {
  if (currentUserCity == null ||
      currentUserCity
          .trim()
          .isEmpty) {
    return [];
  }

  final snapshot =
      await _requests
          .where(
            'status',
            isEqualTo:
                RequestStatus
                    .pending.name,
          )
          .get()
          .timeout(
            const Duration(
              seconds: 10,
            ),
          );

  final buddyCity =
      currentUserCity
          .trim()
          .toLowerCase();

  final requests =
      snapshot.docs
          .map(
            (document) =>
                BuddyRequest.fromMap(
              document.id,
              document.data(),
            ),
          )
          .where(
            (request) {
              // Cannot see your own requests.
              if (request.requesterId ==
                  currentUserId) {
                return false;
              }

              // City must match.
              if (request.city
                      .trim()
                      .toLowerCase() !=
                  buddyCity) {
                return false;
              }

              // Regular public request.
              if (request.targetBuddyId ==
                  null) {
                return true;
              }

              // Specific Buddy Request
              // Only the designated person can see it.
              return request
                      .targetBuddyId ==
                  currentUserId;
            },
          )
          .toList();

  // Offers keep the most urgent tasks first.
  requests.sort(
    (a, b) =>
        a.dateTime.compareTo(
      b.dateTime,
    ),
  );

  return requests;
}

  Future<void> acceptRequest({
    required String requestId,
    required String buddyId,
  }) async {
    final requestReference =
        _requests.doc(requestId);

    try {
      await _db
          .runTransaction((transaction) async {
            final snapshot =
                await transaction.get(
              requestReference,
            );

            final data = snapshot.data();

            if (!snapshot.exists ||
                data == null) {
              throw Exception(
                'This request no longer exists.',
              );
            }

            // Cannot accept your own request.
            if (data['requesterId'] ==
                buddyId) {
              throw Exception(
                'You cannot accept your own request.',
              );
            }

            // Prevent two buddies from claiming the same request at the same time.
            if (data['status'] !=
                RequestStatus.pending.name) {
              throw Exception(
                'This request has already been accepted.',
              );
            }

            final targetBuddyId =
                data['targetBuddyId']
                    as String?;

            // Will be used later when specified buddies are added.
            if (targetBuddyId != null &&
                targetBuddyId != buddyId) {
              throw Exception(
                'This request is intended for another buddy.',
              );
            }

            transaction.update(
              requestReference,
              {
                'acceptedBuddyId':
                    buddyId,
                'status':
                    RequestStatus
                        .accepted.name,
              },
            );
          })
          .timeout(
            const Duration(seconds: 10),
          );
    } on TimeoutException {
      throw Exception(
        'Accepting the request timed out.',
      );
    } on FirebaseException {
      rethrow;
    }
  }
  // =========================================================
// DELETE PENDING REQUEST
// =========================================================

Future<void> deleteRequest(
  String requestId,
) async {
  final reference = _requests.doc(requestId);

  await _db.runTransaction(
    (transaction) async {
      final snapshot =
          await transaction.get(reference);

      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw Exception(
          'This request no longer exists.',
        );
      }

      if (data['status'] !=
          RequestStatus.pending.name) {
        throw Exception(
          'Only pending requests can be deleted.',
        );
      }

      transaction.delete(reference);
    },
  ).timeout(
    const Duration(seconds: 10),
  );
}


// =========================================================
// CANCEL ACCEPTED REQUEST
// =========================================================

Future<void> cancelRequest(
  String requestId,
) async {
  final reference = _requests.doc(requestId);

  await _db.runTransaction(
    (transaction) async {
      final snapshot =
          await transaction.get(reference);

      final data = snapshot.data();

      if (!snapshot.exists || data == null) {
        throw Exception(
          'This request no longer exists.',
        );
      }

      if (data['status'] !=
          RequestStatus.accepted.name) {
        throw Exception(
          'Only accepted requests can be cancelled.',
        );
      }

      transaction.update(
        reference,
        {
          'status':
              RequestStatus.cancelled.name,
        },
      );
    },
  ).timeout(
    const Duration(seconds: 10),
  );
}
}