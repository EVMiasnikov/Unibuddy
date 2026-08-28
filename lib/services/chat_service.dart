import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/buddy_request.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';

class ChatService {
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
        webExperimentalForceLongPolling:
            true,
      );
    }

    return db;
  }

  CollectionReference<
      Map<String, dynamic>> get _chats =>
      _db.collection('chats');

  // =========================================================
  // CREATE CHAT
  // =========================================================

  /// Make sure one accepted Request has exactly one Chat.
  Future<void> createConversation({
    required BuddyRequest request,
    required String buddyId,
    required String buddyName,
  }) async {
    if (request.id == null) {
      throw Exception(
        'Cannot create a chat without a request ID.',
      );
    }

    final chatId = request.id!;

    final chatReference =
        _chats.doc(chatId);

    final conversation =
        ChatConversation(
      id: chatId,

      requestId: chatId,

      requesterId:
          request.requesterId,

      requesterName:
          request.requesterName,

      buddyId: buddyId,

      buddyName: buddyName,

      helpType:
          request.helpType,

      requestDateTime:
          request.dateTime,

      createdAt:
          DateTime.now(),
    );

    try {
      await _db
          .runTransaction(
        (transaction) async {
          final existing =
              await transaction.get(
            chatReference,
          );

          // If it already exists, do nothing.
          // This ensures a request does not create two chats.
          if (existing.exists) {
            return;
          }

          transaction.set(
            chatReference,
            conversation.toMap(),
          );
        },
      ).timeout(
        const Duration(seconds: 10),
      );
    } on TimeoutException {
      throw Exception(
        'Creating the chat timed out.',
      );
    }
  }

  // =========================================================
  // MY CHATS
  // =========================================================

  /// Real-time list of conversations
  /// involving the current user.
  Stream<List<ChatConversation>>
      watchMyConversations(
    String userId,
  ) {
    return _chats
        .where(
          'participants',
          arrayContains: userId,
        )
        .snapshots()
        .map(
      (snapshot) {
        final conversations =
            snapshot.docs.map(
          (document) {
            return ChatConversation
                .fromMap(
              document.id,
              document.data(),
            );
          },
        ).toList();

        // Move chats with recent messages to the front.
        // If there are no messages, sort by chat creation time.
        conversations.sort(
          (a, b) {
            final aTime =
                a.lastMessageAt ??
                    a.createdAt;

            final bTime =
                b.lastMessageAt ??
                    b.createdAt;

            return bTime.compareTo(aTime);
          },
        );

        return conversations;
      },
    );
  }

  // =========================================================
  // MESSAGES
  // =========================================================

  /// Listen to all messages in one chat in real time.
  Stream<List<ChatMessage>>
      watchMessages(
    String chatId,
  ) {
    return _chats
        .doc(chatId)
        .collection('messages')
        .orderBy(
          'sentAt',
          descending: false,
        )
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map(
          (document) {
            return ChatMessage.fromMap(
              document.id,
              document.data(),
            );
          },
        ).toList();
      },
    );
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    final cleanText = text.trim();

    if (cleanText.isEmpty) {
      return;
    }

    final now = DateTime.now();

    final chatReference =
        _chats.doc(chatId);

    final messageReference =
        chatReference
            .collection('messages')
            .doc();

    final message =
        ChatMessage(
      id: messageReference.id,
      senderId: senderId,
      text: cleanText,
      sentAt: now,
    );

    final batch = _db.batch();

    // Save the actual message.
    batch.set(
      messageReference,
      message.toMap(),
    );

    // Also update the last message in the chat list.
    batch.update(
      chatReference,
      {
        'lastMessage': cleanText,
        'lastMessageAt': now,
      },
    );

    try {
      await batch
          .commit()
          .timeout(
            const Duration(seconds: 10),
          );
    } on TimeoutException {
      throw Exception(
        'Sending the message timed out.',
      );
    }
  }
}