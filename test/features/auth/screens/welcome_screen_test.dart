import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:vidyavardhini_classes/core/constants/routes.dart';
import 'package:vidyavardhini_classes/core/providers/locale_provider.dart';
import 'package:vidyavardhini_classes/features/auth/screens/phone_entry_screen.dart'
    show roleDestination;
import 'package:vidyavardhini_classes/features/auth/screens/welcome_screen.dart';
import 'package:vidyavardhini_classes/l10n/app_localizations.dart';

class _Harness extends ConsumerWidget {
  const _Harness({required this.router});
  final GoRouter router;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}

GoRouter _router() => GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const WelcomeScreen()),
        GoRoute(
          path: Routes.phone,
          builder: (_, state) => Scaffold(
            body: Text(
              'PHONE register=${(state.extra as Map?)?['register'] ?? false}',
            ),
          ),
        ),
      ],
    );

Future<void> _pump(WidgetTester t) async {
  t.view.physicalSize = const Size(800, 1600);
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(child: _Harness(router: _router())),
  );
  await t.pumpAndSettle();
}

void main() {
  testWidgets('shows one Login door, no role picker', (t) async {
    await _pump(t);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('New student? Register here'), findsOneWidget);
    // The old role cards are gone.
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Teacher'), findsNothing);
    expect(find.text('Who are you?'), findsNothing);
  });

  testWidgets('language chips switch the whole screen to Hindi and Marathi',
      (t) async {
    await _pump(t);
    await t.tap(find.text('हिन्दी'));
    await t.pumpAndSettle();
    expect(find.text('लॉगिन करें'), findsOneWidget);
    expect(find.text('Login'), findsNothing);

    await t.tap(find.text('मराठी'));
    await t.pumpAndSettle();
    expect(find.text('लॉगिन करा'), findsOneWidget);

    await t.tap(find.text('English'));
    await t.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('Login and Register both go to the single phone screen',
      (t) async {
    await _pump(t);
    await t.tap(find.text('Login'));
    await t.pumpAndSettle();
    expect(find.text('PHONE register=false'), findsOneWidget);

    final router = _router();
    t.view.physicalSize = const Size(800, 1600);
    await t.pumpWidget(ProviderScope(child: _Harness(router: router)));
    await t.pumpAndSettle();
    await t.tap(find.text('New student? Register here'));
    await t.pumpAndSettle();
    expect(find.text('PHONE register=true'), findsOneWidget);
  });

  test('roleDestination sends each role to the right next step', () {
    expect(roleDestination('admin'), Routes.adminLogin);
    expect(roleDestination('teacher'), Routes.teacherLogin);
    expect(roleDestination('student'), Routes.studentDashboard);
    expect(roleDestination(null), Routes.studentDashboard);
  });
}
