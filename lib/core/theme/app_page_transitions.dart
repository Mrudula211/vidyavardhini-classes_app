import 'package:flutter/material.dart';

/// Soft fade + slight horizontal slide used as the app-wide page transition.
class FadeSlidePageTransitionsBuilder extends PageTransitionsBuilder {
  const FadeSlidePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.03, 0),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Shared [PageTransitionsTheme] for light and dark themes.
const appPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.iOS: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.windows: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.macOS: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.linux: FadeSlidePageTransitionsBuilder(),
    TargetPlatform.fuchsia: FadeSlidePageTransitionsBuilder(),
  },
);
