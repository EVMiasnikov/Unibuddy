import 'package:cloud_firestore/cloud_firestore.dart';

/// What kind of help the student needs.
///
/// One request can contain only ONE help type.
/// If the user needs multiple types of help,
/// they should create multiple requests.
enum HelpType {
  stationGuidance,
  campusGuidance,
  publicTransport,
  universityRegistration,
  emergencyOneNightSupport,
  other,
}

/// Human-readable text shown in the UI.
extension HelpTypeLabel on HelpType {
  String get label {
    switch (this) {
      case HelpType.stationGuidance:
        return 'Station guidance';
      case HelpType.campusGuidance:
        return 'Campus guidance';
      case HelpType.publicTransport:
        return 'Public transport';
      case HelpType.universityRegistration:
        return 'University registration';
      case HelpType.emergencyOneNightSupport:
        return 'Emergency one-night support';
      case HelpType.other:
        return 'Other';
    }
  }
}

/// Current state of a request.
enum RequestStatus { pending, accepted, completed, cancelled }

/// A real help request created by an exchange student.
class BuddyRequest {
  /// Firestore document ID.
  /// It can be null before the request is uploaded.
  final String? id;

  /// User who created the request.
  final String requesterId;
  final String requesterName;

  /// What kind of help is needed.
  final HelpType helpType;

  /// Only used when helpType == HelpType.other.
  final String? customHelp;

  /// Optional extra information.
  final String? note;

  /// Where the help is needed.
  final String country;
  final String city;

  /// When the help is needed.
  final DateTime dateTime;

  /// Optional:
  /// null = visible to all buddies.
  /// not null = request is aimed at one specific buddy.
  final String? targetBuddyId;

  /// The buddy who finally accepts the request.
  final String? acceptedBuddyId;

  /// pending / accepted / completed
  final RequestStatus status;

  /// When this request was created.
  final DateTime createdAt;

  /// Feedback left by the requester after completion.
  final int? requesterRating;
  final String? requesterFeedback;

  /// Feedback left by the buddy after completion.
  final int? buddyRating;
  final String? buddyFeedback;

  const BuddyRequest({
    this.id,
    required this.requesterId,
    required this.requesterName,
    required this.helpType,
    this.customHelp,
    this.note,
    required this.country,
    required this.city,
    required this.dateTime,
    this.targetBuddyId,
    this.acceptedBuddyId,
    required this.status,
    required this.createdAt,
    this.requesterRating,
    this.requesterFeedback,
    this.buddyRating,
    this.buddyFeedback,
  });
  Map<String, dynamic> toMap() {
    return {
      'requesterId': requesterId,
      'requesterName': requesterName,
      'helpType': helpType.name,
      'customHelp': customHelp,
      'note': note,
      'country': country,
      'city': city,
      'dateTime': dateTime,
      'targetBuddyId': targetBuddyId,
      'acceptedBuddyId': acceptedBuddyId,
      'status': status.name,
      'createdAt': createdAt,
      'requesterRating': requesterRating,
      'requesterFeedback': requesterFeedback,
      'buddyRating': buddyRating,
      'buddyFeedback': buddyFeedback,
    };
  }

  factory BuddyRequest.fromMap(String id, Map<String, dynamic> map) {
    return BuddyRequest(
      id: id,
      requesterId: map['requesterId'] as String,
      requesterName: map['requesterName'] as String,
      helpType: HelpType.values.byName(map['helpType'] as String),
      customHelp: map['customHelp'] as String?,
      note: map['note'] as String?,
      country: map['country'] as String,
      city: map['city'] as String,
      dateTime: (map['dateTime'] as Timestamp).toDate(),
      targetBuddyId: map['targetBuddyId'] as String?,
      acceptedBuddyId: map['acceptedBuddyId'] as String?,
      status: RequestStatus.values.byName(map['status'] as String),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      requesterRating: map['requesterRating'] as int?,
      requesterFeedback: map['requesterFeedback'] as String?,
      buddyRating: map['buddyRating'] as int?,
      buddyFeedback: map['buddyFeedback'] as String?,
    );
  }
}
