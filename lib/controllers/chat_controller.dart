import 'package:flutter/foundation.dart';

import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/chat_service.dart';

class ChatController extends ChangeNotifier {
  final ChatService _chatService;

  ChatController({
    ChatService? chatService,
  }) : _chatService = chatService ?? ChatService();

  bool _isSending = false;
  String? _errorMessage;

  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  /// Listen to all chats the current user is participating in in real time.
  Stream<List<ChatConversation>> watchMyConversations(
    String userId,
  ) {
    return _chatService.watchMyConversations(userId);
  }

  /// Listen to all messages in a specific chat room in real time.
  Stream<List<ChatMessage>> watchMessages(
    String chatId,
  ) {
    return _chatService.watchMessages(chatId);
  }

  /// Send a text message.
  Future<bool> sendMessage({
    required String chatId,
    required String senderId,
    required String text,
  }) async {
    if (text.trim().isEmpty) {
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _chatService.sendMessage(
        chatId: chatId,
        senderId: senderId,
        text: text,
      );

      return true;
    } catch (e) {
      _errorMessage =
          e.toString().replaceFirst('Exception: ', '');

      return false;
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}