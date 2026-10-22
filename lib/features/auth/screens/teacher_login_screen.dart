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

class TeacherLoginScreen extends ConsumerStatefulWidget {
  const TeacherLoginScreen({super.key});

  @override
  ConsumerState<TeacherLoginScreen> createState() => _TeacherLoginScreenState();
}

class _TeacherLoginScreenState extends ConsumerState<TeacherLoginScreen> {
  final _accessCodeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // The access code is a second step after phone OTP; without a real
    // session no data can be read (row-level security), so start over.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && ref.read(currentUserProvider) == null) {
        context.go(Routes.phone, extra: {'role': 'teacher'});
      }
    });
  }

  @override
  void dispose() {
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final accessCode = _accessCodeController.text.trim();
      final isValid = await ref
          .read(authRepositoryProvider)
          .verifyTeacherAccessCode(accessCode);
      if (!isValid) {
        throw Exception('Invalid access code');
      }
      ref.read(teacherAuthenticatedProvider.notifier).state = true;
      if (!mounted) return;
      context.go(Routes.teacherDashboard);
    } catch (e) {
      if (!mounted) return;
      final l10n = context.l10n;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().contains('Too many')
                ? l10n.tooManyAttempts
                : l10n.invalidAccessCode,
          ),
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
                const SizedBox(height: 32),
                const AppLogoHeader(),
                const SizedBox(height: 40),
                Text(
                  context.l10n.teacherLoginTitle,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.headingColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.teacherLoginSubtitle,
                  style: AppTypography.poppins(
                    fontSize: 14,
                    color: context.bodyTextColor,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _accessCodeController,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: context.l10n.accessCode,
                    hintText: context.l10n.accessCodeHint,
                    counterText: '',
                    prefixIcon: const Icon(Icons.lock_outline_rounded),
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
                    child: Text(context.l10n.useDifferentAccount),
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
