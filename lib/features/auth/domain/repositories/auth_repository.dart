import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Stream<AppUser?> get authStateChanges;

  Future<Result<AppUser>> signIn({required String email, required String password});

  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  });

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<void>> sendSignInLink(String email);

  Future<Result<AppUser>> signInWithEmailLink({
    required String email,
    required String link,
    String? fullName,
    String? phone,
    String? password,
  });

  Stream<String> emailLinkStream();

  Future<void> signOut();

  /// Updates the signed-in user's profile. Only provided fields change.
  Future<Result<void>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  });

  Stream<int> usersCountStream();
}

