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

  /// Google sign-in. Fails with [GoogleLinkRequired] when the Google email
  /// already has a password account — the UI must then call
  /// [linkGoogleAccount] once with the password.
  Future<Result<AppUser>> signInWithGoogle();

  /// Signs in with email + password and links the pending Google credential
  /// from a previous [GoogleLinkRequired]. Throws when there is nothing
  /// pending (stale flow — the UI should restart Google sign-in).
  Future<Result<AppUser>> linkGoogleAccount({
    required String email,
    required String password,
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

  /// All user profiles, newest last. Admin-only server-side.
  Stream<List<AppUser>> watchUsers();
}

