import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../providers/auth_providers.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/l10n_context.dart';
import 'login_screen.dart' show roleDestination;
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
  late String _email;
  bool _forgot = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    _email = extra?['email'] as String? ?? '';
    _forgot = extra?['forgot'] as bool? ?? false;
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
      final repo = ref.read(authRepositoryProvider);
      // Unknown numbers become pending students; admin and teacher accounts
      // already exist (created by the admin) and keep their own role.
      final session = await repo.verifyEmailCode(_email, _otp);
      // The role/status providers fetched as soon as the session appeared —
      // before a new student's account row existed. Refresh them.
      ref.invalidate(currentUserRoleProvider);
      ref.invalidate(currentStudentStatusProvider);
      final role =
          session == null ? null : await repo.fetchUserRole(session.user.id);
      if (!mounted) return;
      _navigateAfterOtp(role);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.otpInvalid)),
      );
      for (final c in _controllers) {
        c.clear();
      }
      _focusNodes[0].requestFocus();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// After a code login: forgotten-password people choose a new password;
  /// otherwise the account's own role decides the next step. Admin and
  /// teacher go on to their access-code check; everyone else continues as a
  /// student (the router sends new students to registration, pending ones to
  /// the waiting screen and approved ones to their dashboard).
  void _navigateAfterOtp(String? role) {
    if (_forgot) {
      context.go(Routes.newPassword, extra: {'role': role});
    } else if (role == 'admin' || role == 'teacher') {
      context.go(roleDestination(role));
    } else {
      context.go(Routes.studentDashboard);
    }
  }

  Future<void> _resendOtp() async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(authRepositoryProvider).sendEmailCode(_email);
      if (!mounted) return;
      _startResendTimer();
      messenger.showSnackBar(SnackBar(content: Text(l10n.otpResent)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.sendCodeFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
                l10n.otpTitle,
                style: AppTypography.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: context.headingColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.otpSubtitle(_email),
                style: AppTypography.poppins(
                  fontSize: 14,
                  color: context.bodyTextColor,
                ),
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
                label: l10n.otpVerify,
                isLoading: _isLoading,
                onPressed: _otp.length == 6 ? _verifyOtp : null,
              ),
              const SizedBox(height: 24),

              Center(
                child: _resendSeconds > 0
                    ? Text(
                        l10n.otpResendIn(_resendSeconds.toString()),
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: context.mutedTextColor,
                        ),
                      )
                    : TextButton(
                        onPressed: _resendOtp,
                        child: Text(
                          l10n.otpResend,
                          style: AppTypography.poppins(
                            fontSize: 14,
                            color: context.headingColor,
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
            color: context.headingColor,
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
