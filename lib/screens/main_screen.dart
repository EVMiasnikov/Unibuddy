import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/buddy_mode.dart';
import '../widgets/app_drawer.dart';
import '../widgets/available_buddies_bar.dart';
import '../widgets/buddy_status_card.dart';
import '../widgets/main_action_button.dart';
import '../widgets/main_action_tile.dart';
import '../widgets/profile_menu_button.dart';
import '../widgets/main_bottom_bar.dart';

import 'chat_screen.dart';
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

              // // ==============================
              // // Be a Buddy - status toggle, and Request a Buddy - mode selection
              // // ==============================

              LayoutBuilder(
                builder: (context, constraints) {
                  final requestTile = MainActionTile(
                    icon: BuddyMode.seekBuddy.icon,
                    label: BuddyMode.seekBuddy.title,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const MyRequestsScreen(),
                        ),
                      );
                    },
                  );

                  if (constraints.maxWidth < 520) {
                    return Column(
                      children: [
                        const BuddyStatusCard(),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          width: double.infinity,
                          child: requestTile,
                        ),
                      ],
                    );
                  }

                  return SizedBox(
                    height: 200,
                    child: Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.stretch,
                      children: [
                        const Expanded(
                          child: BuddyStatusCard(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: requestTile),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // ==============================
              // Available buddies advertisement bar
              // ==============================
              const AvailableBuddiesBar(),
            ],
          ),
        ),
      ),

      // ==============================
      // Quick access - Chat / Browse / My Requests
      // Docked to the bottom of the screen.
      // ==============================
      bottomNavigationBar: const MainBottomBar(),
    );
  }
}
