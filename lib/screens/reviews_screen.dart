import 'package:flutter/material.dart';

import '../models/profile_review.dart';
import '../models/user.dart';
import '../services/review_service.dart';
import '../services/user_service.dart';

class ReviewsScreen extends StatefulWidget {
  final String userId;

  const ReviewsScreen({
    super.key,
    required this.userId,
  });

  @override
  State<ReviewsScreen> createState() =>
      _ReviewsScreenState();
}

class _ReviewsScreenState
    extends State<ReviewsScreen> {
  final ReviewService _reviewService =
      ReviewService();

  List<ProfileReview> _reviews = [];

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews =
          await _reviewService
              .getReviewsForUser(
        widget.userId,
      );

      if (!mounted) {
        return;
      }

      setState(() {
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
    return Scaffold(
      // Navigator automatically gives us
      // the back arrow to Profile.
      appBar: AppBar(
        title: const Text(
          'Reviews',
        ),
      ),

      body: _buildBody(),
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

                  _loadReviews();
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

    if (_reviews.isEmpty) {
      return const Center(
        child: Text(
          'No reviews yet.',
        ),
      );
    }

    return ListView(
      padding:
          const EdgeInsets.all(20),

      children: [
        // =====================================================
        // SUMMARY
        // =====================================================

        Row(
          children: [
            const Icon(
              Icons.star,
              size: 26,
            ),

            const SizedBox(width: 6),

            Text(
              _averageRating
                  .toStringAsFixed(1),

              style:
                  const TextStyle(
                fontSize: 22,
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
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Divider(),

        // =====================================================
        // REVIEW LIST
        // =====================================================

        ..._reviews.map(
          (review) =>
              _ReviewCard(
            review: review,
          ),
        ),
      ],
    );
  }
}

class _ReviewCard
    extends StatelessWidget {
  final ProfileReview review;

  const _ReviewCard({
    required this.review,
  });

  String _formatDate(
    DateTime? date,
  ) {
    if (date == null) {
      return 'Date unavailable';
    }

    final minute =
        date.minute
            .toString()
            .padLeft(2, '0');

    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future:
          UserService().getUserById(
        review.reviewerId,
      ),

      builder: (context, snapshot) {
        final reviewer =
            snapshot.data;

        final name =
            reviewer != null &&
                    reviewer
                        .fullName
                        .isNotEmpty
                ? reviewer.fullName
                : 'User';

        final photoUrl =
            reviewer?.photoUrl;

        return Padding(
          padding:
              const EdgeInsets.symmetric(
            vertical: 18,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  CircleAvatar(
                    radius: 23,

                    backgroundImage:
                        photoUrl != null &&
                                photoUrl
                                    .isNotEmpty
                            ? NetworkImage(
                                photoUrl,
                              )
                            : null,

                    child:
                        photoUrl == null ||
                                photoUrl
                                    .isEmpty
                            ? Text(
                                name.isNotEmpty
                                    ? name[0]
                                        .toUpperCase()
                                    : '?',
                              )
                            : null,
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,

                      children: [
                        Text(
                          name,

                          style:
                              const TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),

                        const SizedBox(
                          height: 4,
                        ),

                        // Stars
                        Row(
                          children:
                              List.generate(
                            5,
                            (index) =>
                                Icon(
                              index <
                                      review
                                          .rating
                                  ? Icons.star
                                  : Icons
                                      .star_border,
                              size: 19,
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 5,
                        ),

                        Text(
                          _formatDate(
                            review
                                .createdAt,
                          ),

                          style:
                              const TextStyle(
                            fontSize: 12,
                            color:
                                Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (review.comment
                  .trim()
                  .isNotEmpty) ...[
                const SizedBox(
                  height: 12,
                ),

                Padding(
                  padding:
                      const EdgeInsets.only(
                    left: 58,
                  ),

                  child: Text(
                    review.comment,

                    style:
                        const TextStyle(
                      fontSize: 15,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              const Divider(),
            ],
          ),
        );
      },
    );
  }
}