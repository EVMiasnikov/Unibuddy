import 'package:flutter/material.dart';

import '../services/buddy_search_service.dart';
import 'profile_view_screen.dart';

class BuddySearchScreen
    extends StatefulWidget {
  final String city;
  final String currentUserId;

  const BuddySearchScreen({
    super.key,
    required this.city,
    required this.currentUserId,
  });

  @override
  State<BuddySearchScreen>
      createState() =>
          _BuddySearchScreenState();
}

class _BuddySearchScreenState
    extends State<BuddySearchScreen> {
  final _searchController =
      TextEditingController();

  final BuddySearchService _service =
      BuddySearchService();

  List<BuddySearchResult> _results =
      [];

  bool _isLoading = false;
  bool _hasSearched = false;
  String? _errorMessage;

  @override
  void dispose() {
    _searchController.dispose();

    super.dispose();
  }

  Future<void> _search() async {
    final query =
        _searchController.text.trim();

    if (query.isEmpty) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _hasSearched = true;
    });

    try {
      final results =
          await _service.searchBuddies(
        query: query,
        city: widget.city,
        currentUserId:
            widget.currentUserId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = e
            .toString()
            .replaceFirst(
              'Exception: ',
              '',
            );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Select a Buddy',
        ),
      ),

      body: Padding(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            Text(
              'Only buddies in ${widget.city} who are currently accepting requests are shown.',
              style:
                  const TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:
                        _searchController,

                    decoration:
                        const InputDecoration(
                      labelText:
                          'Buddy name',
                      hintText:
                          'e.g. Marco',
                      prefixIcon:
                          Icon(
                        Icons.search,
                      ),
                      border:
                          OutlineInputBorder(),
                    ),

                    onSubmitted:
                        (_) => _search(),
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                FilledButton(
                  onPressed:
                      _isLoading
                          ? null
                          : _search,

                  child:
                      const Text(
                    'Search',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          textAlign:
              TextAlign.center,
        ),
      );
    }

    if (!_hasSearched) {
      return const Center(
        child: Text(
          'Search for a buddy by name.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return const Center(
        child: Text(
          'No buddies found.',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount:
          _results.length,

      separatorBuilder:
          (_, _) =>
              const SizedBox(
        height: 8,
      ),

      itemBuilder:
          (context, index) {
        final buddy =
            _results[index];

        return Card(
          child: Padding(
            padding:
                const EdgeInsets.all(
              12,
            ),

            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,

                  backgroundImage:
                      buddy.photoUrl !=
                                  null &&
                              buddy
                                  .photoUrl!
                                  .isNotEmpty
                          ? NetworkImage(
                              buddy
                                  .photoUrl!,
                            )
                          : null,

                  child:
                      buddy.photoUrl ==
                                  null ||
                              buddy
                                  .photoUrl!
                                  .isEmpty
                          ? const Icon(
                              Icons.person,
                            )
                          : null,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        buddy.fullName,

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),

                      if (buddy.university !=
                              null &&
                          buddy
                              .university!
                              .isNotEmpty)
                        Text(
                          buddy.university!,
                        ),

                      if (buddy.city !=
                              null &&
                          buddy.city!
                              .isNotEmpty)
                        Text(
                          buddy.city!,
                          style:
                              const TextStyle(
                            color:
                                Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProfileViewScreen(
                              userId:
                                  buddy.id,
                            ),
                          ),
                        );
                      },

                      child:
                          const Text(
                        'Profile',
                      ),
                    ),

                    FilledButton(
                      onPressed: () {
                        Navigator.of(
                          context,
                        ).pop(buddy);
                      },

                      child:
                          const Text(
                        'Select',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}