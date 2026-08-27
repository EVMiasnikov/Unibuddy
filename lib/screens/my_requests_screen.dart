import 'package:flutter/material.dart';

/// Groups all of the current user's buddy-request activity in one place.
/// Each tab is empty for now - will be filled in once requests are
/// actually stored/fetched from Firestore.
class MyRequestsScreen extends StatelessWidget {
  const MyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Requests'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Published by me'),
              Tab(text: 'Taken by me'),
              Tab(text: 'Accepted by my buddy'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _EmptyRequestsTab(message: "Requests you've published will show up here."),
            _EmptyRequestsTab(message: "Requests you've taken (accepted from someone else) will show up here."),
            _EmptyRequestsTab(message: "Your own requests that a buddy has accepted will show up here."),
          ],
        ),
      ),
    );
  }
}

class _EmptyRequestsTab extends StatelessWidget {
  final String message;

  const _EmptyRequestsTab({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inbox_outlined, size: 56, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}