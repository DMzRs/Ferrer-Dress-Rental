import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';

/// Thrown by [AuthDataSource.signInWithGoogle] when the Google email already
/// has a password account. Carries the email so the UI can prompt for the
/// password once and finish via [AuthDataSource.linkGoogleAccount].
class GoogleLinkRequiredException implements Exception {
  final String email;

  const GoogleLinkRequiredException(this.email);

  @override
  String toString() => 'GoogleLinkRequiredException: $email';
}

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

  /// Google sign-in. Throws [GoogleLinkRequiredException] when the Google
  /// email already has a password account (the pending credential is kept
  /// for [linkGoogleAccount]).
  Future<AppUser> signInWithGoogle();

  /// Links the pending Google credential after a password sign-in.
  Future<AppUser> linkGoogleAccount({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Updates the signed-in user's profile doc. Only provided fields change.
  Future<void> updateProfile({String? fullName, String? phone, String? address, List<String>? savedPlaces});

  Stream<int> usersCountStream();

  Stream<List<AppUser>> watchUsers();
}

