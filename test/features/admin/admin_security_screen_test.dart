import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:vidyavardhini_classes/core/providers/connectivity_provider.dart';
import 'package:vidyavardhini_classes/features/admin/settings/admin_security_screen.dart';
import 'package:vidyavardhini_classes/features/auth/providers/auth_providers.dart';
import 'package:vidyavardhini_classes/features/auth/repository/auth_repository.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

Widget _host(AuthRepository repo) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(repo),
      isOnlineProvider.overrideWithValue(true),
    ],
    child: const MaterialApp(home: AdminSecurityScreen()),
  );
}

Future<void> _fill(WidgetTester t, String label, String text) async {
  await t.enterText(find.widgetWithText(TextFormField, label), text);
}

void main() {
  late _MockAuthRepository repo;

  setUp(() => repo = _MockAuthRepository());

  testWidgets('asks for the current password and access code', (t) async {
    await t.pumpWidget(_host(repo));
    await t.ensureVisible(find.text('SAVE'));
    await t.tap(find.text('SAVE'));
    await t.pump();
    expect(find.text('Enter your current password'), findsOneWidget);
    expect(find.text('Enter your current 6-digit access code'), findsOneWidget);
    verifyNever(() => repo.verifyAdminCredentials(any(), any()));
  });

  testWidgets('requires a new password or a new access code', (t) async {
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'Current access code', '123456');
    await t.ensureVisible(find.text('SAVE'));
    await t.tap(find.text('SAVE'));
    await t.pump();
    expect(
      find.text('Enter a new password and/or a new access code.'),
      findsOneWidget,
    );
    verifyNever(() => repo.verifyAdminCredentials(any(), any()));
  });

  testWidgets('rejects a short password and a non-6-digit code', (t) async {
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'Current access code', '123456');
    await _fill(t, 'New password', 'short');
    await _fill(t, 'New access code (6 digits)', '12');
    await t.ensureVisible(find.text('SAVE'));
    await t.tap(find.text('SAVE'));
    await t.pump();
    expect(find.text('Use at least 8 characters'), findsOneWidget);
    expect(
      find.text('The access code must be exactly 6 digits'),
      findsOneWidget,
    );
  });

  testWidgets('wrong current credentials change nothing', (t) async {
    when(() => repo.verifyAdminCredentials(any(), any()))
        .thenAnswer((_) async => false);
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'Current access code', '123456');
    await _fill(t, 'New password', 'a-new-password');
    await _fill(t, 'Confirm new password', 'a-new-password');
    await t.ensureVisible(find.text('SAVE'));
    await t.tap(find.text('SAVE'));
    await t.pumpAndSettle();

    expect(
      find.text('Your current password or access code is not correct.'),
      findsOneWidget,
    );
    verifyNever(() => repo.setPassword(any()));
    verifyNever(
      () => repo.changeAdminAccessCode(
        currentPassword: any(named: 'currentPassword'),
        newCode: any(named: 'newCode'),
      ),
    );
  });
}
