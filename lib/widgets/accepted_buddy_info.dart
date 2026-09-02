import 'package:flutter/material.dart';

import '../models/user.dart';
import '../services/user_service.dart';


class AcceptedBuddyInfo extends StatelessWidget {

  final String buddyId;

  const AcceptedBuddyInfo({
    super.key,
    required this.buddyId,
  });


  Future<User?> _loadBuddy() {
    return UserService().getUserById(buddyId);
  }


  @override
  Widget build(BuildContext context) {

    return FutureBuilder<User?>(
      future: _loadBuddy(),

      builder: (context, snapshot) {

        if (snapshot.connectionState ==
            ConnectionState.waiting) {

          return const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 8,
            ),

            child: Text(
              'Loading buddy information...',
            ),
          );
        }


        final buddy = snapshot.data;


        if (buddy == null) {

          return const Text(
            'Buddy information unavailable',
            style: TextStyle(
              color: Colors.grey,
            ),
          );
        }


        return Row(
          children: [

            const Icon(
              Icons.person_outline,
              size: 18,
            ),

            const SizedBox(
              width: 6,
            ),

            Text(
              'Accepted by ${buddy.fullName}',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),

          ],
        );
      },
    );
  }
}