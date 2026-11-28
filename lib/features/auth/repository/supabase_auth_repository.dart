import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/cache_service.dart';
import '../../../core/services/session_store.dart';
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
    final userId = _client.auth.currentUser?.id;
    await _client.auth.signOut();
    if (userId != null) await SessionStore.forget(userId);
    // Cached fees, attendance and announcements belong to the person who
    // just left; do not show them to the next user of this phone.
    try {
      await CacheService.instance.clear();
    } catch (_) {
      // Cache not initialised (tests) or already empty.
    }
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

  @override
  Future<bool> confirmCurrentPassword(String password) async {
    final user = _client.auth.currentUser;
    if (user == null) return false;
    try {
      final email = user.email;
      final phone = user.phone;
      if (email != null && email.isNotEmpty) {
        await _client.auth.signInWithPassword(email: email, password: password);
      } else if (phone != null && phone.isNotEmpty) {
        await _client.auth.signInWithPassword(
          phone: phone.startsWith('+') ? phone : '+$phone',
          password: password,
        );
      } else {
        return false;
      }
      return true;
    } on AuthException {
      return false;
    }
  }

}
