import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/core/utils/login_identifier.dart';
import 'package:vidyavardhini_classes/features/auth/repository/supabase_auth_repository.dart';

// ---------------------------------------------------------
// Mocks & Fakes
// ---------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakeAuthResponse extends Fake implements AuthResponse {
  @override
  final Session? session;
  @override
  final User? user;

  FakeAuthResponse({
    this.session,
    this.user,
  });
}

class FakeSession extends Fake implements Session {
  @override
  final User user;

  FakeSession({
    required this.user,
  });
}

class FakeUser extends Fake implements User {
  @override
  final String id;

  FakeUser({
    required this.id,
  });
}

class FakeGoTrueClient extends Fake implements GoTrueClient {
  AuthResponse? Function()? verifyOtpCallback;
  Session? currentSessionMock;
  int verifyOtpCallCount = 0;
  String? lastSignInPhone;

  @override
  Future<AuthResponse> verifyOTP({
    String? email,
    String? phone,
    String? token,
    String? tokenHash,
    required OtpType type,
    String? captchaToken,
    String? redirectTo,
  }) async {
    verifyOtpCallCount++;
    lastVerifyType = type;
    if (verifyOtpCallback != null) {
      final res = verifyOtpCallback!();
      if (res != null) return res;
    }
    return FakeAuthResponse(session: currentSessionMock);
  }

  @override
  Session? get currentSession => currentSessionMock;

  // Password logins -----------------------------------------------------
  String? lastPasswordEmail;
  String? lastPasswordPhone;
  String? lastPassword;
  String? lastSignUpEmail;
  String? lastSignUpPhone;
  Session? signUpSession;
  Object? signInError;
  String? lastOtpEmail;
  bool? lastShouldCreateUser;
  OtpType? lastVerifyType;

  @override
  Future<AuthResponse> signInWithPassword({
    String? email,
    String? phone,
    required String password,
    String? captchaToken,
  }) async {
    if (signInError != null) throw signInError!;
    lastPasswordEmail = email;
    lastPasswordPhone = phone;
    lastPassword = password;
    return FakeAuthResponse(session: currentSessionMock);
  }

  @override
  Future<AuthResponse> signUp({
    String? email,
    String? phone,
    required String password,
    String? emailRedirectTo,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    lastSignUpEmail = email;
    lastSignUpPhone = phone;
    return FakeAuthResponse(session: signUpSession);
  }

  @override
  Future<void> signInWithOtp({
    String? email,
    String? phone,
    String? emailRedirectTo,
    bool? shouldCreateUser,
    Map<String, dynamic>? data,
    String? captchaToken,
    OtpChannel channel = OtpChannel.sms,
  }) async {
    lastSignInPhone = phone;
    lastOtpEmail = email;
    lastShouldCreateUser = shouldCreateUser;
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic _returnValue;
  final Exception? _error;

  FakeSupabaseQueryBuilder([
    this._returnValue,
    this._error,
  ]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return FakePostgrestFilterBuilder(_returnValue, _error);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> insert(
    Object values, {
    bool defaultToNull = true,
  }) {
    return FakePostgrestFilterBuilder(_returnValue, _error);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestFilterBuilder(
    this._returnValue,
    this._error,
  );

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(_returnValue, _error);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {
    Function? onError,
  }) {
    if (_error != null) {
      final fut = Future<List<Map<String, dynamic>>>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    final list = (_returnValue is List)
        ? List<Map<String, dynamic>>.from(
            (_returnValue).map((x) => Map<String, dynamic>.from(x as Map)),
          )
        : <Map<String, dynamic>>[];
    return Future.value(list).then((val) => onValue(val), onError: onError);
  }
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestTransformBuilder(
    this._returnValue,
    this._error,
  );

  @override
  Future<R> then<R>(
    FutureOr<R> Function(Map<String, dynamic>? value) onValue, {
    Function? onError,
  }) {
    if (_error != null) {
      final fut = Future<Map<String, dynamic>?>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    Map<String, dynamic>? val;
    if (_returnValue != null) {
      val = Map<String, dynamic>.from(_returnValue as Map);
    }
    return Future.value(val).then((val) => onValue(val), onError: onError);
  }
}

// ---------------------------------------------------------
// Tests
// ---------------------------------------------------------

void main() {
  late MockSupabaseClient mockClient;
  late FakeGoTrueClient fakeAuth;
  late SupabaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(OtpType.sms);
    registerFallbackValue(FakeAuthResponse());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    fakeAuth = FakeGoTrueClient();

    when(() => mockClient.auth).thenReturn(fakeAuth);

    repository = SupabaseAuthRepository(
      client: mockClient,
    );
  });

  group('password logins', () {
    final session = FakeSession(user: FakeUser(id: 'user-123'));

    test('signs in with an email', () async {
      fakeAuth.currentSessionMock = session;
      final result = await repository.signInWithPassword(
        const LoginIdentifier.email('a@b.com'),
        'secret1',
      );
      expect(result, session);
      expect(fakeAuth.lastPasswordEmail, 'a@b.com');
      expect(fakeAuth.lastPasswordPhone, isNull);
      expect(fakeAuth.lastPassword, 'secret1');
    });

    test('signs in with a mobile number', () async {
      fakeAuth.currentSessionMock = session;
      await repository.signInWithPassword(
        const LoginIdentifier.phone('+919876543210'),
        'secret1',
      );
      expect(fakeAuth.lastPasswordPhone, '+919876543210');
      expect(fakeAuth.lastPasswordEmail, isNull);
    });

    test('wrong credentials bubble up as AuthException', () async {
      fakeAuth.signInError = const AuthException('Invalid login credentials');
      expect(
        () => repository.signInWithPassword(
          const LoginIdentifier.email('a@b.com'),
          'nope',
        ),
        throwsA(isA<AuthException>()),
      );
    });

    test('sign-up returns the session when Supabase signs the person in',
        () async {
      fakeAuth.signUpSession = session;
      final result = await repository.signUpWithPassword(
        const LoginIdentifier.phone('+919876543210'),
        'secret1',
      );
      expect(result, session);
      expect(fakeAuth.lastSignUpPhone, '+919876543210');
      expect(fakeAuth.lastSignUpEmail, isNull);
    });

    test('sign-up returns null when confirmation is still required', () async {
      fakeAuth.signUpSession = null;
      final result = await repository.signUpWithPassword(
        const LoginIdentifier.email('a@b.com'),
        'secret1',
      );
      expect(result, isNull);
    });
  });

  group('email codes', () {
    final session = FakeSession(user: FakeUser(id: 'user-123'));

    test('sendEmailCode emails a code without creating accounts', () async {
      await repository.sendEmailCode('a@b.com');
      expect(fakeAuth.lastOtpEmail, 'a@b.com');
      // Accounts are created by the admin only.
      expect(fakeAuth.lastShouldCreateUser, isFalse);
    });

    test('verifyEmailCode uses the email type and returns the session',
        () async {
      fakeAuth.currentSessionMock = session;
      fakeAuth.verifyOtpCallback = () => FakeAuthResponse(session: session);
      final result = await repository.verifyEmailCode('a@b.com', '123456');
      expect(result, session);
      expect(fakeAuth.lastVerifyType, OtpType.email);
      expect(fakeAuth.verifyOtpCallCount, 1);
    });

    test('verifyEmailCode throws when no session comes back', () async {
      fakeAuth.currentSessionMock = null;
      fakeAuth.verifyOtpCallback = FakeAuthResponse.new;
      expect(
        () => repository.verifyEmailCode('a@b.com', '123456'),
        throwsException,
      );
    });
  });

  group('role lookup', () {
    test('fetchUserRole returns role on success', () async {
      when(() => mockClient.from('users')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'role': 'teacher'}, null),
      );
      expect(await repository.fetchUserRole('user-123'), 'teacher');
      verify(() => mockClient.from('users')).called(1);
    });

    test('fetchUserRole returns null when there is no row', () async {
      when(() => mockClient.from('users')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(null, null),
      );
      expect(await repository.fetchUserRole('user-123'), isNull);
    });
  });
}
