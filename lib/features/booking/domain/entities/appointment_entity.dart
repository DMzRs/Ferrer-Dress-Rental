class Appointment {
  final String id;
  final String userId;
  final String userName;
  final String? itemId;
  final String? itemName;
  final String purpose;
  final DateTime scheduledAt;
  final String status;

  /// Admin-provided explanation, present when status == declined.
  final String declineReason;
  final DateTime createdAt;

  const Appointment({
    required this.id,
    required this.userId,
    required this.userName,
    this.itemId,
    this.itemName,
    required this.purpose,
    required this.scheduledAt,
    required this.status,
    this.declineReason = '',
    required this.createdAt,
  });

  static const List<String> purposes = ['Measuring', 'Trying On'];

  // Lifecycle: pending (customer request) -> confirmed | declined; the
  // customer may cancel a request. 'scheduled' is the legacy confirmed value.
  static const String statusPending = 'pending';
  static const String statusConfirmed = 'confirmed';
  static const String statusDeclined = 'declined';
  static const String statusCancelled = 'cancelled';

  bool get isUpcoming =>
      (status == statusPending ||
          status == statusConfirmed ||
          status == 'scheduled') &&
      scheduledAt.isAfter(DateTime.now());

  bool get isPast => scheduledAt.isBefore(DateTime.now());

  String get statusLabel {
    switch (status) {
      case statusPending:
        return 'Pending';
      case statusConfirmed:
      case 'scheduled':
        return 'Scheduled';
      case statusDeclined:
        return 'Declined';
      case statusCancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}
