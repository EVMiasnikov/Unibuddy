import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../models/buddy_request_type.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_action_tile.dart';
import '../widgets/profile_menu_button.dart';
import 'chat_screen.dart';
import 'create_buddy_request_screen.dart';
import 'my_requests_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return Scaffold(
      // Adding `drawer:` automatically gives the AppBar a hamburger
      // icon on the left that opens it - no extra wiring needed.
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: const Text('Home'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: ProfileMenuButton(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome, ${user?.name ?? 'Guest'}!',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    MainActionTile(
                      icon: BuddyRequestType.offerBuddy.icon,
                      label: BuddyRequestType.offerBuddy.title,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateBuddyRequestScreen(type: BuddyRequestType.offerBuddy),
                        ),
                      ),
                    ),
                    MainActionTile(
                      icon: BuddyRequestType.seekBuddy.icon,
                      label: BuddyRequestType.seekBuddy.title,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const CreateBuddyRequestScreen(type: BuddyRequestType.seekBuddy),
                        ),
                      ),
                    ),
                    MainActionTile(
                      icon: Icons.chat_bubble_outline,
                      label: 'Chat',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const ChatScreen()),
                      ),
                    ),
                    MainActionTile(
                      icon: Icons.list_alt_outlined,
                      label: 'My Requests',
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const MyRequestsScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}