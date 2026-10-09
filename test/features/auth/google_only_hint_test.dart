import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

/// Firebase v6 removed provider lookup, so a credential failure cannot name
/// the account's method. The error therefore covers both cases at once.
class _HintAuthRepository implements AuthRepository {
  _HintAuthRepository({this.signInFailure = 'Incorrect email or password.'});

  final String signInFailure;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(null);

  @override
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) async =>
      Err(AuthFailure(signInFailure));

  @override
  Future<Result<AppUser>> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendPasswordReset(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<void>> sendSignInLink(String email) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<Result<AppUser>> linkGoogleAccount(
          {required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> createAdmin(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<Result<AppUser>> updateUserRole(
          {required String uid, required UserRole role}) =>
      throw UnimplementedError();

  @override
  Stream<String> emailLinkStream() => Stream<String>.empty();

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();

  @override
  Stream<int> usersCountStream() => Stream<int>.empty();

  @override
  Stream<List<AppUser>> watchUsers() => Stream<List<AppUser>>.value([]);
}

void main() {
  test('credential failure names Google and Forgot Password', () async {
    final vm = AuthViewModel(_HintAuthRepository());
    addTearDown(vm.dispose);
    final ok = await vm.signIn('gina@example.com', 'whatever');
    expect(ok, isFalse);
    expect(vm.error, contains('Google'));
    expect(vm.error, contains('Forgot Password'));
  });

  test('non-credential failure keeps the generic error', () async {
    final vm = AuthViewModel(_HintAuthRepository(
        signInFailure:
            'Too many attempts. Please wait a few minutes and try again.'));
    addTearDown(vm.dispose);
    final ok = await vm.signIn('gina@example.com', 'whatever');
    expect(ok, isFalse);
    expect(vm.error, isNot(contains('Google')));
  });
}
