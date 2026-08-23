import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/routes.dart';
import '../providers/auth_providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';

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
  bool _useEmailLogin = true;
  bool _passwordVisible = false;
  String _role = 'student';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _role = extra?['role'] as String? ?? 'student';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String get _roleLabel {
    switch (_role) {
      case 'admin':
        return 'Admin';
      case 'teacher':
        return 'Teacher';
      default:
        return 'Student';
    }
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_useEmailLogin) {
        final email = _emailController.text.trim();
        final password = _passwordController.text.trim();

        final session = await ref
            .read(authRepositoryProvider)
            .signInWithEmailAndPassword(email, password);

        if (session == null) {
          throw Exception('Check email & password.');
        }

        if (!mounted) return;

        // Fetch user's role from DB
        final userRole = await ref
            .read(authRepositoryProvider)
            .fetchUserRole(session.user.id);

        if (userRole == 'admin') {
          context.go(Routes.adminDashboard);
        } else if (userRole == 'teacher') {
          context.go(Routes.teacherDashboard);
        } else {
          context.go(Routes.studentDashboard);
        }
      } else {
        final phone = '+91${_phoneController.text.trim()}';
        await ref.read(authRepositoryProvider).sendOtp(phone);
        if (!mounted) return;
        context.go(Routes.otp, extra: {'phone': phone, 'role': _role});
      }
    } catch (e) {
      if (!mounted) return;
      String errorMsg = 'Invalid email or password.';
      final rawStr = e.toString();
      if (rawStr.contains('Database error querying schema') ||
          rawStr.contains('500')) {
        errorMsg =
            'Account not registered for Student login. If you are Admin, please use Admin Login.';
      } else if (rawStr.contains('Invalid login credentials')) {
        errorMsg = 'Incorrect email or password. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
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
          tooltip: 'Back',
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
                  '$_roleLabel Login',
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.maroon,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _useEmailLogin
                      ? 'Sign in with registered Email & Password'
                      : 'Enter your registered mobile number for OTP',
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(height: 24),

                // Method Selector Toggle (Email / Mobile)
                Row(
                  children: [
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Email & Password')),
                        selected: _useEmailLogin,
                        onSelected: (val) {
                          if (val) setState(() => _useEmailLogin = true);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ChoiceChip(
                        label: const Center(child: Text('Mobile OTP')),
                        selected: !_useEmailLogin,
                        onSelected: (val) {
                          if (val) setState(() => _useEmailLogin = false);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_useEmailLogin) ...[
                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'student@gmail.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Enter your email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: !_passwordVisible,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _passwordVisible
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                        ),
                        onPressed: () => setState(
                            () => _passwordVisible = !_passwordVisible),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Enter your password';
                      }
                      return null;
                    },
                  ),
                ] else ...[
                  // Phone Field
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(10),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Mobile Number',
                      hintText: '9876543210',
                      prefixIcon: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        child: Text(
                          '+91',
                          style: AppTypography.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.brown,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                          const BoxConstraints(minWidth: 0, minHeight: 0),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your mobile number';
                      }
                      if (value.trim().length != 10) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                ],

                const SizedBox(height: 32),

                PrimaryButton(
                  label: _useEmailLogin ? 'Login' : 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _handleAuth,
                ),
                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => context.go(Routes.adminLogin),
                      child: Text(
                        'Admin Login',
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: AppColors.maroon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => context.go(Routes.roleSelect),
                      child: Text(
                        'Change Role',
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: AppColors.brown,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
