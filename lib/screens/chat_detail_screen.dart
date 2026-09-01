import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../services/user_service.dart';
import '../models/buddy_request.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import 'profile_view_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final ChatConversation conversation;

  const ChatDetailScreen({
    super.key,
    required this.conversation,
  });

  @override
  State<ChatDetailScreen> createState() =>
      _ChatDetailScreenState();
}

class _ChatDetailScreenState
    extends State<ChatDetailScreen> {
  final UserService _userService = UserService();
  User? _otherUser;
  final _messageController =
      TextEditingController();

  final _scrollController =
      ScrollController();
  @override
void initState() {
  super.initState();

  _loadOtherUser();
}


Future<void> _loadOtherUser() async {

  final user =
      context.read<AuthController>().currentUser;

  if (user == null) {
    return;
  }


  final otherId =
      user.id ==
              widget.conversation.requesterId
          ? widget.conversation.buddyId
          : widget.conversation.requesterId;


  final result =
      await _userService.getUserById(
    otherId,
  );


  if (mounted) {
    setState(() {
      _otherUser = result;
    });
  }
}
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // =========================================================
  // SEND MESSAGE
  // =========================================================

  Future<void> _sendMessage() async {
    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    final text =
        _messageController.text.trim();

    if (text.isEmpty) {
      return;
    }

    final success =
        await context
            .read<ChatController>()
            .sendMessage(
              chatId:
                  widget.conversation.id,
              senderId: user.id,
              text: text,
            );

    if (!mounted) {
      return;
    }

    if (success) {
      _messageController.clear();
    } else {
      final error =
          context
                  .read<ChatController>()
                  .errorMessage ??
              'Failed to send message.';

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(error),
        ),
      );
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<AuthController>().currentUser;

    final chatController =
        context.watch<ChatController>();

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'User not found.',
          ),
        ),
      );
    }

    // =======================================================
    // Determine who the other person in the chat is.
    // =======================================================

    final otherPersonName =
        user.id ==
                widget.conversation.requesterId
            ? widget.conversation.buddyName
            : widget
                .conversation.requesterName;

    final otherPersonId =
        user.id ==
                widget.conversation.requesterId
            ? widget.conversation.buddyId
            : widget.conversation.requesterId;

    final requestDate =
        widget.conversation.requestDateTime;

    return Scaffold(
      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        title: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              otherPersonName,

              style:
                  const TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            Text(
              '${widget.conversation.helpType.label} · '
              '${requestDate.day}/${requestDate.month}/${requestDate.year}',

              style:
                  const TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.normal,
              ),
            ),
          ],
        ),

        // ===============================================
        // View the other person's profile
        // ===============================================

        actions: [
          IconButton(
            tooltip: 'View profile',

            icon: const Icon(
              Icons.account_circle_outlined,
            ),

            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ProfileViewScreen(
                    userId:
                        otherPersonId,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =====================================================
      // CHAT PAGE
      // =====================================================

      body: Column(
        children: [
          // =================================================
          // MESSAGES
          // =================================================

          Expanded(
            child:
                StreamBuilder<
                    List<ChatMessage>>(
              stream:
                  chatController.watchMessages(
                widget.conversation.id,
              ),

              builder:
                  (context, snapshot) {
                // First load
                if (snapshot.connectionState ==
                        ConnectionState
                            .waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child:
                        CircularProgressIndicator(),
                  );
                }

                // Failed to load
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load messages.\n'
                      '${snapshot.error}',

                      textAlign:
                          TextAlign.center,
                    ),
                  );
                }

                final messages =
                    snapshot.data ?? [];

                // There are no messages yet.
                if (messages.isEmpty) {
                  return const Center(
                    child: Text(
                      'No messages yet.\n'
                      'Say hello!',

                      textAlign:
                          TextAlign.center,

                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  );
                }

                // ===========================================
                // MESSAGE LIST
                // ===========================================

                return ListView.builder(
                  controller:
                      _scrollController,

                  padding:
                      const EdgeInsets.all(
                    16,
                  ),

                  itemCount:
                      messages.length,

                  itemBuilder:
                      (context, index) {
                    final message =
                        messages[index];

                    // Is it sent by me?
                    final isMine =
                        message.senderId ==
                            user.id;

                    return _MessageBubble(
  message: message,
  isMine: isMine,

  senderName: isMine
      ? user.fullName
      : otherPersonName,

  photoUrl: isMine
      ? user.photoUrl
      : _otherUser?.photoUrl,
);
                  },
                );
              },
            ),
          ),

          // =================================================
          // MESSAGE INPUT
          // =================================================

          SafeArea(
            top: false,

            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                12,
                8,
                12,
                12,
              ),

              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.end,

                children: [
                  // =========================================
                  // Input box
                  // =========================================

                  Expanded(
                    child: TextField(
                      controller:
                          _messageController,

                      minLines: 1,
                      maxLines: 4,

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Type a message...',

                        border:
                            OutlineInputBorder(),
                      ),

                      onSubmitted: (_) {
                        if (!chatController
                            .isSending) {
                          _sendMessage();
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 8),

                  // =========================================
                  // Send
                  // =========================================

                  IconButton.filled(
                    onPressed:
                        chatController.isSending
                            ? null
                            : _sendMessage,

                    icon:
                        chatController.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,

                                child:
                                    CircularProgressIndicator(
                                  strokeWidth:
                                      2,
                                ),
                              )
                            : const Icon(
                                Icons.send,
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================
// MESSAGE BUBBLE
// ===========================================================

class _MessageBubble
    extends StatelessWidget {
      final ChatMessage message;
      final bool isMine;
      final String senderName;
      final String? photoUrl;

  const _MessageBubble({
    required this.message,
    required this.isMine,
    required this.senderName,
    required this.photoUrl,
});

  @override
  Widget build(BuildContext context) {
    final time =
        TimeOfDay.fromDateTime(
      message.sentAt,
    ).format(context);

    return Align(
  alignment: isMine
      ? Alignment.centerRight
      : Alignment.centerLeft,

  child: Row(
    mainAxisSize: MainAxisSize.min,

    crossAxisAlignment:
        CrossAxisAlignment.start,

    children: [

      if (!isMine)
        Padding(
          padding:
              const EdgeInsets.only(
            right: 8,
          ),

          child: CircleAvatar(
            radius: 18,

            backgroundImage:
                photoUrl != null
                    ? NetworkImage(photoUrl!)
                    : null,

            child:
                photoUrl == null
                    ? Text(
                        senderName[0]
                            .toUpperCase(),
                      )
                    : null,
          ),
        ),


      Column(
        crossAxisAlignment:
            isMine
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,

        children: [

          if (!isMine)
            Text(
              senderName,

              style:
                  const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),


          Container(
            constraints:
                const BoxConstraints(
              maxWidth: 340,
            ),

            margin:
                const EdgeInsets.only(
              bottom: 10,
            ),

            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),

            decoration:
                BoxDecoration(
              color:
                  isMine
                      ? Theme.of(context)
                          .colorScheme
                          .primaryContainer
                      : Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,

              borderRadius:
                  BorderRadius.circular(
                16,
              ),
            ),


            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.end,

              children: [

                Text(
                  message.text,
                  style:
                      const TextStyle(
                    fontSize: 15,
                  ),
                ),


                const SizedBox(
                  height: 4,
                ),


                Text(
                  time,

                  style:
                      const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ],
  ),
);
  }
}