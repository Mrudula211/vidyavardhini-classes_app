# 09 Theme

## Purpose
Documents the application's theming implementation (colors, typography, light/dark mode).

## Current State
✅ Implemented. `AppTheme`, `AppColors`, and `AppTypography` are fully fleshed out.

## Detailed Explanation
-   **`AppColors.dart`:** Defines a semantic color palette (Maroon, Gold, Parchment) and status colors (Present/Absent, Paid/Pending). Includes distinct hex values for Light and Dark modes.
-   **`AppTypography.dart`:** Uses `google_fonts` for Poppins and Mukta, and a local asset for Cinzel. Defines distinct `TextTheme` objects for light and dark modes mapping semantic HTML-like tags (displayLarge, bodyMedium) to specific fonts.
-   **`AppTheme.dart`:** Constructs the `ThemeData` objects for `MaterialApp`, styling core components like `AppBar`, `ElevatedButton`, `InputDecoration`, and `BottomNavigationBar`.

## Observations
-   The theming setup is robust and highly scalable. Using `Theme.of(context)` will automatically apply the correct styles across the app.

## Problems
-   None in the implementation logic. (Font file missing as noted elsewhere).

## Recommendations
-   Avoid hardcoding colors or text styles in UI widgets. Always use `Theme.of(context).colorScheme` or `AppColors` constants to ensure dark mode compatibility.

## Cross-References
- [07_UI_ANALYSIS.md](07_UI_ANALYSIS.md)
