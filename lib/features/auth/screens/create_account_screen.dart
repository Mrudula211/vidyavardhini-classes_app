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

/// First step for a new student/parent: pick a mobile number or an email and
/// a password. The student details come next (registration form) and the
/// admin approves the account afterwards.
class CreateAccountScreen extends ConsumerStatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  ConsumerState<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState extends ConsumerState<CreateAccountScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _useEmail = false;
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
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
    final l10n = context.l10n;

    setState(() => _isLoading = true);
    try {
      final session = await ref
          .read(authRepositoryProvider)
          .signUpWithPassword(id, _passwordController.text);

      if (!mounted) return;
      if (session == null) {
        // The project still asks people to confirm their contact first.
        _showError(l10n.accountCreatedConfirm);
        context.go(Routes.login);
        return;
      }
      ref.invalidate(currentUserRoleProvider);
      ref.invalidate(currentStudentStatusProvider);
      context.go(Routes.studentRegister);
    } catch (e) {
      if (!mounted) return;
      final text = e.toString().toLowerCase();
      _showError(
        text.contains('already') || text.contains('registered')
            ? l10n.accountAlreadyExists
            : l10n.loginFailedGeneric,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                const SizedBox(height: 28),
                Text(
                  l10n.createAccountTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.createAccountSubtitle,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<bool>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: false,
                        icon: const Icon(Icons.phone_android_rounded),
                        label: Text(l10n.tabMobile),
                      ),
                      ButtonSegment(
                        value: true,
                        icon: const Icon(Icons.email_outlined),
                        label: Text(l10n.tabEmail),
                      ),
                    ],
                    selected: {_useEmail},
                    onSelectionChanged: (v) => setState(() {
                      _useEmail = v.first;
                      _identifierController.clear();
                    }),
                  ),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _identifierController,
                  keyboardType: _useEmail
                      ? TextInputType.emailAddress
                      : TextInputType.phone,
                  decoration: InputDecoration(
                    labelText:
                        _useEmail ? l10n.emailAddress : l10n.mobileNumber,
                    prefixIcon: Icon(
                      _useEmail
                          ? Icons.email_outlined
                          : Icons.phone_android_rounded,
                    ),
                    prefixText: _useEmail ? null : '+91  ',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.enterIdentifier;
                    }
                    final id = LoginIdentifier.parse(value);
                    if (id == null || id.isEmail != _useEmail) {
                      return l10n.invalidIdentifier;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    helperText: l10n.passwordHelper,
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.enterPassword;
                    }
                    if (value.length < 6) return l10n.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) => value != _passwordController.text
                      ? l10n.passwordsDontMatch
                      : null,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.createAccountButton,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed:
                        _isLoading ? null : () => context.go(Routes.login),
                    child: Text(
                      l10n.alreadyHaveAccount,
                      style: AppTypography.poppins(
                        fontSize: 13,
                        color: context.headingColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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
