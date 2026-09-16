class Review {
  final String rentalId;
  final String userId;
  final String userName;
  final String itemId;
  final String itemName;
  final int stars;
  final String comment;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Review({
    required this.rentalId,
    required this.userId,
    this.userName = '',
    required this.itemId,
    this.itemName = '',
    this.stars = 0,
    this.comment = '',
    required this.createdAt,
    this.updatedAt,
  });

  bool get hasComment => comment.trim().isNotEmpty;
}
