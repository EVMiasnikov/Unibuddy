import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../models/profile_review.dart';
import '../models/user.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';
import '../widgets/main_bottom_bar.dart';
import 'profile_setup_screen.dart';
import 'reviews_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;

  const ProfileViewScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ProfileViewScreen> createState() =>
      _ProfileViewScreenState();
}

class _ProfileViewScreenState
    extends State<ProfileViewScreen> {
  final UserService _userService =
      UserService();

  final ReviewService _reviewService =
      ReviewService();

  User? _user;

  List<ProfileReview> _reviews = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user =
          await _userService.getProfile(
        widget.userId,
        '',
      );

      // Review failure should not prevent
      // the basic profile from opening.
      List<ProfileReview> reviews = [];

      try {
        reviews =
            await _reviewService
                .getReviewsForUser(
          widget.userId,
        );
      } catch (_) {
        reviews = [];
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _user = user;
        _reviews = reviews;
        _isLoading = false;
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

        _isLoading = false;
      });
    }
  }

  Future<void> _editProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            const ProfileSetupScreen(),
      ),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _loadProfile();
  }

  double get _averageRating {
    if (_reviews.isEmpty) {
      return 0;
    }

    final total = _reviews.fold<int>(
      0,
      (sum, review) =>
          sum + review.rating,
    );

    return total / _reviews.length;
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile =
        context
                .watch<AuthController>()
                .currentUser
                ?.id ==
            widget.userId;

    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Profile'),

        actions: [
          if (isOwnProfile)
            IconButton(
              icon: const Icon(
                Icons.edit_outlined,
              ),
              tooltip: 'Edit profile',
              onPressed: _editProfile,
            ),
        ],
      ),

      body: _buildBody(),

      bottomNavigationBar:
          const MainBottomBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child:
            CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding:
              const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.center,

            children: [
              const Icon(
                Icons.error_outline,
                size: 48,
              ),

              const SizedBox(height: 12),

              Text(
                _errorMessage!,
                textAlign:
                    TextAlign.center,
              ),

              const SizedBox(height: 16),

              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _errorMessage = null;
                  });

                  _loadProfile();
                },

                child:
                    const Text(
                  'Try again',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_user == null) {
      return const Center(
        child: Text(
          'Profile not found.',
        ),
      );
    }

    final user = _user!;

    return ListView(
      padding:
          const EdgeInsets.all(24),

      children: [
        // =============================
        // Avatar
        // =============================

        Center(
          child: CircleAvatar(
            radius: 52,

            backgroundImage:
                user.photoUrl != null
                    ? NetworkImage(
                        user.photoUrl!,
                      )
                    : null,

            child:
                user.photoUrl == null
                    ? const Icon(
                        Icons.person,
                        size: 52,
                      )
                    : null,
          ),
        ),

        const SizedBox(height: 16),

        // =============================
        // Name
        // =============================

        Center(
          child: Text(
            user.fullName.isNotEmpty
                ? user.fullName
                : 'User',

            style:
                const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),
        ),

        const SizedBox(height: 28),

        // =============================
        // University
        // =============================

        if (user.university != null &&
            user.university!
                .isNotEmpty)
          _ProfileRow(
            icon:
                Icons.school_outlined,
            title: 'University',
            value:
                user.university!,
          ),

        // =============================
        // Country
        // =============================

        if (user.country != null &&
            user.country!.isNotEmpty)
          _ProfileRow(
            icon:
                Icons.public_outlined,
            title: 'Country',
            value:
                user.country!,
          ),

        // =============================
        // City
        // =============================

        if (user.city != null &&
            user.city!.isNotEmpty)
          _ProfileRow(
            icon:
                Icons.location_on_outlined,
            title: 'City',
            value:
                user.city!,
          ),

        // =============================
        // Academic Position
        // =============================

        if (user.position != null)
          _ProfileRow(
            icon:
                Icons.badge_outlined,
            title:
                'Academic position',
            value:
                user.position!.label,
          ),

        // =============================
        // Age
        // =============================

        if (user.age != null)
          _ProfileRow(
            icon:
                Icons.cake_outlined,
            title: 'Age',
            value:
                user.age.toString(),
          ),

        // =============================
        // Sex
        // =============================

        if (user.sex != null)
          _ProfileRow(
            icon:
                Icons.person_outline,
            title: 'Sex',
            value:
                user.sex!.label,
          ),

        // =============================
        // Languages
        // =============================

        if (user.languages
            .isNotEmpty) ...[
          const SizedBox(height: 20),

          const Text(
            'Languages',
            style:
                TextStyle(
              fontSize: 17,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children:
                user.languages.map(
              (language) {
                return Chip(
                  label:
                      Text(language),
                );
              },
            ).toList(),
          ),
        ],

        // =====================================================
        // REVIEWS
        // =====================================================

        const SizedBox(height: 28),

        const Divider(),

        const SizedBox(height: 18),

        const Text(
          'Reviews',
          style: TextStyle(
            fontSize: 17,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        if (_reviews.isEmpty)
          const Text(
            'No reviews yet.',
            style: TextStyle(
              color: Colors.grey,
            ),
          )
        else
          Row(
            children: [
              const Icon(
                Icons.star,
                size: 24,
              ),

              const SizedBox(width: 6),

              Text(
                _averageRating
                    .toStringAsFixed(1),

                style:
                    const TextStyle(
                  fontSize: 19,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(width: 8),

              Text(
                '· ${_reviews.length} '
                '${_reviews.length == 1 ? 'review' : 'reviews'}',

                style:
                    const TextStyle(
                  fontSize: 15,
                  color: Colors.grey,
                ),
              ),
            ],
          ),

        const SizedBox(height: 12),

        SizedBox(
          width: double.infinity,

          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ReviewsScreen(
                    userId:
                        widget.userId,
                  ),
                ),
              );
            },

            icon: const Icon(
              Icons.reviews_outlined,
            ),

            label:
                const Text(
              'View Reviews',
            ),
          ),
        ),

        const SizedBox(height: 20),
      ],
    );
  }
}

class _ProfileRow
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 10,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 22,
          ),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        Colors.grey,
                  ),
                ),

                const SizedBox(
                  height: 3,
                ),

                Text(
                  value,
                  style:
                      const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}