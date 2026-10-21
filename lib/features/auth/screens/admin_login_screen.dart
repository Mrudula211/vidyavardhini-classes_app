import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';

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
      var message = e.toString().replaceAll('Exception: ', '');
      if (!message.startsWith('Too many') && !message.startsWith('Invalid')) {
        message = 'Invalid admin credentials.';
      }
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
          tooltip: 'Go back',
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
                  'Admin Login',
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in with your email, password and 6-digit access code',
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(height: 32),
                if (ref.watch(currentUserProvider) == null) ...[
                  TextFormField(
                    controller: _identifierController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Admin Email',
                      prefixIcon: Icon(Icons.person_outline_rounded),
                    ),
                    validator: (value) {
                      if (value == null || !value.contains('@')) {
                        return 'Enter your admin email';
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
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      tooltip: _passwordVisible ? 'Hide password' : 'Show password',
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
                      return 'Enter your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _accessCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Admin Access Code',
                    hintText: '6-digit code',
                    counterText: '',
                    prefixIcon: Icon(Icons.pin_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().length != 6) {
                      return 'Enter the 6-digit access code';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                PrimaryButton(
                  label: 'Login',
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.go(Routes.roleSelect),
                    child: Text(
                      'Change Role',
                      style: AppTypography.poppins(
                        fontSize: 14,
                        color: AppColors.maroon,
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
