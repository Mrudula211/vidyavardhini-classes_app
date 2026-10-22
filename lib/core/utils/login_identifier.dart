/// What a person typed into the "mobile number or email" box, normalised for
/// Supabase Auth. Indian mobile numbers are stored as `+91XXXXXXXXXX`.
class LoginIdentifier {
  const LoginIdentifier._({this.email, this.phone});

  const LoginIdentifier.email(String value) : this._(email: value);
  const LoginIdentifier.phone(String value) : this._(phone: value);

  final String? email;

  /// E.164 with a leading `+`, e.g. `+919876543210`.
  final String? phone;

  bool get isEmail => email != null;
  bool get isPhone => phone != null;

  /// Text to show people (and to put in messages).
  String get display => email ?? phone!;

  static final _emailPattern =
      RegExp(r'^[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}$');

  /// Returns null when [raw] is neither a usable email nor a 10-digit Indian
  /// mobile number. Accepts `98765 43210`, `+91 98765 43210`, `098765 43210`.
  static LoginIdentifier? parse(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;

    if (text.contains('@')) {
      return _emailPattern.hasMatch(text)
          ? LoginIdentifier.email(text.toLowerCase())
          : null;
    }

    var digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 12 && digits.startsWith('91')) {
      digits = digits.substring(2);
    } else if (digits.length == 11 && digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.length != 10) return null;
    return LoginIdentifier.phone('+91$digits');
  }

  @override
  bool operator ==(Object other) =>
      other is LoginIdentifier && other.email == email && other.phone == phone;

  @override
  int get hashCode => Object.hash(email, phone);
}
