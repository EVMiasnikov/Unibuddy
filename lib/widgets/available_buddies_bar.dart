import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../controllers/buddy_directory_controller.dart';
import '../screens/profile_view_screen.dart';

/// A horizontal strip of avatars advertising who's currently available
/// as a buddy in the user's city - a lightweight "there are people here"
/// nudge, not a full directory (that's what buddy search is for).
class AvailableBuddiesBar extends StatefulWidget {
  const AvailableBuddiesBar({super.key});

  @override
  State<AvailableBuddiesBar> createState() => _AvailableBuddiesBarState();
}

class _AvailableBuddiesBarState extends State<AvailableBuddiesBar> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final user = context.read<AuthController>().currentUser;
    final city = user?.city;
    if (city == null || city.isEmpty) return;
    await context.read<BuddyDirectoryController>().loadAvailableBuddies(
          city,
          excludeUserId: user?.id,
        );
  }

  @override
  Widget build(BuildContext context) {
    final city = context.watch<AuthController>().currentUser?.city;
    final controller = context.watch<BuddyDirectoryController>();

    // No city set yet (e.g. profile setup incomplete) - nothing to show.
    if (city == null || city.isEmpty) return const SizedBox.shrink();

    if (controller.isLoading && controller.buddies.isEmpty) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    // Nobody available right now - keep the main screen clean rather
    // than showing an empty/awkward bar.
    if (controller.buddies.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Buddies available in $city',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 88,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: controller.buddies.length,
            separatorBuilder: (_, _) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final buddy = controller.buddies[index];
              return SizedBox(
                width: 64,
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ProfileViewScreen(userId: buddy.id),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundImage: buddy.photoUrl != null ? NetworkImage(buddy.photoUrl!) : null,
                        child: buddy.photoUrl == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        buddy.name?.isNotEmpty == true ? buddy.name! : 'Buddy',
                        style: const TextStyle(fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
