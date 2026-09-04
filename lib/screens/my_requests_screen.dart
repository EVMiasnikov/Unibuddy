import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/accepted_buddy_info.dart';
import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';
import 'create_request_screen.dart';
import '../widgets/main_bottom_bar.dart';
import 'my_tasks_screen.dart';
import 'offers_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  RequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRequests();
    });
  }

  /// Load requests created by the current user from Firebase.
  Future<void> _loadRequests() async {
    final user = context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    await context.read<RequestController>().loadMyRequests(user.id);
  }

  /// Open the Create Request screen.
  Future<void> _openCreateRequest() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const CreateRequestScreen()),
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

    /// Open Offers.
  void _openOffers() {
    Navigator.of(context).pop();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const OffersScreen()));
  }

  /// Open My Tasks.
  void _openMyTasks() {
    Navigator.of(context).pop();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MyTasksScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RequestController>();

    return Scaffold(
      // ==============================
      // Requester mode left sidebar
      // ==============================
            drawer: AppDrawer(
        onOffers: _openOffers,

        onMyTasks: _openMyTasks,

        onMyRequests: () {
          // We are already on My Requests,
          // so we only need to close the drawer.
          Navigator.of(context).pop();
        },

        onMyChats: _openMyChats,
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
            label: const Text('Create Request'),
          ),

          const SizedBox(width: 8),
        ],
      ),

      // ==============================
      // Main content
      // ==============================
      body: SafeArea(child: _buildBody(controller)),
      // ==============================
      // Quick access - Chat / Browse / My Requests
      // Docked to the bottom of the screen.
      // ==============================
      bottomNavigationBar: const MainBottomBar(),
    );
  }

  Widget _buildBody(RequestController controller) {
    // --------------------------------
    // Show a loading spinner while the first read is in progress.
    // --------------------------------
    if (controller.isLoading && controller.myRequests.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // --------------------------------
    // Read failed
    // --------------------------------
    if (controller.errorMessage != null && controller.myRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.error_outline, size: 48),

              const SizedBox(height: 12),

              Text(controller.errorMessage!, textAlign: TextAlign.center),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: _loadRequests,
                child: const Text('Try again'),
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
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),

              const SizedBox(height: 16),

              const Text(
                'No requests yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Create your first request when you need help.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: _openCreateRequest,
                icon: const Icon(Icons.add),
                label: const Text('Create Request'),
              ),
            ],
          ),
        ),
      );
    }

    final requests = _visibleRequests(controller.myRequests);

    // --------------------------------
    // Has requests: show the list
    // --------------------------------
    return Column(
      children: [
        _buildStatusFilter(),

        Expanded(
          child: requests.isEmpty
              ? Center(
                  child: Text(
                    'No ${_statusLabel(_selectedStatus).toLowerCase()} requests.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadRequests,

                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                    itemCount: requests.length,

                    separatorBuilder: (_, _) => const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final request = requests[index];

                      return _RequestCard(
                        request: request,
                        onChanged: _loadRequests,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<BuddyRequest> _visibleRequests(List<BuddyRequest> requests) {
    final status = _selectedStatus;

    if (status == null) {
      return requests;
    }

    return requests.where((request) => request.status == status).toList();
  }

  Widget _buildStatusFilter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: DropdownButtonFormField<RequestStatus?>(
        initialValue: _selectedStatus,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Status',
          prefixIcon: Icon(Icons.filter_list),
          border: OutlineInputBorder(),
          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        items: [
          const DropdownMenuItem<RequestStatus?>(
            value: null,
            child: Text('All statuses'),
          ),
          ...RequestStatus.values.map(
            (status) => DropdownMenuItem<RequestStatus?>(
              value: status,
              child: Text(_statusLabel(status)),
            ),
          ),
        ],
        onChanged: (status) {
          setState(() {
            _selectedStatus = status;
          });
        },
      ),
    );
  }

  String _statusLabel(RequestStatus? status) {
    switch (status) {
      case null:
        return 'All statuses';
      case RequestStatus.pending:
        return 'Pending';
      case RequestStatus.accepted:
        return 'Accepted';
      case RequestStatus.completed:
        return 'Completed';
      case RequestStatus.cancelled:
        return 'Cancelled';
    }
  }
}

/// A request card.
class _RequestCard extends StatelessWidget {
  final BuddyRequest request;

  final Future<void> Function() onChanged;

  const _RequestCard({required this.request, required this.onChanged});

  Future<void> _handleRequestAction(BuildContext context) async {
    if (request.id == null) {
      return;
    }

    final controller = context.read<RequestController>();

    // =====================================
    // PENDING → DELETE
    // =====================================

    if (request.status == RequestStatus.pending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Delete Request'),
            content: const Text(
              'Are you sure you want to delete this request?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Delete'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final success = await controller.deleteRequest(request.id!);

      if (!context.mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request deleted.')));

        await onChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Failed to delete request.',
            ),
          ),
        );
      }

      return;
    }

    // =====================================
    // ACCEPTED → CANCEL
    // =====================================

    if (request.status == RequestStatus.accepted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Cancel Request'),
            content: const Text(
              'This request has already been accepted by a buddy.\n\n'
              'Cancelling it will close the task, but the chat history will remain.\n\n'
              'Are you sure you want to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: const Text('Keep Request'),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: const Text('Cancel Request'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        return;
      }

      final success = await controller.cancelRequest(request.id!);

      if (!context.mounted) {
        return;
      }

      if (success) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Request cancelled.')));

        await onChanged();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Failed to cancel request.',
            ),
          ),
        );
      }
    }
  }

  Future<void> _completeRequest(BuildContext context) async {
    if (request.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Request'),
          content: const Text('Mark this request as completed?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Not yet'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Complete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final controller = context.read<RequestController>();

    final success = await controller.completeRequest(request.id!);

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Request completed.')));

      await onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to complete request.',
          ),
        ),
      );
    }
  }

  Future<void> _submitFeedback(BuildContext context) async {
    if (request.id == null) {
      return;
    }

    final commentController = TextEditingController();
    var rating = 5;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Leave Feedback'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final value = index + 1;

                      return IconButton(
                        onPressed: () {
                          setDialogState(() {
                            rating = value;
                          });
                        },
                        icon: Icon(
                          value <= rating ? Icons.star : Icons.star_border,
                          color: Colors.amber,
                        ),
                      );
                    }),
                  ),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Comment',
                      hintText: 'How was the help?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );

    final feedback = commentController.text.trim();
    commentController.dispose();

    if (submitted != true || !context.mounted) {
      return;
    }

    final controller = context.read<RequestController>();

    final success = await controller.submitRequesterFeedback(
      requestId: request.id!,
      rating: rating,
      feedback: feedback,
    );

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Feedback submitted.')));

      await onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Failed to submit feedback.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final date = request.dateTime;

    final dateText = '${date.day}/${date.month}/${date.year}';

    final timeText = TimeOfDay.fromDateTime(date).format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.helpType.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                _StatusChip(status: request.status),

                const SizedBox(width: 4),

                if (request.status == RequestStatus.pending ||
                    request.status == RequestStatus.accepted)
                  PopupMenuButton<String>(
                    onSelected: (_) {
                      _handleRequestAction(context);
                    },
                    itemBuilder: (context) {
                      if (request.status == RequestStatus.pending) {
                        return const [
                          PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline),
                                SizedBox(width: 8),
                                Text('Delete Request'),
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
                              Icon(Icons.cancel_outlined),
                              SizedBox(width: 8),
                              Text('Cancel Request'),
                            ],
                          ),
                        ),
                      ];
                    },
                  ),
              ],
            ),

            if (request.helpType == HelpType.other &&
                request.customHelp != null) ...[
              const SizedBox(height: 6),

              Text(request.customHelp!),
            ],

            const SizedBox(height: 12),

            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),

                const SizedBox(width: 6),

                Text('${request.city}, ${request.country}'),
              ],
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),

                const SizedBox(width: 6),

                Text('$dateText · $timeText'),
              ],
            ),

            if (request.note != null) ...[
              const SizedBox(height: 12),

              Text(request.note!, style: const TextStyle(color: Colors.grey)),
            ],
            if (request.acceptedBuddyId != null) ...[
              const SizedBox(height: 12),

              AcceptedBuddyInfo(buddyId: request.acceptedBuddyId!),
            ],
            if (request.status == RequestStatus.pending) ...[
              const SizedBox(height: 12),

              const Text(
                'Waiting for a Buddy to accept your request.',
                style: TextStyle(color: Colors.grey),
              ),
            ],

            if (request.status == RequestStatus.accepted) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _completeRequest(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Request'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            if (request.status == RequestStatus.completed) ...[
              const SizedBox(height: 16),

              if (request.requesterRating == null)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      _submitFeedback(context);
                    },
                    icon: const Icon(Icons.star_outline),
                    label: const Text('Leave Feedback'),
                  ),
                )
              else
                _FeedbackSummary(
                  title: 'Your feedback',
                  rating: request.requesterRating!,
                  comment: request.requesterFeedback,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackSummary extends StatelessWidget {
  final String title;
  final int rating;
  final String? comment;

  const _FeedbackSummary({
    required this.title,
    required this.rating,
    this.comment,
  });

  @override
  Widget build(BuildContext context) {
    final cleanComment = comment?.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Row(
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                size: 18,
                color: Colors.amber,
              );
            }),
          ),
          if (cleanComment != null && cleanComment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(cleanComment),
          ],
        ],
      ),
    );
  }
}

/// Pending / Accepted / Completed
class _StatusChip extends StatelessWidget {
  final RequestStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    String text;

    switch (status) {
      case RequestStatus.pending:
        text = 'Waiting';
        break;

      case RequestStatus.accepted:
        text = 'Buddy Found';
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

      backgroundColor: switch (status) {
        RequestStatus.pending => Colors.orange.shade100,

        RequestStatus.accepted => Colors.green.shade100,

        RequestStatus.completed => Colors.blue.shade100,

        RequestStatus.cancelled => Colors.grey.shade300,
      },
    );
  }
}
