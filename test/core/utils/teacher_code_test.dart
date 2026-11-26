import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/utils/teacher_code.dart';

void main() {
  group('TeacherCode.validate', () {
    test('accepts an ordinary 6-digit code', () {
      expect(TeacherCode.validate('482915'), isNull);
    });

    test('rejects wrong length and non-digits', () {
      expect(TeacherCode.validate(''), isNotNull);
      expect(TeacherCode.validate(null), isNotNull);
      expect(TeacherCode.validate('12345'), isNotNull);
      expect(TeacherCode.validate('1234567'), isNotNull);
      expect(TeacherCode.validate('48291a'), isNotNull);
    });

    test('rejects guessable codes', () {
      const weak = [
        '000000',
        '111111',
        '123456',
        '654321',
        '121212',
        '123123',
        '456789',
      ];
      for (final c in weak) {
        expect(TeacherCode.validate(c), isNotNull, reason: c);
      }
    });
  });

  test('generate always returns an acceptable code', () {
    for (var i = 0; i < 500; i++) {
      expect(TeacherCode.validate(TeacherCode.generate()), isNull);
    }
  });
}
