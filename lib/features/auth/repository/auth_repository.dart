import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/login_identifier.dart';

abstract class AuthRepository {
  /// Mobile number or email + password.
  Future<Session?> signInWithPassword(LoginIdentifier id, String password);

  /// Emails a one-time code (new accounts, forgotten passwords).
  Future<void> sendEmailCode(String email);
  Future<Session?> verifyEmailCode(String email, String code);

  /// Sets the password of the signed-in account.
  Future<void> setPassword(String newPassword);

  Future<void> signOut();
  Stream<Session?> authStateChanges();
  Session? get currentSession;
  User? get currentUser;
  Future<String?> fetchUserRole(String userId);
  Future<String?> fetchStudentStatus(String userId);
  Future<bool> verifyAdminCredentials(String accessCode, String password);
  Future<bool> verifyTeacherAccessCode(String accessCode);

  /// Admin only: sets a new 6-digit access code. Needs the current password
  /// AND the current access code. Returns false when either is wrong.
  Future<bool> changeAdminAccessCode({
    required String currentPassword,
    required String currentCode,
    required String newCode,
  });
}
