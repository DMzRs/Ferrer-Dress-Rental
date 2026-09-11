import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthRepository implements AuthRepository {
  bool failRequest = false;
  bool failVerify = false;
  String failureMessage = 'boom';

  @override
  Stream<AppUser?> get authStateChanges => const Stream.empty();

  @override
  Future<Result<AppUser>> signIn({required String email, required String password}) async =>
      Err(const AuthFailure('not used'));

  @override
  Future<Result<AppUser>> signUp({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async => Err(const AuthFailure('not used'));

  @override
  Future<Result<void>> sendPasswordReset(String email) async => const Success(null);

  @override
  Future<Result<void>> requestEmailOtp(String email) async {
    if (failRequest) return Err(AuthFailure(failureMessage));
    return const Success(null);
  }

  @override
  Future<Result<void>> verifyEmailOtp({required String email, required String code}) async {
    if (failVerify) return Err(AuthFailure(failureMessage));
    return const Success(null);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<Result<void>> updateProfile({
    String? fullName,
    String? phone,
    String? address,
    List<String>? savedPlaces,
  }) async => const Success(null);

  @override
  Stream<int> usersCountStream() => const Stream.empty();
}

void main() {
  group('AuthViewModel OTP state machine', () {
    test('sendOtp transitions idle->sending->codeSent', () async {
      final vm = AuthViewModel(FakeAuthRepository());
      expect(vm.otpState, OtpState.idle);
      final ok = await vm.sendOtp('j@x.com');
      expect(ok, isTrue);
      expect(vm.otpState, OtpState.codeSent);
      expect(vm.resendCooldownSeconds, 60);
      expect(vm.otpError, isNull);
      vm.dispose();
    });

    test('sendOtp failure returns to idle with otpError', () async {
      final repo = FakeAuthRepository()..failRequest = true;
      final vm = AuthViewModel(repo);
      final ok = await vm.sendOtp('j@x.com');
      expect(ok, isFalse);
      expect(vm.otpState, OtpState.idle);
      expect(vm.otpError, 'boom');
      vm.dispose();
    });

    test('confirmOtp success transitions to verified', () async {
      final vm = AuthViewModel(FakeAuthRepository());
      await vm.sendOtp('j@x.com');
      final ok = await vm.confirmOtp(email: 'j@x.com', code: '123456');
      expect(ok, isTrue);
      expect(vm.otpState, OtpState.verified);
      expect(vm.otpError, isNull);
      vm.dispose();
    });

    test('wrong-code path keeps codeSent and sets otpError', () async {
      final repo = FakeAuthRepository()..failVerify = true;
      final vm = AuthViewModel(repo);
      await vm.sendOtp('j@x.com');
      final ok = await vm.confirmOtp(email: 'j@x.com', code: '000000');
      expect(ok, isFalse);
      expect(vm.otpState, OtpState.codeSent);
      expect(vm.otpError, 'boom');
      vm.dispose();
    });

    test('new attempt clears previous otpError', () async {
      final repo = FakeAuthRepository()..failVerify = true;
      final vm = AuthViewModel(repo);
      await vm.sendOtp('j@x.com');
      await vm.confirmOtp(email: 'j@x.com', code: '000000');
      expect(vm.otpError, isNotNull);
      repo.failVerify = false;
      final ok = await vm.confirmOtp(email: 'j@x.com', code: '123456');
      expect(ok, isTrue);
      expect(vm.otpError, isNull);
      vm.dispose();
    });

    test('resetOtp restores idle, clears error, zeroes cooldown', () async {
      final repo = FakeAuthRepository()..failVerify = true;
      final vm = AuthViewModel(repo);
      await vm.sendOtp('j@x.com');
      await vm.confirmOtp(email: 'j@x.com', code: '000000');
      vm.resetOtp();
      expect(vm.otpState, OtpState.idle);
      expect(vm.otpError, isNull);
      expect(vm.resendCooldownSeconds, 0);
      vm.dispose();
    });
  });
}
