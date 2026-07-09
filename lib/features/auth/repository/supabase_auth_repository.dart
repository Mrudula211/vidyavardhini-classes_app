import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {
    await Supabase.instance.client.auth.signInWithOtp(
      phone: phone,
    );
  }

  @override
  Future<Session?> verifyOtp(String phone, String otp, String role) async {
    await Supabase.instance.client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    final session = Supabase.instance.client.auth.currentSession;
    final user = session?.user;
    if (user == null) {
      throw Exception('OTP verification failed. User session missing.');
    }

    await ensureUserProfile(user.id, phone, role);
    return session;
  }

  @override
  Future<void> signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  @override
  Stream<Session?> authStateChanges() {
    return Supabase.instance.client.auth.onAuthStateChange
        .map((event) => event.session);
  }

  @override
  Session? get currentSession => Supabase.instance.client.auth.currentSession;

  @override
  User? get currentUser => Supabase.instance.client.auth.currentUser;

  @override
  Future<String?> fetchUserRole(String userId) async {
    final response = await Supabase.instance.client
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
    final response = await Supabase.instance.client
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
    final response = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('phone', phone)
        .eq('role', 'student')
        .maybeSingle();

    return response != null;
  }

  @override
  Future<bool> verifyAdminCredentials(
    String accessCode,
    String password,
  ) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'verify_admin_credentials',
        params: {
          'p_access_code': accessCode,
          'p_password': password,
        },
      );
      return response == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> verifyTeacherAccessCode(String accessCode) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'verify_teacher_access_code',
        params: {
          'p_access_code': accessCode,
        },
      );
      return response == true;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> ensureUserProfile(
    String userId,
    String phone,
    String role,
  ) async {
    final existing = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing is Map<String, dynamic>) {
      return true;
    }

    await Supabase.instance.client.from('users').insert({
      'id': userId,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    });

    return true;
  }
}
