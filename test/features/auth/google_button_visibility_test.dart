import 'package:ferrer_rental_shop/core/config/app_config.dart';
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
  testWidgets('mock mode hides the Google button', (t) async {
    AppConfig.firebaseEnabled = false;
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    expect(find.text('Continue with Google'), findsNothing);
  });

  testWidgets('firebase mode shows the Google button', (t) async {
    AppConfig.firebaseEnabled = true;
    addTearDown(() => AppConfig.firebaseEnabled = false);
    await t.pumpWidget(_harness());
    await t.pumpAndSettle();
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
