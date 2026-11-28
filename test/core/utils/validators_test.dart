import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/utils/validators.dart';

void main() {
  group('AppValidators - validateIndianPhone', () {
    test('returns error when phone is null or empty', () {
      expect(AppValidators.validateIndianPhone(null), isNotNull);
      expect(AppValidators.validateIndianPhone(''), isNotNull);
      expect(AppValidators.validateIndianPhone('   '), isNotNull);
    });

    test('returns error for invalid digit counts or invalid start digit', () {
      expect(AppValidators.validateIndianPhone('12345'), isNotNull);
      expect(AppValidators.validateIndianPhone('987654321'), isNotNull);
      expect(AppValidators.validateIndianPhone('98765432101'), isNotNull);
      // Indian mobile numbers start with 6, 7, 8, 9
      expect(AppValidators.validateIndianPhone('1234567890'), isNotNull);
      expect(AppValidators.validateIndianPhone('5234567890'), isNotNull);
    });

    test('returns null for valid 10-digit mobile numbers', () {
      expect(AppValidators.validateIndianPhone('9876543210'), isNull);
      expect(AppValidators.validateIndianPhone('8888602496'), isNull);
      expect(AppValidators.validateIndianPhone('7000000000'), isNull);
      expect(AppValidators.validateIndianPhone('6123456789'), isNull);
      expect(AppValidators.validateIndianPhone('98765 43210'), isNull);
    });
  });

  group('AppValidators - validateAccessCode', () {
    test('returns error when access code is null or empty', () {
      expect(AppValidators.validateAccessCode(null), isNotNull);
      expect(AppValidators.validateAccessCode(''), isNotNull);
      expect(AppValidators.validateAccessCode('  '), isNotNull);
    });

    test('returns error when access code is not 6 digits', () {
      expect(AppValidators.validateAccessCode('12345'), isNotNull);
      expect(AppValidators.validateAccessCode('1234567'), isNotNull);
      expect(AppValidators.validateAccessCode('12a456'), isNotNull);
    });

    test('returns null for valid 6-digit access code', () {
      expect(AppValidators.validateAccessCode('123456'), isNull);
      expect(AppValidators.validateAccessCode('000000'), isNull);
      expect(AppValidators.validateAccessCode('999999'), isNull);
    });
  });

  group('AppValidators - validateEmail', () {
    test('returns null when optional and empty', () {
      expect(AppValidators.validateEmail(null, isRequired: false), isNull);
      expect(AppValidators.validateEmail('', isRequired: false), isNull);
    });

    test('returns error when required and empty', () {
      expect(AppValidators.validateEmail(null, isRequired: true), isNotNull);
      expect(AppValidators.validateEmail('', isRequired: true), isNotNull);
    });

    test('returns error for invalid email structure', () {
      expect(AppValidators.validateEmail('invalid'), isNotNull);
      expect(AppValidators.validateEmail('invalid@'), isNotNull);
      expect(AppValidators.validateEmail('invalid@domain'), isNotNull);
      expect(AppValidators.validateEmail('@domain.com'), isNotNull);
    });

    test('returns null for valid email address', () {
      expect(
        AppValidators.validateEmail('siddhigharat81@gmail.com'),
        isNull,
      );
      expect(
        AppValidators.validateEmail('student.name@vidyavardhini.org'),
        isNull,
      );
    });
  });

  group('AppValidators - validateName', () {
    test('returns error when name is null, empty or too short', () {
      expect(AppValidators.validateName(null), isNotNull);
      expect(AppValidators.validateName(''), isNotNull);
      expect(AppValidators.validateName('A'), isNotNull);
    });

    test('returns error when name contains invalid characters', () {
      expect(AppValidators.validateName('John123'), isNotNull);
      expect(AppValidators.validateName('User@Name'), isNotNull);
    });

    test('returns null for valid names', () {
      expect(AppValidators.validateName('Siddhi Gharat'), isNull);
      expect(AppValidators.validateName('A. B. Sharma'), isNull);
      expect(AppValidators.validateName("O'Connor"), isNull);
    });
  });

  group('AppValidators - validateFeeAmount', () {
    test('returns error when amount is null or empty', () {
      expect(AppValidators.validateFeeAmount(null), isNotNull);
      expect(AppValidators.validateFeeAmount(''), isNotNull);
    });

    test('returns error for non-numeric or negative or extreme amount', () {
      expect(AppValidators.validateFeeAmount('abc'), isNotNull);
      expect(AppValidators.validateFeeAmount('-500'), isNotNull);
      expect(AppValidators.validateFeeAmount('2000000'), isNotNull);
    });

    test('returns null for valid fee amounts', () {
      expect(AppValidators.validateFeeAmount('0'), isNull);
      expect(AppValidators.validateFeeAmount('2500'), isNull);
      expect(AppValidators.validateFeeAmount('15,000'), isNull);
    });
  });

  group('AppValidators - validateDob', () {
    test('returns error when dob is null', () {
      expect(AppValidators.validateDob(null), isNotNull);
    });

    test('returns error when date is in future', () {
      final futureDate = DateTime.now().add(const Duration(days: 30));
      expect(AppValidators.validateDob(futureDate), isNotNull);
    });

    test('returns error when student is under minimum age', () {
      final infantDate = DateTime.now().subtract(const Duration(days: 365));
      expect(
        AppValidators.validateDob(infantDate, minimumAgeYears: 3),
        isNotNull,
      );
    });

    test('returns null for valid date of birth', () {
      final validDate = DateTime.now().subtract(const Duration(days: 365 * 10));
      expect(AppValidators.validateDob(validDate, minimumAgeYears: 3), isNull);
    });
  });
}
