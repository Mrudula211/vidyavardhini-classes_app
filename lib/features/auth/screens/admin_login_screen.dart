import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../l10n/l10n_context.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  final _accessCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    var signedInHere = false;
    try {
      final repo = ref.read(authRepositoryProvider);
      final email = _identifierController.text.trim();
      final password = _passwordController.text;
      final code = _accessCodeController.text.trim();

      // 1. A real Supabase session is required: every admin query is checked
      //    by row-level security against it. (An OTP session from the phone
      //    screen is also accepted.)
      if (ref.read(currentUserProvider) == null) {
        final session = await repo.signInWithEmailAndPassword(email, password);
        if (session == null) throw Exception('Invalid admin credentials.');
        signedInHere = true;
      }

      // 2. Access code + password, verified server-side for this account.
      final ok = await repo.verifyAdminCredentials(code, password);
      if (!ok) throw Exception('Invalid admin credentials.');

      // Grant Admin session flag so router allows navigation to /admin
      ref.read(adminAuthenticatedProvider.notifier).state = true;

      if (!mounted) return;
      context.go(Routes.adminDashboard);
    } catch (e) {
      if (signedInHere) {
        await ref.read(authRepositoryProvider).signOut();
      }
      if (!mounted) return;
      final l10n = context.l10n;
      final message = e.toString().contains('Too many')
          ? l10n.tooManyAttempts
          : l10n.invalidAdminCredentials;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.maroon,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.goBack,
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.roleSelect),
        ),
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
                const SizedBox(height: 16),
                const AppLogoHeader(),
                const SizedBox(height: 32),
                Text(
                  context.l10n.adminLoginTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  ref.watch(currentUserProvider) == null
                      ? context.l10n.adminLoginSubtitleFull
                      : context.l10n.adminLoginSubtitle,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                  ),
                ),
                const SizedBox(height: 32),
                if (ref.watch(currentUserProvider) == null) ...[
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: context.l10n.adminEmail,
                      prefixIcon: const Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return context.l10n.enterAdminEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.password,
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible
                          ? context.l10n.hidePassword
                          : context.l10n.showPassword,
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () =>
                          setState(() => _passwordVisible = !_passwordVisible),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return context.l10n.enterPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accessCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: context.l10n.accessCode,
                    hintText: context.l10n.accessCodeHint,
                    counterText: '',
                    prefixIcon: const Icon(Icons.pin_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return context.l10n.enterAccessCode;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: context.l10n.loginButton,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () async {
                      await ref.read(authRepositoryProvider).signOut();
                      if (context.mounted) context.go(Routes.roleSelect);
                    },
                    child: Text(
                      context.l10n.useDifferentAccount,
                      style: AppTypography.poppins(
                        fontSize: 14,
                        color: context.headingColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
