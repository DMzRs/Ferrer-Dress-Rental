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

  /// Passwordless email-link signup step 1: sends the sign-in link.
  Future<void> sendSignInLink(String email);

  /// Passwordless email-link signup step 2: completes sign-in with the link
  /// the user tapped, then attaches the password login + profile so the
  /// account works with both. Emits incoming app links that look like
  /// Firebase email sign-in links (empty when unsupported, e.g. mock).
  Future<AppUser> signInWithEmailLink({
    required String email,
    required String link,
    String? fullName,
    String? phone,
    String? password,
  });

  /// Raw incoming deep links filtered to Firebase email sign-in links.
  Stream<String> get emailLinkStream;

  Future<void> signOut();

  /// Updates the signed-in user's profile doc. Only provided fields change.
  Future<void> updateProfile({String? fullName, String? phone, String? address, List<String>? savedPlaces});

  Stream<int> usersCountStream();
}

