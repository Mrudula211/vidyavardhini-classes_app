import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/constants/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../l10n/l10n_context.dart';
import '../../../shared/widgets/language_switcher.dart';

/// First screen after the splash. One door for everyone: students, parents,
/// teachers and the admin all start with "Login"; the account decides which
/// dashboard they land on.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

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
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Semantics(
                            container: true,
                            label: l10n.language,
                            child: const LanguageSwitcher(onDark: true),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      const _LogoBadge(),
                      const SizedBox(height: 20),
                      Text(
                        AppConstants.appName,
                        textAlign: TextAlign.center,
                        style: AppTypography.cinzel(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.parchment,
                          letterSpacing: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        AppConstants.appTaglineSanskrit,
                        style: AppTypography.mukta(
                          fontSize: 16,
                          color: AppColors.goldLight,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.welcomeTagline,
                        textAlign: TextAlign.center,
                        style: AppTypography.poppins(
                          fontSize: 13,
                          color: AppColors.parchment.withValues(alpha: 0.75),
                        ),
                      ),
                      const Spacer(flex: 3),
                      _ActionSheet(l10n: l10n),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LogoBadge extends StatelessWidget {
  const _LogoBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 148,
      height: 148,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.parchment,
        border: Border.all(color: AppColors.gold, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('images/logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  const _ActionSheet({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: const BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.maroon,
                foregroundColor: AppColors.parchment,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () => context.go(Routes.phone),
              icon: const Icon(Icons.login_rounded),
              label: Text(
                l10n.welcomeLogin,
                style: AppTypography.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.parchment,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.maroon,
                side: const BorderSide(color: AppColors.gold, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () =>
                  context.go(Routes.phone, extra: {'register': true}),
              child: Text(
                l10n.welcomeRegister,
                textAlign: TextAlign.center,
                style: AppTypography.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.maroon,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.welcomeHint,
            textAlign: TextAlign.center,
            style: AppTypography.poppins(
              fontSize: 12,
              color: AppColors.brown.withValues(alpha: 0.75),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
