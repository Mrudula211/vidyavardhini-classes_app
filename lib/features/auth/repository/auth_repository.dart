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
  Future<bool> verifyTeacherAccessCode(String accessCode);

  /// True when [password] is the signed-in person's current password.
  Future<bool> confirmCurrentPassword(String password);
}
