import 'package:cloud_firestore/cloud_firestore.dart';

import 'buddy_request.dart';

class ChatConversation {
  final String id;

  final String requestId;

  final String requesterId;
  final String requesterName;

  final String buddyId;
  final String buddyName;

  final HelpType helpType;

  final DateTime requestDateTime;

  final String? lastMessage;
  final DateTime? lastMessageAt;

  final DateTime createdAt;

  const ChatConversation({
    required this.id,
    required this.requestId,
    required this.requesterId,
    required this.requesterName,
    required this.buddyId,
    required this.buddyName,
    required this.helpType,
    required this.requestDateTime,
    this.lastMessage,
    this.lastMessageAt,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'requestId': requestId,

      'requesterId': requesterId,
      'requesterName': requesterName,

      'buddyId': buddyId,
      'buddyName': buddyName,

      // Used for querying:
      // Which chats the current user is participating in.
      'participants': [
        requesterId,
        buddyId,
      ],

      'helpType': helpType.name,

      'requestDateTime': requestDateTime,

      'lastMessage': lastMessage,
      'lastMessageAt': lastMessageAt,

      'createdAt': createdAt,
    };
  }

  factory ChatConversation.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ChatConversation(
      id: id,

      requestId: map['requestId'] as String,

      requesterId:
          map['requesterId'] as String,

      requesterName:
          map['requesterName'] as String,

      buddyId:
          map['buddyId'] as String,

      buddyName:
          map['buddyName'] as String,

      helpType:
          HelpType.values.byName(
        map['helpType'] as String,
      ),

      requestDateTime:
          (map['requestDateTime']
                  as Timestamp)
              .toDate(),

      lastMessage:
          map['lastMessage'] as String?,

      lastMessageAt:
          (map['lastMessageAt']
                  as Timestamp?)
              ?.toDate(),

      createdAt:
          (map['createdAt']
                  as Timestamp)
              .toDate(),
    );
  }
}