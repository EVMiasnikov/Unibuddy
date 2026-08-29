import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/buddy_request.dart';
import '../controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/chat_conversation.dart';
import 'chat_detail_screen.dart';

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<AuthController>().currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text('User not found.'),
        ),
      );
    }

    final chatController =
        context.read<ChatController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Chats'),
      ),

      body: StreamBuilder<
          List<ChatConversation>>(
        stream:
            chatController
                .watchMyConversations(
          user.id,
        ),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
                  ConnectionState.waiting &&
              !snapshot.hasData) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Text(
                  'Failed to load chats.\n'
                  '${snapshot.error}',
                  textAlign:
                      TextAlign.center,
                ),
              ),
            );
          }

          final conversations =
              snapshot.data ?? [];

          if (conversations.isEmpty) {
            return const Center(
              child: Padding(
                padding:
                    EdgeInsets.all(32),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    Icon(
                      Icons
                          .chat_bubble_outline,
                      size: 56,
                      color: Colors.grey,
                    ),

                    SizedBox(height: 16),

                    Text(
                      'No chats yet.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 8),

                    Text(
                      'A chat will appear after a buddy accepts a request.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding:
                const EdgeInsets.all(12),

            itemCount:
                conversations.length,

            separatorBuilder: (_, _) =>
                const Divider(height: 1),

            itemBuilder:
                (context, index) {
              final conversation =
                  conversations[index];

              return _ChatTile(
                conversation:
                    conversation,
                currentUserId:
                    user.id,
              );
            },
          );
        },
      ),
    );
  }
}

class _ChatTile
    extends StatelessWidget {
  final ChatConversation conversation;
  final String currentUserId;

  const _ChatTile({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final otherPersonName =
        currentUserId ==
                conversation.requesterId
            ? conversation.buddyName
            : conversation
                .requesterName;

    final date =
        conversation.requestDateTime;

    final subtitleTitle =
        '${conversation.helpType.label} · '
        '${date.day}/${date.month}/${date.year}';

    final lastMessage =
        conversation.lastMessage;

    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 6,
      ),

      leading: const CircleAvatar(
        child: Icon(Icons.person),
      ),

      title: Text(
        otherPersonName,
        style:
            const TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),

      subtitle: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(subtitleTitle),

          if (lastMessage != null &&
              lastMessage.isNotEmpty)
            Text(
              lastMessage,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),
        ],
      ),

      trailing:
          const Icon(
        Icons.chevron_right,
      ),

      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ChatDetailScreen(
              conversation:
                  conversation,
            ),
          ),
        );
      },
    );
  }
}
