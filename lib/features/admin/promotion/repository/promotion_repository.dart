import 'package:supabase_flutter/supabase_flutter.dart';

class AcademicYearInfo {
  const AcademicYearInfo({
    required this.id,
    required this.label,
    required this.startDate,
    required this.endDate,
  });

  final String id;
  final String label;
  final DateTime startDate;
  final DateTime endDate;

  factory AcademicYearInfo.fromJson(Map<String, dynamic> json) {
    return AcademicYearInfo(
      id: json['id'] as String,
      label: json['year_label'] as String,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
    );
  }
}

class PromotionResult {
  const PromotionResult({required this.promoted, required this.archived});

  final int promoted;
  final int archived;
}

/// Academic-year promotion. All guards (CONFIRM text, admin password, recent
/// OTP login, admin role) are enforced by the `promote_students` database
/// function; the app only collects the inputs.
class PromotionRepository {
  PromotionRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<AcademicYearInfo?> fetchCurrentYear() async {
    final data = await _client
        .from('academic_years')
        .select()
        .eq('is_current', true)
        .maybeSingle();
    return data == null ? null : AcademicYearInfo.fromJson(data);
  }

  static String _e164(String phone) =>
      phone.startsWith('+') ? phone : '+$phone';

  /// Sends an SMS code to the admin's own phone.
  Future<void> sendOtp(String phone) {
    return _client.auth.signInWithOtp(
      phone: _e164(phone),
      shouldCreateUser: false,
    );
  }

  /// Verifies the SMS code (which refreshes the session with an OTP proof)
  /// and then runs the promotion.
  Future<PromotionResult> verifyOtpAndPromote({
    required String phone,
    required String otp,
    required String confirmText,
    required String password,
    required String yearLabel,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    await _client.auth.verifyOTP(
      phone: _e164(phone),
      token: otp,
      type: OtpType.sms,
    );

    final res = await _client.rpc('promote_students', params: {
      'p_confirm': confirmText,
      'p_password': password,
      'p_year_label': yearLabel,
      'p_start_date': _date(startDate),
      'p_end_date': _date(endDate),
    },);
    final map = Map<String, dynamic>.from(res as Map);
    return PromotionResult(
      promoted: (map['promoted'] as num).toInt(),
      archived: (map['archived'] as num).toInt(),
    );
  }

  static String _date(DateTime d) => d.toIso8601String().split('T').first;
}
