import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyavardhini_classes/features/auth/screens/admin_login_screen.dart';

Widget _host() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const AdminLoginScreen()),
    ],
  );
  return ProviderScope(child: MaterialApp.router(routerConfig: router));
}

void main() {
  testWidgets('empty submit shows both validation errors', (t) async {
    await t.pumpWidget(_host());
    await t.pump();
    await t.tap(find.text('Login'));
    await t.pump();
    expect(find.text('Enter your email or access code'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
  });

  testWidgets('password visibility toggle flips obscureText', (t) async {
    await t.pumpWidget(_host());
    await t.pump();
    bool obscured() => t
        .widget<TextField>(find.byType(TextField).last)
        .obscureText;
    expect(obscured(), isTrue);
    await t.tap(find.byTooltip('Show password'));
    await t.pump();
    expect(obscured(), isFalse);
  });
}
