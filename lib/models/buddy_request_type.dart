import 'package:flutter/material.dart';

/// A buddy request can go one of two directions:
/// - offerBuddy: "I want to be a buddy" (I'll help/mentor someone)
/// - seekBuddy:  "I want a buddy" (I want someone to help/mentor me)
enum BuddyRequestType { offerBuddy, seekBuddy }

extension BuddyRequestTypeLabel on BuddyRequestType {
  String get title {
    switch (this) {
      case BuddyRequestType.offerBuddy:
        return 'Offer to be a Buddy';
      case BuddyRequestType.seekBuddy:
        return 'Request a Buddy';
    }
  }

  String get description {
    switch (this) {
      case BuddyRequestType.offerBuddy:
        return "You're offering to help and guide another student.";
      case BuddyRequestType.seekBuddy:
        return "You're looking for a buddy to help guide you.";
    }
  }

  IconData get icon {
    switch (this) {
      case BuddyRequestType.offerBuddy:
        return Icons.volunteer_activism_outlined;
      case BuddyRequestType.seekBuddy:
        return Icons.handshake_outlined;
    }
  }
}