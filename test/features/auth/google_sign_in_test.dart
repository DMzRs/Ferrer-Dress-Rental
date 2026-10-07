import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

const _googleUser = AppUser(
  uid: 'google-1',
  fullName: 'Gina Reyes',
  email: 'gina@example.com',
  phone: '',
  role: UserRole.customer,
);

class _FakeGoogleAuthRepository implements AuthRepository {
  _FakeGoogleAuthRepository({this.googleResult});

  Result<AppUser>? googleResult;
  String? linkedEmail;
  var _linked = false;

  @override
  Stream<AppUser?> get authStateChanges => Stream.value(_googleUser);

  @override
  Future<Result<AppUser>> signInWithGoogle() async {
    if (_linked) return const Success(_googleUser);
    return googleResult ?? const Success(_googleUser);
  }

  @override
  Future<Result<AppUser>> linkGoogleAccount(
      {required String email, required String password}) async {
    linkedEmail = email;
    _linked = true;
    return const Success(_googleUser);
  }

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
  Future<Result<AppUser>> signIn(
          {required String email, required String password}) =>
      throw UnimplementedError();

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
  test('signInWithGoogle success signs the user in', () async {
    final vm = AuthViewModel(_FakeGoogleAuthRepository());
    addTearDown(vm.dispose);
    final ok = await vm.signInWithGoogle();
    expect(ok, isTrue);
    expect(vm.error, isNull);
    expect(vm.user?.email, 'gina@example.com');
  });

  test('signInWithGoogle failure surfaces the error', () async {
    final vm = AuthViewModel(_FakeGoogleAuthRepository(
      googleResult: const Err(AuthFailure('Google sign-in failed.')),
    ));
    addTearDown(vm.dispose);
    final ok = await vm.signInWithGoogle();
    expect(ok, isFalse);
    expect(vm.error, 'Google sign-in failed.');
  });

  test('account collision exposes link email instead of an error', () async {
    final vm = AuthViewModel(_FakeGoogleAuthRepository(
      googleResult:
          const Err(GoogleLinkRequired('maria@example.com')),
    ));
    addTearDown(vm.dispose);
    final ok = await vm.signInWithGoogle();
    expect(ok, isFalse);
    expect(vm.error, isNull);
    expect(vm.googleLinkEmail, 'maria@example.com');
  });

  test('linkGoogleWithPassword links then clears the collision', () async {
    final repo = _FakeGoogleAuthRepository(
      googleResult: const Err(GoogleLinkRequired('maria@example.com')),
    );
    final vm = AuthViewModel(repo);
    addTearDown(vm.dispose);
    await vm.signInWithGoogle();
    expect(vm.googleLinkEmail, 'maria@example.com');
    final ok = await vm.linkGoogleWithPassword('ferrer123');
    expect(ok, isTrue);
    expect(repo.linkedEmail, 'maria@example.com');
    expect(vm.googleLinkEmail, isNull);
  });
}
