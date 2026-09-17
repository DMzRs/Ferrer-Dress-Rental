import 'package:ferrer_rental_shop/features/auth/data/datasources/mock_auth_data_source.dart';
import 'package:ferrer_rental_shop/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/views/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

Widget _harness() {
  return ChangeNotifierProvider<AuthViewModel>(
    create: (_) =>
        AuthViewModel(AuthRepositoryImpl(MockAuthDataSource())),
    child: const MaterialApp(home: LoginScreen()),
  );
}

void main() {
  testWidgets('login mode has exactly one switch link', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    expect(find.text('Create Account'), findsOneWidget);
    expect(
        find.textContaining('Join us', findRichText: true), findsNothing);
    expect(find.text('Forgot Password?'), findsOneWidget);
  });

  testWidgets('signup mode has one back link, no forgot password', (t) async {
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    await t.ensureVisible(find.text('Create Account'));
    await t.pumpAndSettle();
    await t.tap(find.text('Create Account'));
    await t.pumpAndSettle();
    expect(find.text('FULL NAME'), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);
    expect(find.text('Forgot Password?'), findsNothing);
    expect(find.text('Back to Sign In'), findsNothing);
  });
}
