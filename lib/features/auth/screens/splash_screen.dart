import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scaleIn;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _scaleIn = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );
    _controller.forward();
    _navigateSafely();
  }

  Future<void> _navigateSafely() async {
    try {
      await _navigate();
    } catch (_) {
      // Network or permission error: fall back to the welcome screen rather
      // than spinning forever.
      if (mounted) context.go(Routes.roleSelect);
    }
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    final session = Supabase.instance.client.auth.currentSession;
    if (session?.user != null) {
      final userId = session!.user.id;
      final response = await Supabase.instance.client
          .from('users')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (!mounted) return;

      if (response is Map<String, dynamic>) {
        final role = response['role'] as String?;
        switch (role) {
          case 'admin':
            context.go(Routes.adminDashboard);
            return;
          case 'teacher':
            context.go(Routes.teacherDashboard);
            return;
          case 'student':
            final statusResponse = await Supabase.instance.client
                .from('student_profiles')
                .select('status')
                .eq('id', userId)
                .maybeSingle();

            if (!mounted) return;

            final status = (statusResponse is Map<String, dynamic>)
                ? statusResponse['status'] as String?
                : null;

            if (status == 'pending') {
              context.go(Routes.pendingApproval);
              return;
            }
            if (status == null || status == 'rejected' || status == 'banned') {
              await Supabase.instance.client.auth.signOut();
              if (!mounted) return;
              context.go(Routes.roleSelect);
              return;
            }
            context.go(Routes.studentDashboard);
            return;
          default:
            context.go(Routes.roleSelect);
            return;
        }
      }
    }

    context.go(Routes.roleSelect);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.maroon,
      body: Center(
        child: FadeTransition(
          opacity: _fadeIn,
          child: ScaleTransition(
            scale: _scaleIn,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                Image.asset(
                  'images/logo.png',
                  width: 180,
                  height: 180,
                ),
                const SizedBox(height: 24),

                // App name
                Text(
                  AppConstants.appName,
                  style: AppTypography.cinzel(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.parchment,
                    letterSpacing: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Sanskrit tagline
                Text(
                  AppConstants.appTaglineSanskrit,
                  style: AppTypography.mukta(
                    fontSize: 14,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 4),

                // English tagline
                Text(
                  AppConstants.appTaglineEnglish,
                  style: AppTypography.poppins(
                    fontSize: 12,
                    color: AppColors.parchment.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 48),

                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.gold.withValues(alpha: 0.8),
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
