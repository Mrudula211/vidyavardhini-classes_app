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

final currentUserProvider = Provider<User?>((ref) {
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
