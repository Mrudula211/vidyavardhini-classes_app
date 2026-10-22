import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class AppLogoHeader extends StatelessWidget {
  const AppLogoHeader({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          'images/logo.png',
          width: compact ? 40 : 52,
          height: compact ? 40 : 52,
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vidyavardhini',
              style: AppTypography.cinzel(
                fontSize: compact ? 14 : 17,
                fontWeight: FontWeight.w700,
                color: context.headingColor,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              'Classes',
              style: AppTypography.cinzel(
                fontSize: compact ? 12 : 14,
                fontWeight: FontWeight.w400,
                color: context.bodyTextColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
