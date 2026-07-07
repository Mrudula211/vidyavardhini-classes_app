import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../shared/widgets/app_logo_header.dart';
import '../../../shared/widgets/primary_button.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  int _resendSeconds = AppConstants.otpResendSeconds;
  Timer? _resendTimer;
  late String _phone;
  late String _role;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _phone = extra?['phone'] as String? ?? '';
    _role = extra?['role'] as String? ?? 'student';
    _startResendTimer();
  }

  void _startResendTimer() {
    _resendSeconds = AppConstants.otpResendSeconds;
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendSeconds == 0) {
        timer.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitEntered(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    }
    if (_otp.length == 6) _verifyOtp();
  }

  void _onBackspace(int index) {
    if (index > 0 && _controllers[index].text.isEmpty) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
    }
  }

  Future<void> _verifyOtp() async {
    if (_otp.length != 6) return;
    setState(() => _isLoading = true);
    try {
      // TODO: call authRepository.verifyOtp(phone: _phone, token: _otp)
      // await Supabase.instance.client.auth.verifyOTP(phone: _phone, token: _otp, type: OtpType.sms)
      if (!mounted) return;
      _navigateAfterOtp();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid OTP. Please try again.')),
      );
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateAfterOtp() {
    switch (_role) {
      case 'admin':
        context.go(Routes.adminLogin, extra: {'phone': _phone});
      case 'teacher':
        context.go(Routes.teacherLogin, extra: {'phone': _phone});
      default:
        // TODO: check if student is registered → pending / dashboard / register
        context.go(Routes.studentRegister, extra: {'phone': _phone});
    }
  }

  @override
  Widget build(BuildContext context) {
    final maskedPhone = _phone.length > 4
        ? '${_phone.substring(0, _phone.length - 4)}XXXX'
        : _phone;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),
              const AppLogoHeader(),
              const SizedBox(height: 40),

              Text(
                'Verify OTP',
                style: AppTypography.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.maroon,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to $maskedPhone',
                style:
                    AppTypography.poppins(fontSize: 14, color: AppColors.brown),
              ),
              const SizedBox(height: 40),

              // OTP boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  6,
                  (i) => _OtpBox(
                    controller: _controllers[i],
                    focusNode: _focusNodes[i],
                    onChanged: (val) => _onDigitEntered(i, val),
                    onBackspace: () => _onBackspace(i),
                  ),
                ),
              ),
              const SizedBox(height: 40),

              PrimaryButton(
                label: 'Verify OTP',
                isLoading: _isLoading,
                onPressed: _otp.length == 6 ? _verifyOtp : null,
              ),
              const SizedBox(height: 24),

              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'Resend OTP in $_resendSeconds seconds',
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: AppColors.lightOutline,
                        ),
                      )
                    : TextButton(
                        onPressed: _startResendTimer,
                        child: Text(
                          'Resend OTP',
                          style: AppTypography.poppins(
                            fontSize: 14,
                            color: AppColors.maroon,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OtpBox extends StatelessWidget {
  const _OtpBox({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onBackspace,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 46,
      height: 56,
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.backspace) {
            onBackspace();
          }
        },
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          maxLength: 1,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: AppTypography.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppColors.maroon,
          ),
          decoration: InputDecoration(
            counterText: '',
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.lightOutline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.maroon, width: 2),
            ),
          ),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
