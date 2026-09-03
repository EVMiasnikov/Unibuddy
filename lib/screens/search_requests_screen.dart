import 'package:flutter/material.dart';

/// Lets a student browse/search buddy requests published by other
/// students, so they can find one to accept. Empty for now - will
/// be filled in once requests are actually stored/fetched from Firestore.
class SearchRequestsScreen extends StatelessWidget {
  const SearchRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Browse Requests')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Available buddy requests from other students will show up here.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
