import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/login_identifier.dart';
import '../../../l10n/l10n_context.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';

/// The single login screen for every role. Mobile number or email plus a
/// password; or, as a fallback (forgotten password), a one-time code emailed
/// to the person. The account's role (stored in `users.role`) decides where
/// they land — nobody picks a role.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _codeMode = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final id = LoginIdentifier.parse(_identifierController.text);
    if (id == null) return;

    setState(() => _isLoading = true);
    try {
      if (_codeMode) {
        await _sendCode(id);
      } else {
        await _loginWithPassword(id);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithPassword(LoginIdentifier id) async {
    final l10n = context.l10n;
    final repo = ref.read(authRepositoryProvider);
    try {
      final session = await repo.signInWithPassword(
        id,
        _passwordController.text,
      );
      if (session == null) throw Exception('no session');
      ref.invalidate(currentUserRoleProvider);
      ref.invalidate(currentStudentStatusProvider);
      final role = await repo.fetchUserRole(session.user.id);
      if (!mounted) return;
      context.go(roleDestination(role));
    } catch (e) {
      if (!mounted) return;
      _showError(
        e.toString().contains('Invalid login credentials')
            ? l10n.loginFailedCredentials
            : l10n.loginFailedGeneric,
      );
    }
  }

  Future<void> _sendCode(LoginIdentifier id) async {
    final l10n = context.l10n;
    if (!id.isEmail) {
      _showError(l10n.emailCodeNotice);
      return;
    }
    try {
      await ref.read(authRepositoryProvider).sendEmailCode(id.email!);
    } catch (_) {
      if (mounted) _showError(l10n.sendCodeFailed);
      return;
    }
    if (!mounted) return;
    context.go(Routes.otp, extra: {'email': id.email, 'forgot': true});
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  l10n.loginTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeMode ? l10n.emailCodeSubtitle : l10n.loginSubtitle,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  decoration: InputDecoration(
                    labelText:
                        _codeMode ? l10n.emailAddress : l10n.identifierLabel,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterIdentifier;
                    }
                    return LoginIdentifier.parse(value) == null
                        ? l10n.invalidIdentifier
                        : null;
                  },
                ),
                if (!_codeMode) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    autofillHints: const [AutofillHints.password],
                    decoration: InputDecoration(
                      labelText: l10n.passwordOrCode,
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _passwordVisible
                            ? l10n.hidePassword
                            : l10n.showPassword,
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () => setState(
                          () => _passwordVisible = !_passwordVisible,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? l10n.enterPassword
                        : null,
                  ),
                ],
                const SizedBox(height: 28),
                PrimaryButton(
                  label: _codeMode ? l10n.sendCode : l10n.loginButton,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _codeMode = !_codeMode),
                    child: Text(
                      _codeMode ? l10n.usePasswordInstead : l10n.forgotPassword,
                      textAlign: TextAlign.center,
                      style: AppTypography.poppins(
                        fontSize: 13,
                        color: context.headingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.noLoginHint,
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(
                    fontSize: 12,
                    color: context.mutedTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Where a signed-in person goes next, decided by their account's role.
/// Admin and teacher continue to their access-code step; students go straight
/// to their dashboard (the router sends pending students to the waiting
/// screen).
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
