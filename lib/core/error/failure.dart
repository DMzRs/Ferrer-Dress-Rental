class Failure {
  final String message;
  final String? code;

  const Failure(this.message, {this.code});

  @override
  String toString() => message;
}

class AuthFailure extends Failure {
  const AuthFailure(super.message, {super.code});
}

/// The Google email already has a password account. The UI must prompt for
/// the password once and call linkGoogleAccount — not show an error.
class GoogleLinkRequired extends AuthFailure {
  final String email;

  const GoogleLinkRequired(this.email)
      : super('This email already uses password sign-in.',
            code: 'account-exists-with-different-credential');
}

class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.code});
}

class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.code});
}
