import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';
import 'offers_screen.dart';
import '../widgets/main_bottom_bar.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen> {
  RequestStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final user = context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    await context.read<RequestController>().loadMyTasks(user.id);
  }

  void _openOffers() {
    Navigator.of(context).pop();

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const OffersScreen()));
  }

  void _openMyChats() {
    Navigator.of(context).pop();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ChatScreen()));
  }

  void _switchMode() {
    // Close the drawer.
    Navigator.of(context).pop();

    // Return to the Offer / Request mode selection screen.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<RequestController>();

    return Scaffold(
      drawer: AppDrawer(
        mode: AppDrawerMode.buddy,

        onOffers: _openOffers,

        onMyTasks: () {
          // Already on My Tasks.
          Navigator.of(context).pop();
        },

        onMyChats: _openMyChats,

        onSwitchMode: _switchMode,
      ),

      appBar: AppBar(
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

        title: const Text('My Tasks'),
      ),

      body: SafeArea(child: _buildBody(controller)),
      // ==============================
      // Quick access - Chat / Browse / My Requests
      // Docked to the bottom of the screen.
      // ==============================
      bottomNavigationBar: const MainBottomBar(),
    );
  }

  Widget _buildBody(RequestController controller) {
    if (controller.isLoading && controller.myTasks.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.myTasks.isEmpty) {
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
                onPressed: _loadTasks,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (controller.myTasks.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.task_alt_outlined, size: 56, color: Colors.grey),

              SizedBox(height: 16),

              Text(
                'No tasks yet.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              SizedBox(height: 8),

              Text(
                'Requests you accept will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    final tasks = _visibleTasks(controller.myTasks);

    return Column(
      children: [
        _buildStatusFilter(),

        Expanded(
          child: tasks.isEmpty
              ? Center(
                  child: Text(
                    'No ${_statusLabel(_selectedStatus).toLowerCase()} tasks.',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,

                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),

                    itemCount: tasks.length,

                    separatorBuilder: (_, _) => const SizedBox(height: 12),

                    itemBuilder: (context, index) {
                      final task = tasks[index];

                      return _TaskCard(task: task, onChanged: _loadTasks);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  List<BuddyRequest> _visibleTasks(List<BuddyRequest> tasks) {
    final status = _selectedStatus;

    if (status == null) {
      return tasks;
    }

    return tasks.where((task) => task.status == status).toList();
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

class _TaskCard extends StatelessWidget {
  final BuddyRequest task;
  final Future<void> Function() onChanged;

  const _TaskCard({required this.task, required this.onChanged});

  Future<void> _completeTask(BuildContext context) async {
    if (task.id == null) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Complete Task'),
          content: const Text('Mark this task as completed?'),
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

    final success = await controller.completeRequest(task.id!);

    if (!context.mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Task completed.')));

      await onChanged();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(controller.errorMessage ?? 'Failed to complete task.'),
        ),
      );
    }
  }

  Future<void> _submitFeedback(BuildContext context) async {
    if (task.id == null) {
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
                      hintText: 'How was the request?',
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

    final success = await controller.submitBuddyFeedback(
      requestId: task.id!,
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
    final date = task.dateTime;

    final dateText = '${date.day}/${date.month}/${date.year}';

    final timeText = TimeOfDay.fromDateTime(date).format(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // =========================
            // Help type + status
            // =========================
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.helpType.label,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                _TaskStatusChip(status: task.status),
              ],
            ),

            // If the type is Other
            if (task.helpType == HelpType.other && task.customHelp != null) ...[
              const SizedBox(height: 6),

              Text(task.customHelp!),
            ],

            const SizedBox(height: 12),

            // =========================
            // Requester name
            // =========================
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18),

                const SizedBox(width: 6),

                Text(task.requesterName),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // Location
            // =========================
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 18),

                const SizedBox(width: 6),

                Text('${task.city}, ${task.country}'),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // Date + time
            // =========================
            Row(
              children: [
                const Icon(Icons.schedule_outlined, size: 18),

                const SizedBox(width: 6),

                Text('$dateText · $timeText'),
              ],
            ),

            // =========================
            // If the helper cancels
            // =========================
            if (task.status == RequestStatus.cancelled) ...[
              const SizedBox(height: 12),

              const Text(
                'Cancelled by requester',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            // =========================
            // Optional note
            // =========================
            if (task.note != null) ...[
              const SizedBox(height: 12),

              Text(task.note!, style: const TextStyle(color: Colors.grey)),
            ],

            if (task.status == RequestStatus.accepted) ...[
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _completeTask(context);
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Complete Task'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],

            if (task.status == RequestStatus.completed) ...[
              const SizedBox(height: 16),

              if (task.buddyRating == null)
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
                  rating: task.buddyRating!,
                  comment: task.buddyFeedback,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskStatusChip extends StatelessWidget {
  final RequestStatus status;

  const _TaskStatusChip({required this.status});

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

    return Chip(label: Text(text));
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
