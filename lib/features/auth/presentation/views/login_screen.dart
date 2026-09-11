import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:ferrer_rental_shop/core/config/app_config.dart';
import 'package:ferrer_rental_shop/core/constants/app_colors.dart';
import 'package:ferrer_rental_shop/core/constants/app_strings.dart';
import 'package:ferrer_rental_shop/core/utils/validators.dart';
import 'package:ferrer_rental_shop/core/widgets/app_logo.dart';
import 'package:ferrer_rental_shop/core/widgets/common_widgets.dart';
import 'package:ferrer_rental_shop/features/auth/presentation/viewmodels/auth_viewmodel.dart';

enum AuthMode { login, signup }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AuthMode _mode = AuthMode.login;
  bool _obscure = true;
  bool _resetBusy = false;
  bool _canSubmit = false;

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();

  // Step 2 of signup: OTP code entry. Saved Step-1 details are snapshotted
  // into local vars so verify + signUp use exactly what was submitted.
  bool _otpStep = false;
  String _otpName = '';
  String _otpEmail = '';
  String _otpPhone = '';
  String _otpPassword = '';
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  late final List<FocusNode> _otpNodes;
  bool _settingOtpProgrammatically = false;

  AuthViewModel get _vm => context.read<AuthViewModel>();

  @override
  void initState() {
    super.initState();
    _otpNodes = List.generate(
      6,
      (i) => FocusNode(
        onKeyEvent: (node, event) {
          // Hardware-keyboard backspace on an empty box moves back.
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace &&
              _otpControllers[i].text.isEmpty &&
              i > 0) {
            _otpNodes[i - 1].requestFocus();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
      ),
    );
    for (final controller in [
      _emailController,
      _passwordController,
      _confirmPasswordController,
      _nameController,
      _phoneController,
    ]) {
      controller.addListener(_recheckValidity);
    }
  }

  /// The submit button stays pale until every visible field would pass
  /// the same validators the form runs on submit.
  bool _isValidFor(AuthMode mode) {
    final email = Validators.email(_emailController.text) == null;
    final password = Validators.password(_passwordController.text) == null;
    if (mode == AuthMode.login) return email && password;
    final confirmMatches = _confirmPasswordController.text.isNotEmpty &&
        _confirmPasswordController.text == _passwordController.text;
    return email &&
        password &&
        confirmMatches &&
        Validators.fullName(_nameController.text) == null &&
        Validators.phone(_phoneController.text) == null;
  }

  void _recheckValidity() {
    final valid = _isValidFor(_mode);
    if (valid != _canSubmit) {
      setState(() => _canSubmit = valid);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _otpNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _switchMode(AuthMode mode) {
    FocusScope.of(context).unfocus();
    _vm.resetOtp();
    _clearOtpBoxes();
    _clearOtpSnapshot();
    setState(() {
      _mode = mode;
      _otpStep = false;
      _canSubmit = _isValidFor(mode);
    });
  }

  void _clearOtpBoxes() {
    _settingOtpProgrammatically = true;
    try {
      for (final controller in _otpControllers) {
        controller.clear();
      }
    } finally {
      _settingOtpProgrammatically = false;
    }
  }

  void _clearOtpSnapshot() {
    _otpName = '';
    _otpEmail = '';
    _otpPhone = '';
    _otpPassword = '';
  }

  bool get _otpComplete =>
      _otpControllers.every((c) => c.text.isNotEmpty);

  /// Single-char UX is enforced here in [onChanged] rather than with a
  /// length limiter: a length-1 limiter would truncate an incoming paste to
  /// one box, while this keeps typed input to one digit per box and still
  /// distributes a full-code paste across all six.
  void _onOtpChanged(int index, String value) {
    if (_settingOtpProgrammatically) return;
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    _settingOtpProgrammatically = true;
    try {
      if (digits.length > 1) {
        // Full-code paste: fill all six boxes.
        for (var i = 0; i < 6; i++) {
          _otpControllers[i].text =
              i < digits.length ? digits[i] : '';
        }
      } else {
        // Typed input: keep only the latest digit.
        _otpControllers[index].text =
            digits.isEmpty ? '' : digits[digits.length - 1];
      }
    } finally {
      _settingOtpProgrammatically = false;
    }
    if (digits.length > 1) {
      if (digits.length >= 6) {
        _otpNodes[index].unfocus();
      } else {
        _otpNodes[digits.length.clamp(0, 5)].requestFocus();
      }
    } else if (digits.isEmpty) {
      // Cleared via soft-keyboard backspace: move to the previous box.
      if (index > 0) _otpNodes[index - 1].requestFocus();
    } else if (index < 5) {
      _otpNodes[index + 1].requestFocus();
    } else {
      _otpNodes[index].unfocus();
    }
    setState(() {});
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_mode == AuthMode.signup) {
      await _startOtpStep();
      return;
    }
    _vm.clearError();

    final success =
        await _vm.signIn(_emailController.text, _passwordController.text);

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.error ?? 'Something went wrong'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  /// Step 1 of signup: validate the details form, snapshot the details, and
  /// send the OTP. Only flips to the code-entry step on success.
  Future<void> _startOtpStep() async {
    final name = _nameController.text;
    final email = _emailController.text;
    final phone = _phoneController.text;
    final password = _passwordController.text;
    final sent = await _vm.sendOtp(email);
    if (!mounted) return;
    if (sent) {
      setState(() {
        _otpName = name;
        _otpEmail = email;
        _otpPhone = phone;
        _otpPassword = password;
        _otpStep = true;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.otpError ?? 'Something went wrong'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _resendOtp() async {
    // Guard against double-taps while a send is in flight.
    if (_vm.otpState == OtpState.sending) return;
    final sent = await _vm.sendOtp(_otpEmail);
    if (!mounted || sent) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_vm.otpError ?? 'Something went wrong'),
        backgroundColor: AppColors.danger,
      ),
    );
  }

  /// Step 2 of signup: verify the code, then create the account with the
  /// saved Step-1 details.
  Future<void> _verifyOtp() async {
    FocusScope.of(context).unfocus();
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter the 6-digit code'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final verified = await _vm.confirmOtp(email: _otpEmail, code: code);
    if (!mounted) return;
    // Wrong code: vm.otpError renders under the boxes; stay on Step 2.
    if (!verified) return;
    final success = await _vm.signUp(
      fullName: _otpName,
      email: _otpEmail,
      phone: _otpPhone,
      password: _otpPassword,
    );
    if (!mounted) return;
    if (success) {
      _vm.resetOtp();
      _clearOtpBoxes();
      _clearOtpSnapshot();
      setState(() => _otpStep = false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_vm.error ?? 'Something went wrong'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _backToDetails() {
    FocusScope.of(context).unfocus();
    setState(() => _otpStep = false);
  }

  Future<void> _showForgotPasswordSheet() async {
    final emailController = TextEditingController(text: _emailController.text);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            MediaQuery.of(sheetContext).viewInsets.bottom + 28,
          ),
          child: StatefulBuilder(builder: (context, setSheetState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.champagne,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Reset Password',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Enter your account email and we will send you a secure reset link.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
                ),
                const SizedBox(height: 18),
                ElegantTextField(
                  controller: emailController,
                  hint: 'you@example.com',
                  label: 'EMAIL ADDRESS',
                  prefixIcon: Icons.mail_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                GradientButton(
                  label: 'Send Reset Link',
                  busy: _resetBusy,
                  onPressed: () async {
                    if (Validators.email(emailController.text) != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Enter a valid email address')),
                      );
                      return;
                    }
                    setSheetState(() => _resetBusy = true);
                    final ok =
                        await _vm.sendPasswordReset(emailController.text);
                    setSheetState(() => _resetBusy = false);
                    if (!sheetContext.mounted) return;
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          ok
                              ? 'Reset link sent. Check your inbox.'
                              : (_vm.error ?? 'Could not send reset link.'),
                        ),
                        backgroundColor: ok ? AppColors.success : AppColors.danger,
                      ),
                    );
                  },
                ),
              ],
            );
          }),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AuthViewModel>();
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.creamGradient),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _FloralWatermarkPainter())),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        const AppLogo(size: 84),
                        const SizedBox(height: 18),
                        FerrerWordmark(fontSize: 32),
                        const SizedBox(height: 36),
                        _mode == AuthMode.signup && _otpStep
                            ? _OtpStepCard(
                                email: _otpEmail,
                                otpControllers: _otpControllers,
                                otpNodes: _otpNodes,
                                otpError: vm.otpError,
                                otpState: vm.otpState,
                                resendCooldownSeconds:
                                    vm.resendCooldownSeconds,
                                codeComplete: _otpComplete,
                                onChanged: _onOtpChanged,
                                onVerify: _verifyOtp,
                                onResend: _resendOtp,
                                onBack: _backToDetails,
                              )
                            : _AuthCard(
                                mode: _mode,
                                formKey: _formKey,
                                emailController: _emailController,
                                passwordController: _passwordController,
                                confirmPasswordController:
                                    _confirmPasswordController,
                                nameController: _nameController,
                                phoneController: _phoneController,
                                obscure: _obscure,
                                canSubmit: _canSubmit,
                                onToggleObscure: () =>
                                    setState(() => _obscure = !_obscure),
                                busy: vm.busy ||
                                    vm.otpState == OtpState.sending,
                                onSubmit: _submit,
                                onForgotPassword: _showForgotPasswordSheet,
                                onSwitchToSignup: () =>
                                    _switchMode(AuthMode.signup),
                                onSwitchToLogin: () =>
                                    _switchMode(AuthMode.login),
                              ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: _mode == AuthMode.login
                              ? _CreateAccountLink(onTap: () => _switchMode(AuthMode.signup))
                              : _BackToLoginLink(onTap: () => _switchMode(AuthMode.login)),
                        ),
                        if (!AppConfig.firebaseEnabled) ...[
                          const SizedBox(height: 26),
                          _DemoCredentialsCard(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpStepCard extends StatelessWidget {
  final String email;
  final List<TextEditingController> otpControllers;
  final List<FocusNode> otpNodes;
  final String? otpError;
  final OtpState otpState;
  final int resendCooldownSeconds;
  final bool codeComplete;
  final void Function(int index, String value) onChanged;
  final VoidCallback onVerify;
  final VoidCallback onResend;
  final VoidCallback onBack;

  const _OtpStepCard({
    required this.email,
    required this.otpControllers,
    required this.otpNodes,
    required this.otpError,
    required this.otpState,
    required this.resendCooldownSeconds,
    required this.codeComplete,
    required this.onChanged,
    required this.onVerify,
    required this.onResend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .38),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Check your email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'We sent a 6-digit code to $email',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
          ),
          const SizedBox(height: 26),
          Row(
            children: List.generate(6, (i) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                  child: TextField(
                    controller: otpControllers[i],
                    focusNode: otpNodes[i],
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    textAlign: TextAlign.center,
                    textInputAction:
                        i < 5 ? TextInputAction.next : TextInputAction.done,
                    onSubmitted: i == 5 ? (_) => onVerify() : null,
                    onChanged: (value) => onChanged(i, value),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          if (otpError != null) ...[
            const SizedBox(height: 10),
            Text(
              otpError!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.danger,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (resendCooldownSeconds > 0)
                Text(
                  'Resend in ${resendCooldownSeconds}s',
                  style: const TextStyle(
                    color: AppColors.inkSoft,
                    fontSize: 13,
                  ),
                )
              else
                TextButton(
                  onPressed: onResend,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.roseDark,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: const Text('Resend code'),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GradientButton(
            label: 'Verify Code',
            busy: otpState == OtpState.verifying,
            onPressed: codeComplete ? onVerify : null,
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: onBack,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.roseDark,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: const Text('Back to details'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final AuthMode mode;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final bool obscure;
  final bool canSubmit;
  final VoidCallback onToggleObscure;
  final bool busy;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final VoidCallback onSwitchToSignup;
  final VoidCallback onSwitchToLogin;

  const _AuthCard({
    required this.mode,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.nameController,
    required this.phoneController,
    required this.obscure,
    required this.canSubmit,
    required this.onToggleObscure,
    required this.busy,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onSwitchToSignup,
    required this.onSwitchToLogin,
  });

  @override
  Widget build(BuildContext context) {
    final isLogin = mode == AuthMode.login;
    return Container(
      key: ValueKey(mode),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .92),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: AppColors.goldSoft.withValues(alpha: .55)),
        boxShadow: [
          BoxShadow(
            color: AppColors.blush.withValues(alpha: .38),
            blurRadius: 34,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isLogin ? AppStrings.welcomeBack : AppStrings.createAccountTitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 6),
            Text(
              isLogin ? AppStrings.loginSubtitle : AppStrings.signupSubtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 26),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isLogin
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('signup-fields'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElegantTextField(
                        controller: nameController,
                        hint: 'Maria Santos',
                        label: 'FULL NAME',
                        prefixIcon: Icons.person_outline_rounded,
                        validator: Validators.fullName,
                      ),
                    ),
            ),
            ElegantTextField(
              controller: emailController,
              hint: 'you@example.com',
              label: 'EMAIL ADDRESS',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.email,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isLogin
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('phone-field'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElegantTextField(
                        controller: phoneController,
                        hint: '0917 123 4567',
                        label: 'PHONE NUMBER',
                        prefixIcon: Icons.phone_iphone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: Validators.phone,
                      ),
                    ),
            ),
            ElegantTextField(
              controller: passwordController,
              hint: '••••••••',
              label: 'PASSWORD',
              prefixIcon: Icons.lock_rounded,
              obscureText: obscure,
              onSuffixTap: onToggleObscure,
              suffixIcon: obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              textInputAction: isLogin ? TextInputAction.done : TextInputAction.next,
              onSubmitted: isLogin ? (_) => onSubmit() : null,
              validator: Validators.password,
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) => SizeTransition(
                sizeFactor: animation,
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: isLogin
                  ? const SizedBox.shrink()
                  : Padding(
                      key: const ValueKey('confirm-password-field'),
                      padding: const EdgeInsets.only(bottom: 16),
                      child: ElegantTextField(
                        controller: confirmPasswordController,
                        hint: '••••••••',
                        label: 'CONFIRM PASSWORD',
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: obscure,
                        onSuffixTap: onToggleObscure,
                        suffixIcon:
                            obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => onSubmit(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: isLogin ? onForgotPassword : null,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.roseDark,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                child: const Text('Forgot Password?'),
              ),
            ),
            const SizedBox(height: 14),
            GradientButton(
              label: isLogin ? 'Log In' : 'Create Account',
              busy: busy,
              onPressed: canSubmit ? onSubmit : null,
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    isLogin
                        ? 'New to Ferrer Clothing Rental?'
                        : 'Already have an account?',
                    style: const TextStyle(color: AppColors.inkSoft, fontSize: 13),
                  ),
                ),
                TextButton(
                  onPressed: isLogin ? onSwitchToSignup : onSwitchToLogin,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.roseDark,
                    padding: const EdgeInsets.only(left: 6),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  child: Text(isLogin ? 'Create an Account' : 'Sign In'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateAccountLink extends StatelessWidget {
  final VoidCallback onTap;

  const _CreateAccountLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: RichText(
        textAlign: TextAlign.center,
        text: const TextSpan(
          style: TextStyle(color: AppColors.inkSoft, fontSize: 13.5),
          children: [
            TextSpan(text: "Don't have an account? "),
            TextSpan(
              text: 'Join us',
              style: TextStyle(
                color: AppColors.roseDark,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackToLoginLink extends StatelessWidget {
  final VoidCallback onTap;

  const _BackToLoginLink({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: const Text(
        'Back to Sign In',
        style: TextStyle(
          color: AppColors.roseDark,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
          letterSpacing: .3,
        ),
      ),
    );
  }
}

class _FloralWatermarkPainter extends CustomPainter {
  static const List<(Offset, double)> _flowers = [
    (Offset(.06, .14), 30),
    (Offset(.9, .08), 22),
    (Offset(.94, .38), 36),
    (Offset(.05, .58), 26),
    (Offset(.88, .84), 32),
    (Offset(.16, .92), 20),
    (Offset(.45, .04), 18),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..color = AppColors.rose.withValues(alpha: .09);

    final goldStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..color = AppColors.gold.withValues(alpha: .11);

    final dot = Paint()
      ..style = PaintingStyle.fill
      ..color = AppColors.gold.withValues(alpha: .13);

    for (var i = 0; i < _flowers.length; i++) {
      final (rel, radius) = _flowers[i];
      final center = Offset(rel.dx * size.width, rel.dy * size.height);
      _flower(canvas, center, radius, i.isEven ? stroke : goldStroke, dot);
    }

    final leaf = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.success.withValues(alpha: .07);
    for (final pos in const [
      Offset(.25, .35),
      Offset(.75, .6),
      Offset(.55, .85),
    ]) {
      canvas.save();
      canvas.translate(pos.dx * size.width, pos.dy * size.height);
      canvas.rotate(.7);
      canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 12, height: 34), leaf);
      canvas.restore();
    }
  }

  void _flower(Canvas canvas, Offset center, double radius, Paint petalPaint, Paint dot) {
    for (var p = 0; p < 6; p++) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(p * math.pi / 3);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(0, -radius * .62),
          width: radius * .58,
          height: radius * 1.05,
        ),
        petalPaint,
      );
      canvas.restore();
    }
    canvas.drawCircle(center, radius * .17, dot);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DemoCredentialsCard extends StatelessWidget {
  const _DemoCredentialsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.champagne.withValues(alpha: .45),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldSoft),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.info_outline_rounded, size: 15, color: AppColors.gold),
              SizedBox(width: 6),
              Text(
                'PREVIEW MODE ACCOUNTS',
                style: TextStyle(
                  fontSize: 10.5,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _row('Customer', 'maria@example.com'),
          _row('Admin', 'admin@ferrer.ph'),
          const SizedBox(height: 6),
          const Text(
            'Password for both: ferrer123',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String role, String email) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            role,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.roseDark,
            ),
          ),
          Text(
            email,
            style: const TextStyle(fontSize: 12.5, color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

