import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../controllers/auth_controller.dart';
import '../screens/login_screen.dart';

enum _ProfileMenuAction { viewProfile, logout }

/// The avatar button in the top-right of the AppBar.
/// Tapping it opens a small popup with the user's info and quick actions.
class ProfileMenuButton extends StatelessWidget {
  const ProfileMenuButton({super.key});

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthController>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().currentUser;

    return PopupMenuButton<_ProfileMenuAction>(
      tooltip: 'Account',
      offset: const Offset(0, 48),
      icon: CircleAvatar(
        radius: 18,
        backgroundImage: (user?.photoUrl != null) ? NetworkImage(user!.photoUrl!) : null,
        child: user?.photoUrl == null ? const Icon(Icons.person) : null,
      ),
      itemBuilder: (context) => [
        // Non-selectable header showing who's logged in.
        PopupMenuItem<_ProfileMenuAction>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user?.fullName.isNotEmpty == true ? user!.fullName : 'Your profile',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (user?.email != null)
                Text(
                  user!.email,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem<_ProfileMenuAction>(
          value: _ProfileMenuAction.viewProfile,
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('View profile'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
        const PopupMenuItem<_ProfileMenuAction>(
          value: _ProfileMenuAction.logout,
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Log out'),
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ],
      onSelected: (action) {
        switch (action) {
          case _ProfileMenuAction.viewProfile:
            // TODO: navigate to a dedicated profile screen once it exists
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile screen coming soon')),
            );
            break;
          case _ProfileMenuAction.logout:
            _logout(context);
            break;
        }
      },
    );
  }
}