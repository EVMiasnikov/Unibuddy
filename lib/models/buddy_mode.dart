import 'package:flutter/material.dart';

/// A buddy request can go one of two directions:
/// - offerBuddy: "I want to be a buddy" (I'll help/mentor someone)
/// - seekBuddy:  "I want a buddy" (I want someone to help/mentor me)
enum BuddyMode { offerBuddy, seekBuddy }

extension BuddyModeLabel on BuddyMode {
  String get title {
    switch (this) {
      case BuddyMode.offerBuddy:
        return 'Offer to be a Buddy';
      case BuddyMode.seekBuddy:
        return 'Request a Buddy';
    }
  }

  String get description {
    switch (this) {
      case BuddyMode.offerBuddy:
        return "You're offering to help and guide another student.";
      case BuddyMode.seekBuddy:
        return "You're looking for a buddy to help guide you.";
    }
  }

  IconData get icon {
    switch (this) {
      case BuddyMode.offerBuddy:
        return Icons.volunteer_activism_outlined;
      case BuddyMode.seekBuddy:
        return Icons.handshake_outlined;
    }
  }
}