import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<void> sendOtp(String phone) async {
    await _client.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<Session?> verifyOtp(String phone, String otp, String role) async {
    await _client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    final session = _client.auth.currentSession;
    final user = session?.user;
    if (user == null) {
      throw Exception('OTP verification failed. User session missing.');
    }

    await ensureUserProfile(user.id, phone, role);
    return session;
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Stream<Session?> authStateChanges() {
    return _client.auth.onAuthStateChange
        .map((event) => event.session);
  }

  @override
  Session? get currentSession => _client.auth.currentSession;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Future<String?> fetchUserRole(String userId) async {
    final response = await _client
        .from('users')
        .select('role')
        .eq('id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response['role'] as String?;
    }
    return null;
  }

  @override
  Future<String?> fetchStudentStatus(String userId) async {
    final response = await _client
        .from('student_profiles')
        .select('status')
        .eq('id', userId)
        .maybeSingle();

    if (response is Map<String, dynamic>) {
      return response['status'] as String?;
    }
    return null;
  }

  @override
  Future<bool> isStudentPhoneRegistered(String phone) async {
    final response = await _client
        .from('users')
        .select('id')
        .eq('phone', phone)
        .eq('role', 'student')
        .maybeSingle();

    return response != null;
  }

  @override
  Future<Session?> signInWithEmailAndPassword(String email, String password) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session;
  }

  /// Verified server-side against the signed-in admin's own record
  /// (`verify_my_admin_credentials`); requires a real Supabase session.
  @override
  Future<bool> verifyAdminCredentials(
    String accessCode,
    String password,
  ) async {
    return _verify('verify_my_admin_credentials', {
      'p_access_code': accessCode,
      'p_password': password,
    });
  }

  /// Verified against the signed-in teacher's own code
  /// (`verify_my_teacher_access_code`); requires a real Supabase session.
  @override
  Future<bool> verifyTeacherAccessCode(String accessCode) async {
    return _verify('verify_my_teacher_access_code', {
      'p_access_code': accessCode,
    });
  }

  Future<bool> _verify(String function, Map<String, dynamic> params) async {
    try {
      final response = await _client.rpc(function, params: params);
      return response == true;
    } on PostgrestException catch (e) {
      // Surface the lockout message instead of a generic "invalid code".
      if (e.message.contains('Too many failed attempts')) {
        throw Exception(e.message);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> ensureUserProfile(
    String userId,
    String phone,
    String role,
  ) async {
    final existing = await _client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing is Map<String, dynamic>) {
      return true;
    }

    // Only students may self-register. Teacher and admin accounts are created
    // by the admin (create_teacher_profile / seed), so an unknown phone here
    // is not an account and must not become one.
    if (role != 'student') {
      await _client.auth.signOut();
      throw Exception('This phone number is not registered as a $role.');
    }

    await _client.from('users').insert({
      'id': userId,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
