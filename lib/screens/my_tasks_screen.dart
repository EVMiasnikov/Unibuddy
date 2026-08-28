import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../controllers/request_controller.dart';
import '../models/buddy_request.dart';
import '../widgets/app_drawer.dart';
import 'chat_screen.dart';
import 'offers_screen.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() =>
      _MyTasksScreenState();
}

class _MyTasksScreenState
    extends State<MyTasksScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTasks();
    });
  }

  Future<void> _loadTasks() async {
    final user =
        context.read<AuthController>().currentUser;

    if (user == null) {
      return;
    }

    await context
        .read<RequestController>()
        .loadMyTasks(user.id);
  }

  void _openOffers() {
    Navigator.of(context).pop();

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const OffersScreen(),
      ),
    );
  }

  void _openMyChats() {
    Navigator.of(context).pop();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ChatScreen(),
      ),
    );
  }

  void _switchMode() {
    // Close the drawer.
    Navigator.of(context).pop();

    // Return to the Offer / Request mode selection screen.
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller =
        context.watch<RequestController>();

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

      body: SafeArea(
        child: _buildBody(controller),
      ),
    );
  }

  Widget _buildBody(
    RequestController controller,
  ) {
    if (controller.isLoading &&
        controller.myTasks.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller.errorMessage != null &&
        controller.myTasks.isEmpty) {
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
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              Icon(
                Icons.task_alt_outlined,
                size: 56,
                color: Colors.grey,
              ),

              SizedBox(height: 16),

              Text(
                'No tasks yet.',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 8),

              Text(
                'Requests you accept will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTasks,

      child: ListView.separated(
        padding: const EdgeInsets.all(16),

        itemCount:
            controller.myTasks.length,

        separatorBuilder: (_, __) =>
            const SizedBox(height: 12),

        itemBuilder: (context, index) {
          final task =
              controller.myTasks[index];

          return _TaskCard(
            task: task,
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final BuddyRequest task;

  const _TaskCard({
    required this.task,
  });

  @override
  Widget build(BuildContext context) {
    final date = task.dateTime;

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
                      fontWeight:
                          FontWeight.bold,
                    ),
                  ),
                ),

                _TaskStatusChip(
                  status: task.status,
                ),
              ],
            ),

            // If the type is Other
            if (task.helpType ==
                    HelpType.other &&
                task.customHelp != null) ...[
              const SizedBox(height: 6),

              Text(
                task.customHelp!,
              ),
            ],

            const SizedBox(height: 12),

            // =========================
            // Requester name
            // =========================
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Text(
                  task.requesterName,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // Location
            // =========================
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 18,
                ),

                const SizedBox(width: 6),

                Text(
                  '${task.city}, ${task.country}',
                ),
              ],
            ),

            const SizedBox(height: 8),

            // =========================
            // Date + time
            // =========================
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

            // =========================
            // If the helper cancels
            // =========================
            if (task.status ==
                RequestStatus.cancelled) ...[
              const SizedBox(height: 12),

              const Text(
                'Cancelled by requester',
                style: TextStyle(
                  color: Colors.grey,
                  fontStyle:
                      FontStyle.italic,
                ),
              ),
            ],

            // =========================
            // Optional note
            // =========================
            if (task.note != null) ...[
              const SizedBox(height: 12),

              Text(
                task.note!,
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
class _TaskStatusChip extends StatelessWidget {
  final RequestStatus status;

  const _TaskStatusChip({
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
