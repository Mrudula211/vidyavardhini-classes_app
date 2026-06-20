import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.maroon, AppColors.brown],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 48),

                Image.asset('images/logo.png', width: 120, height: 120),
                const SizedBox(height: 16),

                Text(
                  AppConstants.appName,
                  style: AppTypography.cinzel(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.parchment,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.appTaglineSanskrit,
                  style: AppTypography.mukta(
                    fontSize: 13,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 56),

                Text(
                  'Who are you?',
                  style: AppTypography.cinzel(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.parchment,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 32),

                _RoleCard(
                  icon: Icons.admin_panel_settings_rounded,
                  label: 'Admin',
                  subtitle: 'Owner / Manager',
                  onTap: () => context.go(
                    Routes.phone,
                    extra: {'role': 'admin'},
                  ),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.school_rounded,
                  label: 'Teacher',
                  subtitle: 'Instructor',
                  onTap: () => context.go(
                    Routes.phone,
                    extra: {'role': 'teacher'},
                  ),
                ),
                const SizedBox(height: 16),
                _RoleCard(
                  icon: Icons.person_rounded,
                  label: 'Student',
                  subtitle: 'Enrolled learner',
                  onTap: () => context.go(
                    Routes.phone,
                    extra: {'role': 'student'},
                  ),
                ),

                const Spacer(),
                Text(
                  'Mrs. Siddhi Gharat',
                  style: AppTypography.poppins(
                    fontSize: 11,
                    color: AppColors.parchment.withOpacity(0.4),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.parchment.withOpacity(0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.gold.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.gold, size: 26),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.parchment,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.poppins(
                      fontSize: 12,
                      color: AppColors.parchment.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}
