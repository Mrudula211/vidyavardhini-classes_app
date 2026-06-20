import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  AppTypography._();

  // Heading font (Cinzel — decorative, traditional)
  static TextStyle cinzel({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontFamily: 'Cinzel',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
    );
  }

  // Body font (Poppins — clean, modern)
  static TextStyle poppins({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
    double? height,
  }) {
    return GoogleFonts.poppins(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  // Marathi / Hindi text (Mukta)
  static TextStyle mukta({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color? color,
  }) {
    return GoogleFonts.mukta(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextTheme lightTextTheme = TextTheme(
    // Display
    displayLarge: cinzel(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.maroon),
    displayMedium: cinzel(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.maroon),
    displaySmall: cinzel(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.maroon),

    // Headline
    headlineLarge: cinzel(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.brown),
    headlineMedium: cinzel(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.brown),
    headlineSmall: cinzel(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.brown),

    // Title
    titleLarge: poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.brown),
    titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.brown),
    titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.brown),

    // Body
    bodyLarge: poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.lightOnBackground),
    bodyMedium: poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.lightOnBackground),
    bodySmall: poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.lightOnBackground),

    // Label
    labelLarge: poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.brown),
    labelMedium: poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.brown),
    labelSmall: poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.brown),
  );

  static TextTheme darkTextTheme = TextTheme(
    displayLarge: cinzel(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.gold),
    displayMedium: cinzel(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.gold),
    displaySmall: cinzel(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.gold),

    headlineLarge: cinzel(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.goldLight),
    headlineMedium: cinzel(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.goldLight),
    headlineSmall: cinzel(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.goldLight),

    titleLarge: poppins(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
    titleMedium: poppins(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),
    titleSmall: poppins(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkOnBackground),

    bodyLarge: poppins(fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.darkOnSurface),
    bodyMedium: poppins(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.darkOnSurface),
    bodySmall: poppins(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.darkOnSurface),

    labelLarge: poppins(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.goldLight),
    labelMedium: poppins(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.goldLight),
    labelSmall: poppins(fontSize: 10, fontWeight: FontWeight.w500, color: AppColors.goldLight),
  );
}
