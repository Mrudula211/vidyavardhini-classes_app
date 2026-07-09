import 'package:bcrypt/bcrypt.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  @override
  Future<void> sendOtp(String phone) async {
    final response = await Supabase.instance.client.auth.signInWithOtp(
      phone: phone,
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }
  }

  @override
  Future<Session?> verifyOtp(String phone, String otp, String role) async {
    final response = await Supabase.instance.client.auth.verifyOTP(
      phone: phone,
      token: otp,
      type: OtpType.sms,
    );

    if (response.error != null) {
      throw Exception(response.error!.message);
    }

    final session = response.session;
    final user = session?.user;
    if (user == null) {
      throw Exception('OTP verification failed. User session missing.');
    }

    await ensureUserProfile(user.id, phone, role);
    return session;
  }

  @override
  Future<void> signOut() async {
    final response = await Supabase.instance.client.auth.signOut();
    if (response.error != null) {
      throw Exception(response.error!.message);
    }
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
      String accessCode, String password) async {
    final response = await Supabase.instance.client
        .from('admin_profiles')
        .select('access_code_hash, password_hash')
        .maybeSingle();

    if (response is! Map<String, dynamic>) {
      return false;
    }

    final storedAccessCodeHash = response['access_code_hash'] as String?;
    final storedPasswordHash = response['password_hash'] as String?;

    if (storedAccessCodeHash == null || storedPasswordHash == null) {
      return false;
    }

    final accessCodeValid = BCrypt.checkpw(accessCode, storedAccessCodeHash);
    final passwordValid = BCrypt.checkpw(password, storedPasswordHash);
    return accessCodeValid && passwordValid;
  }

  @override
  Future<bool> verifyTeacherAccessCode(String accessCode) async {
    final response = await Supabase.instance.client
        .from('teacher_profiles')
        .select('id, access_code_hash');

    if (response is! List) {
      return false;
    }

    for (final item in response) {
      if (item is Map<String, dynamic>) {
        final hash = item['access_code_hash'] as String?;
        if (hash != null && BCrypt.checkpw(accessCode, hash)) {
          return true;
        }
      }
    }

    return false;
  }

  @override
  Future<bool> ensureUserProfile(
      String userId, String phone, String role) async {
    final existing = await Supabase.instance.client
        .from('users')
        .select('id')
        .eq('id', userId)
        .maybeSingle();

    if (existing != null) {
      return true;
    }

    final insertResponse = await Supabase.instance.client.from('users').insert({
      'id': userId,
      'phone': phone,
      'role': role,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).execute();

    if (insertResponse.error != null) {
      throw Exception(insertResponse.error!.message);
    }
    return true;
  }
}
