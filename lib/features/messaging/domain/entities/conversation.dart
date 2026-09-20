class Conversation {
  final String userId;
  final String userName;
  final String lastText;
  final String lastSenderRole;
  final DateTime? updatedAt;
  final DateTime? lastSeenCustomer;
  final DateTime? lastSeenAdmin;

  const Conversation({
    required this.userId,
    this.userName = '',
    this.lastText = '',
    this.lastSenderRole = '',
    this.updatedAt,
    this.lastSeenCustomer,
    this.lastSeenAdmin,
  });

  /// Unread for the customer: shop wrote last and it is newer than the
  /// customer's last open (null seen-stamp counts as unread).
  bool get unreadForCustomer {
    if (lastSenderRole != 'admin' || updatedAt == null) return false;
    final seen = lastSeenCustomer;
    if (seen == null) return true;
    return updatedAt!.isAfter(seen);
  }

  /// Unread for admin: customer wrote last and it is newer than last open.
  bool get unreadForAdmin {
    if (lastSenderRole != 'customer' || updatedAt == null) return false;
    final seen = lastSeenAdmin;
    if (seen == null) return true;
    return updatedAt!.isAfter(seen);
  }
}
