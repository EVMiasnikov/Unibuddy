import 'package:flutter/material.dart';
import 'profile_view_screen.dart';

class AllBuddiesScreen extends StatelessWidget {
  final String city;
  final List<dynamic> buddies;

  const AllBuddiesScreen({
    super.key,
    required this.city,
    required this.buddies,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Buddies in $city'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        itemCount: buddies.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final buddy = buddies[index];

          final name =
              buddy.name?.isNotEmpty == true ? buddy.name! : 'Buddy';

          return InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfileViewScreen(
                    userId: buddy.id,
                  ),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: buddy.photoUrl != null
                        ? NetworkImage(buddy.photoUrl!)
                        : null,
                    child: buddy.photoUrl == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),

                  const SizedBox(width: 16),

                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}