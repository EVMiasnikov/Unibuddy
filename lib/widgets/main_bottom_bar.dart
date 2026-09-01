import 'package:flutter/material.dart';
import 'main_action_button.dart';
import '../screens/chat_screen.dart';
import '../screens/my_requests_screen.dart';
import '../screens/offers_screen.dart';

/// Shared quick-access bar: Chat / Browse Requests / My Requests.
/// Drop `bottomNavigationBar: const MainBottomBar()` into any Scaffold
/// to add it - keeps this in one place so it's consistent everywhere.
class MainBottomBar extends StatelessWidget {
  const MainBottomBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            MainActionButton(
              icon: Icons.chat_bubble_outline,
              label: 'Chat',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              ),
            ),
            const SizedBox(width: 12),
            MainActionButton(
              icon: Icons.search,
              label: 'Browse Requests',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OffersScreen()),
              ),
            ),
            const SizedBox(width: 12),
            MainActionButton(
              icon: Icons.list_alt_outlined,
              label: 'My Requests',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
