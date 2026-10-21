import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyavardhini_classes/features/auth/providers/auth_providers.dart';
import 'package:vidyavardhini_classes/features/auth/screens/admin_login_screen.dart';

Widget _host() {
  final router = GoRouter(
    routes: [
      GoRoute(path: '/', builder: (_, __) => const AdminLoginScreen()),
    ],
  );
  return ProviderScope(
    overrides: [currentUserProvider.overrideWithValue(null)],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  testWidgets('empty submit shows all validation errors', (t) async {
    await t.pumpWidget(_host());
    await t.pump();
    await t.tap(find.text('Login'));
    await t.pump();
    expect(find.text('Enter your admin email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    expect(find.text('Enter the 6-digit access code'), findsOneWidget);
  });

  testWidgets('password visibility toggle flips obscureText', (t) async {
    await t.pumpWidget(_host());
    await t.pump();
    bool obscured() =>
        t.widget<TextField>(find.byType(TextField).at(1)).obscureText;
    expect(obscured(), isTrue);
    await t.tap(find.byTooltip('Show password'));
    await t.pump();
    expect(obscured(), isFalse);
  });
}
