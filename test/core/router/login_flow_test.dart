import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/core/utils/login_identifier.dart';
import 'package:vidyavardhini_classes/features/auth/providers/auth_providers.dart';
import 'package:vidyavardhini_classes/features/auth/repository/auth_repository.dart';

class _FakeRepo implements AuthRepository {
  // ignore: close_sinks
  final controller = StreamController<Session?>.broadcast();
  User? user;
  String? role;

  @override
  Stream<Session?> authStateChanges() async* {
    yield null; // Supabase reports the initial (empty) session first
    yield* controller.stream;
  }

  @override
  User? get currentUser => user;
  @override
  Session? get currentSession => null;
  @override
  Future<String?> fetchUserRole(String userId) async {
    await Future<void>.value();
    return role;
  }

  @override
  Future<String?> fetchStudentStatus(String userId) async => null;
  @override
  Future<Session?> signInWithPassword(LoginIdentifier id, String p) async =>
      null;
  @override
  Future<void> sendEmailCode(String email) async {}
  @override
  Future<Session?> verifyEmailCode(String email, String code) async => null;
  @override
  Future<void> setPassword(String newPassword) async {}
  @override
  Future<void> signOut() async {}
  @override
  Future<bool> confirmCurrentPassword(String password) async => true;
}

User _user() => const User(
      id: 'u1',
      appMetadata: {},
      userMetadata: {},
      aud: 'authenticated',
      createdAt: '2026-01-01',
    );

void main() {
  test('after login the role and status settle (router can leave the splash)',
      () async {
    final repo = _FakeRepo();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    addTearDown(repo.controller.close);

    // Same listeners the router holds for its whole life.
    container
      ..listen(authStateProvider, (_, __) {})
      ..listen(currentUserRoleProvider, (_, __) {})
      ..listen(currentStudentStatusProvider, (_, __) {});
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(container.read(currentUserRoleProvider).valueOrNull, isNull);

    // Sign in as the admin. The screens must NOT invalidate the providers:
    // doing so while they refresh left them loading forever, so the router
    // stayed on the splash screen.
    repo
      ..user = _user()
      ..role = 'admin';
    repo.controller.add(
      Session(accessToken: 't', tokenType: 'bearer', user: repo.user!),
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));

    final role = container.read(currentUserRoleProvider);
    expect(role.isLoading, isFalse);
    expect(role.valueOrNull, 'admin');
    expect(container.read(currentStudentStatusProvider).isLoading, isFalse);
  });
}
