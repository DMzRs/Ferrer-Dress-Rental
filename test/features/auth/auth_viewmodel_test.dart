import 'dart:async';

import 'package:ferrer_rental_shop/core/error/failure.dart';
import 'package:ferrer_rental_shop/core/utils/result.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

const _user = AppUser(
  uid: 'u1',
  fullName: 'Jane Doe',
  email: 'j@x.com',
  phone: '0917',
  role: UserRole.customer,
);

class FakeAuthRepository implements AuthRepository {
  bool failSend = false;
  bool failComplete = false;
  String failureMessage = 'boom';
  final linkController = StreamController<String>.broadcast();

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
  Future<Result<void>> sendSignInLink(String email) async {
    if (failSend) return Err(AuthFailure(failureMessage));
    return const Success(null);
  }

  @override
  Future<Result<AppUser>> signInWithEmailLink({
    required String email,
    required String link,
    String? fullName,
    String? phone,
    String? password,
  }) async {
    if (failComplete) return Err(AuthFailure(failureMessage));
    return const Success(_user);
  }

  @override
  Stream<String> emailLinkStream() => linkController.stream;

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

Future<bool> _send(AuthViewModel vm) {
  return vm.sendLink(
    fullName: 'Jane Doe',
    email: 'j@x.com',
    phone: '0917',
    password: 'secret123',
  );
}

void main() {
  group('AuthViewModel email-link state machine', () {
    test('sendLink transitions idle->linkSent', () async {
      final vm = AuthViewModel(FakeAuthRepository());
      expect(vm.linkState, EmailLinkState.idle);
      final ok = await _send(vm);
      expect(ok, isTrue);
      expect(vm.linkState, EmailLinkState.linkSent);
      expect(vm.resendCooldownSeconds, 60);
      expect(vm.linkError, isNull);
      vm.dispose();
    });

    test('sendLink failure returns to idle with linkError', () async {
      final repo = FakeAuthRepository()..failSend = true;
      final vm = AuthViewModel(repo);
      final ok = await _send(vm);
      expect(ok, isFalse);
      expect(vm.linkState, EmailLinkState.idle);
      expect(vm.linkError, 'boom');
      vm.dispose();
    });

    test('incoming link auto-completes signup', () async {
      final repo = FakeAuthRepository();
      final vm = AuthViewModel(repo);
      await _send(vm);
      repo.linkController.add('https://ferrer-rental-shop.firebaseapp.com/__/auth/handler?mode=signIn&oobCode=x');
      await Future.delayed(const Duration(milliseconds: 100));
      expect(vm.linkState, EmailLinkState.verified);
      expect(vm.user?.uid, 'u1');
      expect(vm.linkError, isNull);
      vm.dispose();
    });

    test('failed link completion stays linkSent with linkError', () async {
      final repo = FakeAuthRepository()..failComplete = true;
      final vm = AuthViewModel(repo);
      await _send(vm);
      final ok = await vm.completeWithLink('https://x/bad');
      expect(ok, isFalse);
      expect(vm.linkState, EmailLinkState.linkSent);
      expect(vm.linkError, 'boom');
      vm.dispose();
    });

    test('resetLink restores idle, clears error, zeroes cooldown', () async {
      final repo = FakeAuthRepository()..failComplete = true;
      final vm = AuthViewModel(repo);
      await _send(vm);
      await vm.completeWithLink('https://x/bad');
      vm.resetLink();
      expect(vm.linkState, EmailLinkState.idle);
      expect(vm.linkError, isNull);
      expect(vm.resendCooldownSeconds, 0);
      vm.dispose();
    });
  });
}
