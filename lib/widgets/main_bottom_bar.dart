import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import 'main_action_button.dart';

import '../screens/chat_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/offers_screen.dart';


/// Shared quick-access bar:
/// Chat / Browse Requests / My Requests.
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [

            // ============================
            // Chat
            // ============================
            Expanded(
              child: MainActionButton(
                icon: Icons.chat_bubble_outline,
                label: 'Chat',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ChatScreen(),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(width: 12),


            // ============================
            // Browse Requests
            // Only available for Buddies
            // ============================
            Expanded(
              child: MainActionButton(
                icon: Icons.search,
                label: 'Browse Requests',
                onTap: () {

                  final user =
                      context.read<AuthController>().currentUser;


                  if (user == null) {
                    return;
                  }


                  // User must enable "Be a Buddy"
                  if (!user.isAcceptingBuddyRequests) {

                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text(
                          'Become a Buddy first',
                        ),

                        content: const Text(
                          'Enable "Be a Buddy" mode before accepting requests.',
                        ),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },

                            child: const Text(
                              'OK',
                            ),
                          ),
                        ],
                      ),
                    );

                    return;
                  }


                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OffersScreen(),
                    ),
                  );

                },
              ),
            ),


            const SizedBox(width: 12),


            // ============================
            // My Requests
            // ============================
            Expanded(
              child: MainActionButton(
                icon: Icons.list_alt_outlined,
                label: 'My Requests',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const MyRequestsScreen(),
                    ),
                  );
                },
              ),
            ),

          ],
        ),
      ),
    );
  }
}
