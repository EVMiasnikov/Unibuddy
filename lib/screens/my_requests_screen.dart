import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';
import 'create_request_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() =>
      _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  /// Load requests created by the current user from Firebase.
  Future<void> _loadRequests() async {
    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    await context
        .read<RequestController>()
        .loadMyRequests(user.id);
  }

  /// Open the Create Request screen.
  Future<void> _openCreateRequest() async {
    final created =
        await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            const CreateRequestScreen(),
      ),
    );

    // Reload the request list after successful creation.
    if (created == true) {
      await _loadRequests();
    }
  }

  /// Open My Chats.
  void _openMyChats() {
    // Close the drawer first.
    Navigator.of(context).pop();

    // Then navigate to the chat screen.
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  /// Return to the initial Offer / Request mode selection screen.
  void _switchMode() {
    // First pop: close the drawer.
    Navigator.of(context).pop();

    // Second pop: exit My Requests,
    // and return to the previous mode selection screen.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<RequestController>();

    return Scaffold(
      // ==============================
      // Requester mode left sidebar
      // ==============================
      drawer: AppDrawer(
        mode: AppDrawerMode.requester,

        onMyRequests: () {
          // We are already on My Requests,
          // so we only need to close the drawer.
          Navigator.of(context).pop();
        },

        onMyChats: _openMyChats,

        onSwitchMode: _switchMode,
      ),

      // ==============================
      // Top bar
      // ==============================
      appBar: AppBar(
        // Force the menu to appear in the top-left instead of the back arrow.
        leading: Builder(
          builder: (context) {
            return IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            );
          },
        ),

        title: const Text('My Requests'),

        actions: [
          TextButton.icon(
            onPressed: _openCreateRequest,
            icon: const Icon(Icons.add),
            label: const Text(
              'Create Request',
            ),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ==============================
      // Main content
      // ==============================
      body: SafeArea(
        child: _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(
    RequestController controller,
  ) {
    // --------------------------------
    // Show a loading spinner while the first read is in progress.
    // --------------------------------
    if (controller.isLoading &&
        controller.myRequests.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // --------------------------------
    // Read failed
    // --------------------------------
    if (controller.errorMessage != null &&
        controller.myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(height: 12),

              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _loadRequests,
                child: const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------
    // No requests at all
    // --------------------------------
    if (controller.myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.inbox_outlined,
                size: 56,
                color: Colors.grey,
              ),

              const SizedBox(height: 16),

              const Text(
                'No requests yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create your first request when you need help.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _openCreateRequest,
                icon: const Icon(Icons.add),
                label: const Text(
                  'Create Request',
                ),
              ),
            ],
          ),
        ),
      );
    }

    // --------------------------------
    // Has requests: show the list
    // --------------------------------
    return RefreshIndicator(
      onRefresh: _loadRequests,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount:
            controller.myRequests.length,

        separatorBuilder: (_, _) =>
            const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final request =
              controller.myRequests[index];

          return _RequestCard(
            request: request,
            onChanged: _loadRequests,
          );
        },
      ),
    );
  }
}

/// A request card.
class _RequestCard extends StatelessWidget {
  final BuddyRequest request;

  final Future<void> Function() onChanged;

  const _RequestCard({
    required this.request,
    required this.onChanged,
  });

  Future<void> _handleRequestAction(
    BuildContext context,
  ) async {
    if (request.id == null) {
      return;
    }

    final controller =
        context.read<RequestController>();

    // =====================================
    // PENDING → DELETE
    // =====================================

    if (request.status ==
        RequestStatus.pending) {
      final confirmed =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:
                const Text('Delete Request'),
            content: const Text(
              'Are you sure you want to delete this request?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false);
                },
                child:
                    const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(true);
                },
                child:
                    const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final success =
          await controller.deleteRequest(
        request.id!,
      );

      if (!context.mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Request deleted.',
            ),
          ),
        );

        await onChanged();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ??
                  'Failed to delete request.',
            ),
          ),
        );
      }

      return;
    }

    // =====================================
    // ACCEPTED → CANCEL
    // =====================================

    if (request.status ==
        RequestStatus.accepted) {
      final confirmed =
          await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title:
                const Text('Cancel Request'),
            content: const Text(
              'This request has already been accepted by a buddy.\n\n'
              'Cancelling it will close the task, but the chat history will remain.\n\n'
              'Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(false);
                },
                child:
                    const Text('Keep Request'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context)
                      .pop(true);
                },
                child:
                    const Text('Cancel Request'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final success =
          await controller.cancelRequest(
        request.id!,
      );

      if (!context.mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Request cancelled.',
            ),
          ),
        );

        await onChanged();
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ??
                  'Failed to cancel request.',
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = request.dateTime;

    final dateText =
        '${date.day}/${date.month}/${date.year}';

    final timeText =
        TimeOfDay.fromDateTime(date)
            .format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.helpType.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                _StatusChip(
                  status: request.status,
                ),

                const SizedBox(width: 4),

                if (request.status ==
                        RequestStatus.pending ||
                    request.status ==
                        RequestStatus.accepted)
                  PopupMenuButton<String>(
                    onSelected: (_) {
                      _handleRequestAction(
                        context,
                      );
                    },
                    itemBuilder: (context) {
                      if (request.status ==
                          RequestStatus.pending) {
                        return const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_outline,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Delete Request',
                                ),
                              ],
                            ),
                          ),
                        ];
                      }

                      return const [
                        PopupMenuItem(
                          value: 'cancel',
                          child: Row(
                            children: [
                              Icon(
                                Icons.cancel_outlined,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Cancel Request',
                              ),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),

            if (request.helpType ==
                    HelpType.other &&
                request.customHelp != null) ...[
              const SizedBox(height: 6),

              Text(
                request.customHelp!,
              ),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Text(
                  '${request.city}, ${request.country}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Text(
                  '$dateText · $timeText',
                ),
              ],
            ),

            if (request.note != null) ...[
              const SizedBox(height: 12),

              Text(
                request.note!,
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Pending / Accepted / Completed
class _StatusChip extends StatelessWidget {
  final RequestStatus status;

  const _StatusChip({
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    String text;

    switch (status) {
      case RequestStatus.pending:
        text = 'Pending';
        break;

      case RequestStatus.accepted:
        text = 'Accepted';
        break;

      case RequestStatus.completed:
        text = 'Completed';
        break;

      case RequestStatus.cancelled:
        text = 'Cancelled';
        break;
    }

    return Chip(
      label: Text(text),
    );
  }
}
