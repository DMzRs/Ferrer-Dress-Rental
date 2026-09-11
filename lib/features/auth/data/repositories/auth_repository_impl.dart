import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';

import '../datasources/auth_data_source.dart';
import '../datasources/firebase_auth_data_source.dart';
import '../datasources/mock_auth_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._dataSource);

  final AuthDataSource _dataSource;

  static AuthDataSource defaultDataSource() =>
      AppConfig.firebaseEnabled ? FirebaseAuthDataSource() : MockAuthDataSource();

  @override
  Stream<AppUser?> get authStateChanges => _dataSource.authStateChanges;

  Future<Result<T>> _safe<T>(Future<T> Function() action) async {
    try {
      return Success(await action());
    } catch (e) {
      return Err(AuthFailure(_friendly(e)));
    }
  }

  String _friendly(Object e) {
    final message = e.toString().replaceFirst('Exception: ', '');
    if (message.contains('invalid-credential') ||
        message.contains('wrong-password')) {
      return 'Incorrect email or password.';
    }
    if (message.contains('email-already-in-use')) {
      return 'This email is already registered.';
    }
    if (message.contains('network')) return 'Please check your internet connection.';
    return message;
  }

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) {
    return _safe(() => _dataSource.signIn(email: email, password: password));
  }

  @override
  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) {
    return _safe(() => _dataSource.signUp(
          fullName: fullName,
          email: email,
          phone: phone,
          password: password,
        ));
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) {
    return _safe(() => _dataSource.sendPasswordReset(email));
  }

  @override
  Future<Result<void>> requestEmailOtp(String email) {
    return _safe(() => _dataSource.requestEmailOtp(email));
  }

  @override
  Future<Result<void>> verifyEmailOtp({required String email, required String code}) {
    return _safe(() => _dataSource.verifyEmailOtp(email: email, code: code));
  }

  @override
  Future<void> signOut() => _dataSource.signOut();

  @override
  Future<Result<void>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) {
    return _safe(() => _dataSource.updateProfile(
          fullName: fullName,
          phone: phone,
          address: address,
          savedPlaces: savedPlaces,
        ));
  }

  @override
  Stream<int> usersCountStream() => _dataSource.usersCountStream();
}
