class Rental {
  final String id;
  final String userId;
  final String userName;
  final String itemId;
  final String itemName;
  final String itemCategory;
  final DateTime startDate;
  final DateTime endDate;
  final double rentalFee;
  final double securityDeposit;
  final double total;
  final String status;
  final String deliveryAddress;
  final DateTime createdAt;
  final DateTime? returnedAt;

  const Rental({
    required this.id,
    required this.userId,
    required this.userName,
    required this.itemId,
    required this.itemName,
    this.itemCategory = 'dress',
    required this.startDate,
    required this.endDate,
    required this.rentalFee,
    required this.securityDeposit,
    required this.total,
    required this.status,
    this.deliveryAddress = '',
    required this.createdAt,
    this.returnedAt,
  });

  bool get isActive => status == 'active';
  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isDeclined => status == 'declined';

  /// Awaiting the shop's confirmation decision, or already confirmed.
  bool get isConfirmedOrActive => isActive || isCompleted || isOverdue;

  bool get isOverdue =>
      isActive && DateTime.now().isAfter(_endOfDay(endDate));

  String get displayStatus {
    if (status == 'completed') return 'completed';
    if (status == 'cancelled') return 'cancelled';
    if (status == 'declined') return 'declined';
    if (status == 'pending') return 'pending';
    return isOverdue ? 'overdue' : 'active';
  }

  int get totalDays {
    final days =
        DateTime(endDate.year, endDate.month, endDate.day)
                .difference(DateTime(startDate.year, startDate.month, startDate.day))
                .inDays +
            1;
    return days < 1 ? 1 : days;
  }

  int get daysElapsed {
    final elapsed = DateTime.now().difference(
      DateTime(startDate.year, startDate.month, startDate.day),
    );
    return elapsed.inDays.clamp(0, totalDays);
  }

  int get daysRemaining => (totalDays - daysElapsed).clamp(0, totalDays);

  double get progress => isCompleted ? 1 : (daysElapsed / totalDays).clamp(0.0, 1.0);

  DateTime _endOfDay(DateTime d) => DateTime(d.year, d.month, d.day, 23, 59, 59);
}
