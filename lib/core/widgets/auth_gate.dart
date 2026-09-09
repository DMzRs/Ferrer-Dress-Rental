import 'package:flutter/material.dart';

import 'package:ferrer_rental_shop/features/admin/admin_shell.dart';
import 'package:ferrer_rental_shop/features/auth/domain/entities/app_user.dart';
import 'package:ferrer_rental_shop/features/auth/domain/repositories/auth_repository.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/views/login_screen.dart';
import 'package:ferrer_rental_shop/features/shell/presentation/views/user_shell.dart';
import 'app_logo.dart';
import '../constants/app_colors.dart';

class AuthGate extends StatelessWidget {
  final AuthRepository authRepository;

  const AuthGate({super.key, required this.authRepository});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppUser?>(
      stream: authRepository.authStateChanges,
      builder: (context, snapshot) {
        // Splash only until the stream's first event arrives. A `null`
        // user is a valid event (signed out) and must fall through to
        // the login screen.
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _SplashScreen();
        }
        final user = snapshot.data;
        if (user == null) return const LoginScreen();
        return user.isAdmin ? const AdminShell() : const UserShell();
      },
    );
  }
}

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.creamGradient),
      child: Center(
        child: FadeTransition(
          opacity: _fade,
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppLogo(size: 88),
              SizedBox(height: 18),
              Text(
                'Ferrer',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: AppColors.ink,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'CLOTHING RENTAL',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

