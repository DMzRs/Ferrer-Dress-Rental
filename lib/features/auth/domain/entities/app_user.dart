enum UserRole { customer, admin }

class AppUser {
  final String uid;
  final String fullName;
  final String email;
  final String phone;
  final String address;

  /// Named delivery addresses the user keeps for quick checkout, e.g.
  /// home, office, or event venue. Raw address strings, newest last.
  final List<String> savedPlaces;

  final UserRole role;

  const AppUser({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.phone,
    this.address = '',
    this.savedPlaces = const [],
    required this.role,
  });

  AppUser copyWith({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) {
    return AppUser(
      uid: uid,
      fullName: fullName ?? this.fullName,
      email: email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      savedPlaces: savedPlaces ?? this.savedPlaces,
      role: role,
    );
  }

  bool get isAdmin => role == UserRole.admin;

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}
