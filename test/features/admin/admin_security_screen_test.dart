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

Future<void> _save(WidgetTester t) async {
  await t.ensureVisible(find.text('SAVE'));
  await t.tap(find.text('SAVE'));
  await t.pumpAndSettle();
}

void main() {
  late _MockAuthRepository repo;

  setUp(() => repo = _MockAuthRepository());

  testWidgets('asks for the current and the new password', (t) async {
    await t.pumpWidget(_host(repo));
    await _save(t);
    expect(find.text('Enter your current password'), findsOneWidget);
    expect(find.text('Enter a new password'), findsOneWidget);
    verifyNever(() => repo.confirmCurrentPassword(any()));
  });

  testWidgets('has no access-code fields any more', (t) async {
    await t.pumpWidget(_host(repo));
    expect(find.textContaining('access code'), findsNothing);
  });

  testWidgets('rejects a short or unchanged new password', (t) async {
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'New password', 'short');
    await _save(t);
    expect(find.text('Use at least 8 characters'), findsOneWidget);

    await _fill(t, 'New password', 'old-password');
    await _save(t);
    expect(find.text('The new password must be different'), findsOneWidget);
  });

  testWidgets('rejects a confirmation that does not match', (t) async {
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'New password', 'a-new-password');
    await _fill(t, 'Confirm new password', 'something-else');
    await _save(t);
    expect(find.text('Passwords do not match'), findsOneWidget);
    verifyNever(() => repo.confirmCurrentPassword(any()));
  });

  testWidgets('a wrong current password changes nothing', (t) async {
    when(() => repo.confirmCurrentPassword(any()))
        .thenAnswer((_) async => false);
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'wrong-password');
    await _fill(t, 'New password', 'a-new-password');
    await _fill(t, 'Confirm new password', 'a-new-password');
    await _save(t);

    expect(find.text('Your current password is not correct.'), findsOneWidget);
    verifyNever(() => repo.setPassword(any()));
  });

  testWidgets('the right current password saves the new one', (t) async {
    when(() => repo.confirmCurrentPassword('old-password'))
        .thenAnswer((_) async => true);
    when(() => repo.setPassword(any())).thenAnswer((_) async {});
    await t.pumpWidget(_host(repo));
    await _fill(t, 'Current password', 'old-password');
    await _fill(t, 'New password', 'a-new-password');
    await _fill(t, 'Confirm new password', 'a-new-password');
    await _save(t);

    verify(() => repo.setPassword('a-new-password')).called(1);
  });
}
