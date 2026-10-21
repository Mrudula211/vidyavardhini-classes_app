import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _load(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  final en = _load('en');
  final messageKeys = en.keys.where((k) => !k.startsWith('@'));

  for (final code in ['hi', 'mr']) {
    group('app_$code.arb', () {
      final arb = _load(code);

      test('has every English key and nothing extra', () {
        final enKeys = messageKeys.toSet();
        final keys = arb.keys.where((k) => !k.startsWith('@')).toSet();
        expect(enKeys.difference(keys), isEmpty, reason: 'untranslated keys');
        expect(keys.difference(enKeys), isEmpty, reason: 'unknown keys');
      });

      test('translations are non-empty and keep the same placeholders', () {
        for (final key in messageKeys) {
          final text = arb[key] as String;
          expect(text.trim(), isNotEmpty, reason: key);
          expect(
            _placeholders(text),
            _placeholders(en[key] as String),
            reason: 'placeholders differ for $key',
          );
        }
      });

      test('is actually translated (Devanagari present, not a copy of English)',
          () {
        final devanagari = RegExp(r'[\u0900-\u097F]');
        var untranslated = 0;
        for (final key in messageKeys) {
          final text = arb[key] as String;
          if (!devanagari.hasMatch(text)) untranslated++;
        }
        // A handful of keys are legitimately symbol-only; nearly all must be
        // in Devanagari.
        expect(untranslated, lessThan(3));
      });
    });
  }
}
