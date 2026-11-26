import 'dart:math';

/// A teacher's login is a 6-digit access code (it is their password), so the
/// obvious codes must never be handed out.
class TeacherCode {
  TeacherCode._();

  static final _digits = RegExp(r'^[0-9]{6}$');

  /// Null when [code] is acceptable, otherwise a message for the admin.
  static String? validate(String? code) {
    final c = (code ?? '').trim();
    if (!_digits.hasMatch(c)) return 'Enter exactly 6 digits';
    if (_isWeak(c)) {
      return 'Too easy to guess (for example 123456 or 000000). Choose another.';
    }
    return null;
  }

  /// A random code that passes [validate].
  static String generate([Random? random]) {
    final rng = random ?? Random.secure();
    while (true) {
      final code = (100000 + rng.nextInt(900000)).toString();
      if (validate(code) == null) return code;
    }
  }

  static bool _isWeak(String c) {
    if (c.split('').toSet().length <= 2) return true; // 111111, 121212, 000111
    const ascending = '0123456789';
    const descending = '9876543210';
    if (ascending.contains(c) || descending.contains(c)) return true;
    if (c.substring(0, 3) == c.substring(3)) return true; // 123123
    return false;
  }
}
