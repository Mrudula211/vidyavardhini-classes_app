import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/l10n_context.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';
import '../providers/auth_providers.dart';
import 'login_screen.dart' show roleDestination;

/// Shown after someone logged in with an emailed code because they forgot
/// their password: lets them choose a new one (or skip).
class NewPasswordScreen extends ConsumerStatefulWidget {
  const NewPasswordScreen({super.key});

  @override
  ConsumerState<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends ConsumerState<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _visible = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? get _role =>
      (GoRouterState.of(context).extra as Map<String, dynamic>?)?['role']
          as String?;

  void _continue() => context.go(roleDestination(_role));

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authRepositoryProvider)
          .setPassword(_passwordController.text);
      messenger.showSnackBar(SnackBar(content: Text(l10n.passwordSaved)));
      if (mounted) _continue();
    } catch (_) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.passwordSaveFailed),
          backgroundColor: AppColors.maroon,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                  l10n.newPasswordTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.newPasswordBody,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_visible,
                  decoration: InputDecoration(
                    labelText: l10n.newPassword,
                    helperText: l10n.passwordHelper,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                    suffixIcon: IconButton(
                      tooltip: _visible ? l10n.hidePassword : l10n.showPassword,
                      icon: Icon(
                        _visible
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                      ),
                      onPressed: () => setState(() => _visible = !_visible),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return l10n.enterPassword;
                    if (v.length < 6) return l10n.passwordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: !_visible,
                  decoration: InputDecoration(
                    labelText: l10n.confirmPassword,
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
                  ),
                  validator: (v) => v != _passwordController.text
                      ? l10n.passwordsDontMatch
                      : null,
                ),
                const SizedBox(height: 28),
                PrimaryButton(
                  label: l10n.savePassword,
                  isLoading: _isLoading,
                  onPressed: _save,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : _continue,
                    child: Text(l10n.skipForNow),
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
