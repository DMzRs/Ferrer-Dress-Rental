import 'package:ferrer_rental_shop/features/auth/data/datasources/auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:flutter_test/flutter_test.dart';

class _ThrottledDataSource implements AuthDataSource {
  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Stream<String> get emailLinkStream => const Stream.empty();

  @override
  Stream<int> usersCountStream() => const Stream.empty();

  @override
  Future<AppUser> signIn({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AppUser> signUp(
          {required String fullName,
          required String email,
          required String phone,
          required String password}) =>
      throw UnimplementedError();

  @override
  Future<void> sendPasswordReset(String email) => throw Exception(
      '[firebase_auth/too-many-requests] We have blocked all requests from this device due to unusual activity. Try again later.');

  @override
  Future<void> sendSignInLink(String email) => throw UnimplementedError();

  @override
  Future<AppUser> signInWithEmailLink(
          {required String email,
          required String link,
          String? fullName,
          String? phone,
          String? password}) =>
      throw UnimplementedError();

  @override
  Future<void> signOut() async {}

  @override
  Future<void> updateProfile(
          {String? fullName,
          String? phone,
          String? address,
          List<String>? savedPlaces}) =>
      throw UnimplementedError();
}

void main() {
  test('throttle errors map to a friendly retry message', () async {
    final repo = AuthRepositoryImpl(_ThrottledDataSource());
    final result = await repo.sendPasswordReset('a@b.com');
    expect(result.isSuccess, isFalse);
    expect(result.failure?.message, contains('Too many attempts'));
    expect(result.failure?.message, isNot(contains('firebase_auth')));
  });
}
