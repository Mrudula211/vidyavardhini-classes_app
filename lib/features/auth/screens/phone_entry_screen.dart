import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/l10n_context.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// The single login screen for every role. Mobile number + OTP by default,
/// email + password as an alternative. The account's role (stored in
/// `users.role`) decides where the person lands — nobody picks a role.
class PhoneEntryScreen extends ConsumerStatefulWidget {
  const PhoneEntryScreen({super.key});

  @override
  ConsumerState<PhoneEntryScreen> createState() => _PhoneEntryScreenState();
}

class _PhoneEntryScreenState extends ConsumerState<PhoneEntryScreen> {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _useEmailLogin = false;
  bool _passwordVisible = false;
  bool _isRegister = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _isRegister = extra?['register'] as bool? ?? false;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.maroon,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    setState(() => _isLoading = true);

    try {
      if (_useEmailLogin) {
        await _loginWithEmail();
      } else {
        final phone = '+91${_phoneController.text.trim()}';
        try {
          await ref.read(authRepositoryProvider).sendOtp(phone);
        } catch (_) {
          if (mounted) _showError(l10n.sendCodeFailed);
          return;
        }
        if (!mounted) return;
        context.go(Routes.otp, extra: {'phone': phone});
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithEmail() async {
    final l10n = context.l10n;
    final repo = ref.read(authRepositoryProvider);
    try {
      final session = await repo.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      if (session == null) throw Exception('no session');
      final role = await repo.fetchUserRole(session.user.id);
      if (!mounted) return;
      context.go(roleDestination(role));
    } catch (e) {
      if (!mounted) return;
      final raw = e.toString();
      _showError(
        raw.contains('Invalid login credentials')
            ? l10n.loginFailedCredentials
            : l10n.loginFailedGeneric,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final showEmailToggle = !_isRegister;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.goBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.roleSelect),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSwitcher(),
          ),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                const AppLogoHeader(),
                const SizedBox(height: 32),
                Text(
                  _isRegister ? l10n.registerTitle : l10n.loginTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _useEmailLogin
                      ? l10n.emailLoginSubtitle
                      : (_isRegister
                          ? l10n.registerSubtitle
                          : l10n.loginSubtitle),
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(height: 28),
                if (_useEmailLogin) ..._emailFields(l10n) else _phoneField(l10n),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _useEmailLogin ? l10n.loginButton : l10n.sendCode,
                  isLoading: _isLoading,
                  onPressed: _handleAuth,
                ),
                if (showEmailToggle) ...[
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(
                                () => _useEmailLogin = !_useEmailLogin,
                              ),
                      child: Text(
                        _useEmailLogin
                            ? l10n.usePhoneInstead
                            : l10n.useEmailInstead,
                        textAlign: TextAlign.center,
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: AppColors.maroon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _phoneField(AppLocalizations l10n) {
    return TextFormField(
      controller: _phoneController,
      keyboardType: TextInputType.phone,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(10),
      ],
      decoration: InputDecoration(
        labelText: l10n.mobileNumber,
        hintText: '9876543210',
        prefixIcon: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Text(
            '+91',
            style: AppTypography.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.brown,
            ),
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return l10n.enterMobile;
        }
        if (value.trim().length != 10) return l10n.invalidMobile;
        return null;
      },
    );
  }

  List<Widget> _emailFields(AppLocalizations l10n) {
    return [
      TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          labelText: l10n.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
        ),
        validator: (value) => (value == null || value.trim().isEmpty)
            ? l10n.enterEmail
            : null,
      ),
      const SizedBox(height: 16),
      TextFormField(
        controller: _passwordController,
        obscureText: !_passwordVisible,
        decoration: InputDecoration(
          labelText: l10n.password,
          prefixIcon: const Icon(Icons.lock_outline_rounded),
          suffixIcon: IconButton(
            tooltip:
                _passwordVisible ? l10n.hidePassword : l10n.showPassword,
            icon: Icon(
              _passwordVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
            ),
            onPressed: () =>
                setState(() => _passwordVisible = !_passwordVisible),
          ),
        ),
        validator: (value) => (value == null || value.isEmpty)
            ? l10n.enterPassword
            : null,
      ),
    ];
  }
}

/// Where a signed-in person goes next, decided by their account's role.
/// Admin and teacher continue to their access-code step; students go straight
/// to their dashboard (the router sends pending/new students to the right
/// registration or approval screen).
String roleDestination(String? role) {
  switch (role) {
    case 'admin':
      return Routes.adminLogin;
    case 'teacher':
      return Routes.teacherLogin;
    default:
      return Routes.studentDashboard;
  }
}
