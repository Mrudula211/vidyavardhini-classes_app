import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: const ColorScheme.light(
          primary: AppColors.maroon,
          onPrimary: AppColors.parchment,
          primaryContainer: AppColors.maroonLight,
          onPrimaryContainer: AppColors.parchment,
          secondary: AppColors.gold,
          onSecondary: AppColors.brown,
          secondaryContainer: AppColors.goldLight,
          onSecondaryContainer: AppColors.brown,
          tertiary: AppColors.brown,
          onTertiary: AppColors.parchment,
          surface: AppColors.lightSurface,
          onSurface: AppColors.lightOnSurface,
          surfaceContainerHighest: AppColors.lightSurfaceVariant,
          outline: AppColors.lightOutline,
          error: AppColors.error,
          onError: Colors.white,
        ),
        scaffoldBackgroundColor: AppColors.lightBackground,
        textTheme: AppTypography.lightTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.parchment,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.parchment,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.lightSurface,
          elevation: 2,
          shadowColor: AppColors.brown.withValues(alpha: 0.15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: AppColors.lightOutline.withValues(alpha: 0.4),
            ),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.maroon,
            foregroundColor: AppColors.parchment,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AppTypography.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.maroon,
            side: const BorderSide(color: AppColors.maroon),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AppTypography.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.maroon,
            textStyle: AppTypography.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.lightSurface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.lightOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.maroon, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          labelStyle:
              AppTypography.poppins(fontSize: 14, color: AppColors.brown),
          hintStyle: AppTypography.poppins(
            fontSize: 14,
            color: AppColors.lightOutline,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.lightSurfaceVariant,
          selectedColor: AppColors.maroon,
          labelStyle: AppTypography.poppins(fontSize: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        dividerTheme: const DividerThemeData(
          color: AppColors.lightOutline,
          thickness: 0.5,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.lightSurface,
          selectedItemColor: AppColors.maroon,
          unselectedItemColor: AppColors.lightOutline,
          selectedLabelStyle:
              AppTypography.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.poppins(fontSize: 11),
          type: BottomNavigationBarType.fixed,
          elevation: 8,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.maroon,
          foregroundColor: AppColors.parchment,
        ),
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.brown,
          contentTextStyle:
              AppTypography.poppins(fontSize: 14, color: AppColors.parchment),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          onPrimary: AppColors.brown,
          primaryContainer: AppColors.goldDark,
          onPrimaryContainer: AppColors.parchment,
          secondary: AppColors.maroonLight,
          onSecondary: AppColors.parchment,
          secondaryContainer: AppColors.maroon,
          onSecondaryContainer: AppColors.parchment,
          tertiary: AppColors.parchment,
          onTertiary: AppColors.brown,
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkOnSurface,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          outline: AppColors.darkOutline,
          error: Color(0xFFEF9A9A),
          onError: AppColors.darkBackground,
        ),
        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: AppTypography.darkTextTheme,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.gold,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTypography.cinzel(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.gold,
            letterSpacing: 1.2,
          ),
        ),
        cardTheme: CardThemeData(
          color: AppColors.darkSurface,
          elevation: 4,
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side:
                BorderSide(color: AppColors.darkOutline.withValues(alpha: 0.5)),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.brown,
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AppTypography.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.gold,
            side: const BorderSide(color: AppColors.gold),
            minimumSize: const Size(double.infinity, 52),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: AppTypography.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkOutline),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.darkOutline),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.gold, width: 2),
          ),
          labelStyle:
              AppTypography.poppins(fontSize: 14, color: AppColors.goldLight),
          hintStyle:
              AppTypography.poppins(fontSize: 14, color: AppColors.darkOutline),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: AppColors.darkSurface,
          selectedItemColor: AppColors.gold,
          unselectedItemColor: AppColors.darkOutline,
          selectedLabelStyle:
              AppTypography.poppins(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.poppins(fontSize: 11),
          type: BottomNavigationBarType.fixed,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.gold,
          foregroundColor: AppColors.brown,
        ),
      );
}
