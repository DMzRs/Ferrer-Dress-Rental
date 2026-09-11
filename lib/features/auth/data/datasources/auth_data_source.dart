import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

abstract class AuthDataSource {
  Stream<AppUser?> get authStateChanges;

  Future<AppUser> signIn({required String email, required String password});

  Future<AppUser> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> sendPasswordReset(String email);

  Future<void> requestEmailOtp(String email);

  Future<void> verifyEmailOtp({required String email, required String code});

  Future<void> signOut();

  /// Updates the signed-in user's profile doc. Only provided fields change.
  Future<void> updateProfile({String? fullName, String? phone, String? address, List<String>? savedPlaces});

  Stream<int> usersCountStream();
}

