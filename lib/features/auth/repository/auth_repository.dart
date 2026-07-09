import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<void> sendOtp(String phone);
  Future<Session?> verifyOtp(String phone, String otp, String role);
  Future<void> signOut();
  Stream<Session?> authStateChanges();
  Session? get currentSession;
  User? get currentUser;
  Future<String?> fetchUserRole(String userId);
  Future<String?> fetchStudentStatus(String userId);
  Future<bool> verifyAdminCredentials(String accessCode, String password);
  Future<bool> verifyTeacherAccessCode(String accessCode);
  Future<bool> ensureUserProfile(String userId, String phone, String role);
}
