import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/session_store.dart';
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
  try {
    final role = await ref.watch(authRepositoryProvider).fetchUserRole(user.id);
    if (role != null) await SessionStore.cacheRole(user.id, role);
    return role;
  } catch (_) {
    // Offline or a server hiccup: a logged-in person must not be treated as
    // logged out. Use the role remembered from the last successful lookup.
    final cached = SessionStore.cachedRole(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

final currentStudentStatusProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  try {
    final status =
        await ref.watch(authRepositoryProvider).fetchStudentStatus(user.id);
    if (status != null) await SessionStore.cacheStatus(user.id, status);
    return status;
  } catch (_) {
    final cached = SessionStore.cachedStatus(user.id);
    if (cached != null) return cached;
    rethrow;
  }
});

/// True while someone who forgot their password is signing in with an emailed
/// code and choosing a new password. Lets the router keep them on the OTP and
/// new-password screens instead of sending them to a dashboard first.
final passwordRecoveryProvider = StateProvider<bool>((ref) => false);

