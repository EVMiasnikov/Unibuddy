import 'package:flutter/material.dart';
import '../models/buddy_request_type.dart';

/// Used for both "Offer to be a Buddy" and "Request a Buddy" -
/// same shape of screen, different type/title/icon. The real form
/// (details, availability, etc.) gets built once the data model
/// for a buddy request is defined.
class CreateBuddyRequestScreen extends StatelessWidget {
  final BuddyRequestType type;

  const CreateBuddyRequestScreen({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(type.title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(type.icon, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(
                type.description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              const Text('(Form coming soon)', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
}