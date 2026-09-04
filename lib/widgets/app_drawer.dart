import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../screens/login_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback? onOffers;
  final VoidCallback? onMyTasks;
  final VoidCallback? onMyRequests;
  final VoidCallback? onMyChats;

  const AppDrawer({
    super.key,
    this.onOffers,
    this.onMyTasks,
    this.onMyRequests,
    this.onMyChats,
  });

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthController>().logout();

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<AuthController>().currentUser;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            // =========================
            // User information
            // =========================
            DrawerHeader(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundImage:
                        user?.photoUrl != null
                            ? NetworkImage(
                                user!.photoUrl!,
                              )
                            : null,
                    child:
                        user?.photoUrl == null
                            ? const Icon(
                                Icons.person,
                                size: 28,
                              )
                            : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty ==
                                  true
                              ? user!.fullName
                              : 'Unibuddy',
                          style: const TextStyle(
                            fontWeight:
                                FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow:
                              TextOverflow.ellipsis,
                        ),

                        if (user?.university != null)
                          Text(
                            user!.university!,
                            style:
                                const TextStyle(
                              fontSize: 12,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // =========================
            // Navigation
            // =========================
            ListTile(
              leading: const Icon(Icons.people_outline),
              title: const Text('Offers'),
              onTap: onOffers,
            ),

            ListTile(
              leading: const Icon(Icons.task_alt_outlined),
              title: const Text('My Tasks'),
              onTap: onMyTasks,
            ),

            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: const Text('My Requests'),
              onTap: onMyRequests,
            ),

            ListTile(
              leading: const Icon(Icons.chat_bubble_outline),
              title: const Text('My Chats'),
              onTap: onMyChats,
            ),

            const Spacer(),

            // =========================
            // Logout
            // =========================
            const Divider(height: 1),

            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}