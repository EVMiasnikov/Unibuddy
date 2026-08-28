import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/buddy_mode.dart';
import '../widgets/app_drawer.dart';
import '../widgets/main_action_tile.dart';
import '../widgets/profile_menu_button.dart';

import 'my_requests_screen.dart';
import 'offers_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        context.watch<AuthController>().currentUser;

    return Scaffold(
      drawer: const AppDrawer(),

      appBar: AppBar(
        title: const Text('UniBuddy'),

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
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Text(
                'Welcome, ${user?.name ?? 'Guest'}!',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,

                  children: [
                    // =========================
                    // Buddy Mode
                    // =========================
                    MainActionTile(
                      icon:
                          BuddyMode.offerBuddy.icon,

                      label:
                          BuddyMode.offerBuddy.title,

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const OffersScreen(),
                          ),
                        );
                      },
                    ),

                    // =========================
                    // Requester Mode
                    // =========================
                    MainActionTile(
                      icon:
                          BuddyMode.seekBuddy.icon,

                      label:
                          BuddyMode.seekBuddy.title,

                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const MyRequestsScreen(),
                          ),
                        );
                      },
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