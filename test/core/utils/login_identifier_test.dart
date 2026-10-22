import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/utils/login_identifier.dart';

void main() {
  group('LoginIdentifier.parse', () {
    test('recognises emails and lower-cases them', () {
      final id = LoginIdentifier.parse('  Parent@Example.COM ');
      expect(id!.isEmail, isTrue);
      expect(id.email, 'parent@example.com');
    });

    test('rejects malformed emails', () {
      expect(LoginIdentifier.parse('not-an-email@'), isNull);
      expect(LoginIdentifier.parse('a@b'), isNull);
    });

    test('accepts a plain 10-digit mobile number', () {
      final id = LoginIdentifier.parse('9876543210');
      expect(id!.isPhone, isTrue);
      expect(id.phone, '+919876543210');
    });

    test('tolerates spaces, +91, 91 and a leading zero', () {
      for (final raw in [
        '98765 43210',
        '+91 98765 43210',
        '919876543210',
        '09876543210',
        '+91-9876543210',
      ]) {
        expect(LoginIdentifier.parse(raw)!.phone, '+919876543210', reason: raw);
      }
    });

    test('rejects wrong-length numbers and empty input', () {
      expect(LoginIdentifier.parse('12345'), isNull);
      expect(LoginIdentifier.parse('98765432101'), isNull);
      expect(LoginIdentifier.parse('   '), isNull);
      expect(LoginIdentifier.parse(''), isNull);
    });

    test('equal identifiers compare equal', () {
      expect(
        LoginIdentifier.parse('9876543210'),
        LoginIdentifier.parse('+91 9876543210'),
      );
    });
  });
}
