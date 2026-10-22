import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../l10n/l10n_context.dart';

/// Shown once to an approved student who has not yet set a password,
/// so they can also log in later via the Email & Password option.
class StudentPasswordScreen extends ConsumerStatefulWidget {
  const StudentPasswordScreen({super.key});

  @override
  ConsumerState<StudentPasswordScreen> createState() =>
      _StudentPasswordScreenState();
}

class _StudentPasswordScreenState
    extends ConsumerState<StudentPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _passwordVisible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('Session expired. Please log in again.');
      }

      final profile = await client
          .from('student_profiles')
          .select('email')
          .eq('id', user.id)
          .maybeSingle();
      final email = (profile is Map<String, dynamic>)
          ? profile['email'] as String?
          : null;

      await client.auth.updateUser(
        UserAttributes(
          password: _passwordController.text,
          email: (email != null && email.trim().isNotEmpty) ? email : null,
        ),
      );

      if (!mounted) return;
      context.go(Routes.studentDashboard);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.couldNotSetPassword),
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                const AppLogoHeader(),
                const SizedBox(height: 32),
                Text(
                  context.l10n.setPasswordTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.setPasswordBody,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.newPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                    if (value.length < 6) {
                      return context.l10n.passwordTooShort;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_passwordVisible,
                  decoration: InputDecoration(
                    labelText: context.l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return context.l10n.passwordsDontMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: context.l10n.setPasswordContinue,
                  isLoading: _isLoading,
                  onPressed: _submit,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
