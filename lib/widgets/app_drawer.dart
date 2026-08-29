import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../screens/login_screen.dart';

enum AppDrawerMode {
  modeSelection,
  requester,
  buddy,
}

class AppDrawer extends StatelessWidget {
  final AppDrawerMode mode;

  final VoidCallback? onMyRequests;
  final VoidCallback? onMyChats;

  final VoidCallback? onOffers;
  final VoidCallback? onMyTasks;

  final VoidCallback? onSwitchMode;

  const AppDrawer({
    super.key,
    this.mode = AppDrawerMode.modeSelection,
    this.onMyRequests,
    this.onMyChats,
    this.onOffers,
    this.onMyTasks,
    this.onSwitchMode,
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
            // REQUESTER MODE
            // =========================
            if (mode ==
                AppDrawerMode.requester) ...[
              ListTile(
                leading: const Icon(
                  Icons.list_alt_outlined,
                ),
                title:
                    const Text('My Requests'),
                onTap: onMyRequests,
              ),

              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                ),
                title:
                    const Text('My Chats'),
                onTap: onMyChats,
              ),
            ],

            // =========================
            // BUDDY MODE
            // =========================
            if (mode ==
                AppDrawerMode.buddy) ...[
              ListTile(
                leading: const Icon(
                  Icons.people_outline,
                ),
                title:
                    const Text('Offers'),
                onTap: onOffers,
              ),

              ListTile(
                leading: const Icon(
                  Icons.task_alt_outlined,
                ),
                title:
                    const Text('My Tasks'),
                onTap: onMyTasks,
              ),

              ListTile(
                leading: const Icon(
                  Icons.chat_bubble_outline,
                ),
                title:
                    const Text('My Chats'),
                onTap: onMyChats,
              ),
            ],

            const Spacer(),

            // =========================
            // Switch Mode
            // =========================
            if (mode !=
                AppDrawerMode.modeSelection) ...[
              const Divider(height: 1),

              ListTile(
                leading: const Icon(
                  Icons.swap_horiz,
                ),
                title:
                    const Text('Switch Mode'),
                onTap: onSwitchMode,
              ),
            ],

            // =========================
            // Logout
            // =========================
            const Divider(height: 1),

            ListTile(
              leading:
                  const Icon(Icons.logout),
              title: const Text('Log out'),
              onTap: () => _logout(context),
            ),
          ],
        ),
      ),
    );
  }
}