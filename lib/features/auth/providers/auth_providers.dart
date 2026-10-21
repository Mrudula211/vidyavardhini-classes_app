import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repository/auth_repository.dart';
import '../repository/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository();
});

final authStateProvider = StreamProvider<Session?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

/// The signed-in user's id. Re-evaluated on every auth event, but dependents
/// are only notified when the id itself changes (login, logout, switch) — not
/// on the hourly token refresh.
final currentUserIdProvider = Provider<String?>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).currentUser?.id;
});

final currentUserProvider = Provider<User?>((ref) {
  ref.watch(currentUserIdProvider);
  return ref.watch(authRepositoryProvider).currentUser;
});

final currentUserRoleProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).fetchUserRole(user.id);
});

final currentStudentStatusProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  return ref.watch(authRepositoryProvider).fetchStudentStatus(user.id);
});

final adminAuthenticatedProvider = StateProvider<bool>((ref) => false);
final teacherAuthenticatedProvider = StateProvider<bool>((ref) => false);
