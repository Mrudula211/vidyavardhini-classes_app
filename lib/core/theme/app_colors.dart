import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand palette
  static const Color parchment = Color(0xFFF5EFE0);
  static const Color gold = Color(0xFFC68A2D);
  static const Color goldLight = Color(0xFFE6AA4A);
  static const Color goldDark = Color(0xFF9E6B1E);
  static const Color maroon = Color(0xFF7B2D26);
  static const Color maroonLight = Color(0xFFA84038);
  static const Color maroonDark = Color(0xFF561E1A);
  static const Color brown = Color(0xFF4A2C1A);
  static const Color brownLight = Color(0xFF6B3F25);

  // Primary & secondary aliases
  static const Color primary = maroon;
  static const Color primaryVariant = maroonDark;
  static const Color secondary = gold;
  static const Color secondaryVariant = goldDark;

  // Light mode
  static const Color lightBackground = parchment;
  static const Color lightSurface = Color(0xFFFDF8F0);
  static const Color lightSurfaceVariant = Color(0xFFEDE3CC);
  static const Color lightOnBackground = brown;
  static const Color lightOnSurface = Color(0xFF3D2510);
  static const Color lightOutline = Color(0xFFB8A88A);

  // Dark mode
  static const Color darkBackground = Color(0xFF1A1208);
  static const Color darkSurface = Color(0xFF2C1F10);
  static const Color darkSurfaceVariant = Color(0xFF3D2C18);
  static const Color darkOnBackground = parchment;
  static const Color darkOnSurface = Color(0xFFEDE3CC);
  static const Color darkOutline = Color(0xFF6B5030);

  // Semantic colors
  static const Color success = Color(0xFF2E7D32);
  static const Color successLight = Color(0xFFE8F5E9);
  static const Color warning = Color(0xFFF57F17);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color error = Color(0xFFC62828);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color info = Color(0xFF1565C0);
  static const Color infoLight = Color(0xFFE3F2FD);

  // Status colors (attendance / fees)
  static const Color statusPresent = Color(0xFF388E3C);
  static const Color statusAbsent = Color(0xFFD32F2F);
  static const Color statusPaid = Color(0xFF2E7D32);
  static const Color statusPartial = Color(0xFFF57F17);
  static const Color statusPending = Color(0xFFD32F2F);
  static const Color statusActive = Color(0xFF388E3C);
  static const Color statusInactive = Color(0xFF757575);
  static const Color statusBanned = Color(0xFFB71C1C);

  // Heatmap colors (attendance calendar)
  static const Color heatmapHigh = Color(0xFF2E7D32);
  static const Color heatmapMedium = Color(0xFFF9A825);
  static const Color heatmapLow = Color(0xFFC62828);
  static const Color heatmapNone = Color(0xFFEEEEEE);
}

/// Text colours that stay readable in both themes. The raw brand colours
/// (maroon, brown) are only legible on the light parchment background.
extension ThemeTone on BuildContext {
  bool get isDarkTheme => Theme.of(this).brightness == Brightness.dark;

  /// Headings and emphasis: maroon on light, warm gold on dark.
  Color get headingColor =>
      isDarkTheme ? AppColors.goldLight : AppColors.maroon;

  /// Regular body text: brown on light, parchment on dark.
  Color get bodyTextColor =>
      isDarkTheme ? AppColors.darkOnBackground : AppColors.brown;

  /// Secondary / hint text.
  Color get mutedTextColor => isDarkTheme
      ? AppColors.darkOnBackground.withValues(alpha: 0.65)
      : AppColors.brownLight.withValues(alpha: 0.8);
}
