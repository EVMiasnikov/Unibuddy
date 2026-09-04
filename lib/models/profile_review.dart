class ProfileReview {
  final String requestId;

  /// Person who wrote this review.
  final String reviewerId;

  /// 1 - 5 stars.
  final int rating;

  /// Optional written feedback.
  final String comment;

  /// When this feedback was submitted.
  ///
  /// Can be null for old reviews created
  /// before feedback timestamps were added.
  final DateTime? createdAt;

  const ProfileReview({
    required this.requestId,
    required this.reviewerId,
    required this.rating,
    required this.comment,
    this.createdAt,
  });
}