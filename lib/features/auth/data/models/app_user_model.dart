import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

class AppUserModel extends AppUser {
  const AppUserModel({
    required super.uid,
    required super.fullName,
    required super.email,
    required super.phone,
    super.address,
    super.savedPlaces,
    required super.role,
  });

  factory AppUserModel.fromMap(String uid, Map<String, dynamic> map) {
    return AppUserModel(
      uid: uid,
      fullName: (map['fullName'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      address: (map['address'] ?? '') as String,
      savedPlaces:
          ((map['savedPlaces'] as List?) ?? []).map((e) => e.toString()).toList(),
      role: map['role'] == 'admin' ? UserRole.admin : UserRole.customer,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'address': address,
      'savedPlaces': savedPlaces,
      'role': role == UserRole.admin ? 'admin' : 'customer',
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}

