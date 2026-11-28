import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/providers/connectivity_provider.dart';
import 'package:vidyavardhini_classes/features/admin/students/screens/add_student_screen.dart';
import 'package:vidyavardhini_classes/features/admin/students/widgets/access_code_card.dart';

Widget _host(Widget child) => ProviderScope(
      overrides: [isOnlineProvider.overrideWithValue(true)],
      child: MaterialApp(home: child),
    );

Future<void> _scrollTo(WidgetTester t, Finder f) async {
  await t.ensureVisible(f);
  await t.pump();
}

void main() {
  testWidgets('empty form shows the required-field messages', (t) async {
    t.view.physicalSize = const Size(1000, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(_host(const AddStudentScreen()));
    final button = find.text('ADD STUDENT');
    await _scrollTo(t, button);
    await t.tap(button);
    await t.pump();

    expect(find.text('Enter the student name'), findsOneWidget);
    expect(find.text('Enter the school name'), findsOneWidget);
    expect(find.text('Enter the parent name'), findsOneWidget);
    expect(find.text('Enter the monthly fee'), findsOneWidget);
    expect(
      find.text('Enter a 10-digit mobile number'),
      findsOneWidget,
    ); // parent mobile
    expect(
      find.text('Enter a 10-digit mobile number or a valid email'),
      findsOneWidget,
    ); // login
  });

  testWidgets('the login box accepts a mobile number or an email', (t) async {
    t.view.physicalSize = const Size(1000, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);

    await t.pumpWidget(_host(const AddStudentScreen()));
    final login = find.widgetWithText(
      TextFormField,
      'Login mobile number or email *',
    );

    for (final value in ['9876543210', 'parent@example.com']) {
      await t.enterText(login, value);
      final button = find.text('ADD STUDENT');
      await _scrollTo(t, button);
      await t.tap(button);
      await t.pump();
      expect(
        find.text('Enter a 10-digit mobile number or a valid email'),
        findsNothing,
        reason: value,
      );
    }

    await t.enterText(login, '12345');
    final button = find.text('ADD STUDENT');
    await _scrollTo(t, button);
    await t.tap(button);
    await t.pump();
    expect(
      find.text('Enter a 10-digit mobile number or a valid email'),
      findsOneWidget,
    );
  });

  testWidgets('AccessCodeCard shows the login and code', (t) async {
    await t.pumpWidget(
      _host(
        const Scaffold(
          body: AccessCodeCard(
            logins: ['+919876543210', 'a@b.com'],
            accessCode: 'K7M2PQ9X',
          ),
        ),
      ),
    );
    expect(find.text('+919876543210'), findsOneWidget);
    expect(find.text('a@b.com'), findsOneWidget);
    expect(find.text('Login (mobile number)'), findsOneWidget);
    expect(find.text('Login (email)'), findsOneWidget);
    expect(find.text('K7M2PQ9X'), findsOneWidget);
    expect(find.text('Generate a new code'), findsNothing);
  });

  testWidgets('AccessCodeCard offers a new code when it can regenerate',
      (t) async {
    var tapped = false;
    await t.pumpWidget(
      _host(
        Scaffold(
          body: AccessCodeCard(
            logins: const ['a@b.com'],
            accessCode: null,
            onRegenerate: () => tapped = true,
          ),
        ),
      ),
    );
    expect(find.text('Not available'), findsOneWidget);
    await t.tap(find.text('Generate a new code'));
    expect(tapped, isTrue);
  });
}
