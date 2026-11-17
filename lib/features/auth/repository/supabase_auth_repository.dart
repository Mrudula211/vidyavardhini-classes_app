import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/login_identifier.dart';
import 'auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final SupabaseClient _client;

  SupabaseAuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  @override
  Future<Session?> signInWithPassword(
    LoginIdentifier id,
    String password,
  ) async {
    final response = id.isEmail
        ? await _client.auth.signInWithPassword(
            email: id.email,
            password: password,
          )
        : await _client.auth.signInWithPassword(
            phone: id.phone,
            password: password,
          );
    return response.session;
  }

  @override
  Future<Session?> signUpWithPassword(
    LoginIdentifier id,
    String password,
  ) async {
    final response = id.isEmail
        ? await _client.auth.signUp(email: id.email, password: password)
        : await _client.auth.signUp(phone: id.phone, password: password);
    return response.session;
  }

  @override
  Future<void> sendEmailCode(String email) async {
    // Accounts are created by the admin only; never create one here.
    await _client.auth.signInWithOtp(email: email, shouldCreateUser: false);
  }

  @override
  Future<Session?> verifyEmailCode(String email, String code) async {
    final response = await _client.auth.verifyOTP(
      email: email,
      token: code,
      type: OtpType.email,
    );
    final session = response.session ?? _client.auth.currentSession;
    if (session == null) {
      throw Exception('Code verification failed. Please try again.');
    }
    return session;
  }

  @override
  Future<void> setPassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Stream<Session?> authStateChanges() {
    return _client.auth.onAuthStateChange.map((event) => event.session);
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

  @override
  Future<void> changeAdminAccessCode({
    required String currentPassword,
    required String newCode,
  }) async {
    await _client.rpc(
      'change_my_admin_access_code',
      params: {
        'p_current_password': currentPassword,
        'p_new_code': newCode,
      },
    );
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
}
