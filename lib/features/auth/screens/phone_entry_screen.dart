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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
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

  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final phone = '+91${_phoneController.text.trim()}';
      await ref.read(authRepositoryProvider).sendOtp(phone);
      if (!mounted) return;
      context.go(Routes.otp, extra: {'phone': phone, 'role': _role});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
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
                const SizedBox(height: 32),
                const AppLogoHeader(),
                const SizedBox(height: 40),

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
                  'Enter your registered mobile number',
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: AppColors.brown,
                  ),
                ),
                const SizedBox(height: 32),

                // Phone field
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
                          horizontal: 12, vertical: 14),
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
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Send OTP',
                  isLoading: _isLoading,
                  onPressed: _sendOtp,
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
