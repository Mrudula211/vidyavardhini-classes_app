import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
    if (verifyOtpCallback != null) {
      final res = verifyOtpCallback!();
      if (res != null) return res;
    }
    return FakeAuthResponse(session: currentSessionMock);
  }

  @override
  Session? get currentSession => currentSessionMock;

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
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select(
      [String columns = '*',]) {
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
          String column, Object value,) =>
      this;

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(_returnValue, _error);
  }

  @override
  Future<R> then<R>(
      FutureOr<R> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError,}) {
    if (_error != null) {
      final fut = Future<List<Map<String, dynamic>>>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    final list = (_returnValue is List)
        ? List<Map<String, dynamic>>.from(
            (_returnValue)
                .map((x) => Map<String, dynamic>.from(x as Map)),
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
  Future<R> then<R>(FutureOr<R> Function(Map<String, dynamic>? value) onValue,
      {Function? onError,}) {
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

  group('verifyOtp & ensureUserProfile', () {
    const phone = '+1234567890';
    const otp = '123456';
    const role = 'student';
    final fakeUser = FakeUser(id: 'user-123');
    final fakeSession = FakeSession(user: fakeUser);

    test('Happy Path (Existing User): returns session without inserting',
        () async {
      fakeAuth.currentSessionMock = fakeSession;
      fakeAuth.verifyOtpCallback =
          () => FakeAuthResponse(session: fakeSession, user: fakeUser);

      when(() => mockClient.from(
            'users',
          ),).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          {
            'id': fakeUser.id,
          },
          null,
        ),
      );

      final session = await repository.verifyOtp(phone, otp, role);

      expect(session, isNotNull);
      expect(session?.user.id, 'user-123');

      expect(fakeAuth.verifyOtpCallCount, 1);
      verify(() => mockClient.from(
            'users',
          ),).called(1);
    });

    test('Happy Path (New User): returns session after inserting', () async {
      fakeAuth.currentSessionMock = fakeSession;
      fakeAuth.verifyOtpCallback =
          () => FakeAuthResponse(session: fakeSession, user: fakeUser);

      var calls = 0;
      when(() => mockClient.from(
            'users',
          ),).thenAnswer((_) {
        calls++;
        if (calls == 1) {
          return FakeSupabaseQueryBuilder(null, null);
        } else {
          return FakeSupabaseQueryBuilder([], null);
        }
      });

      final session = await repository.verifyOtp(phone, otp, role);

      expect(session, isNotNull);
      expect(session?.user.id, 'user-123');

      expect(fakeAuth.verifyOtpCallCount, 1);
      verify(() => mockClient.from(
            'users',
          ),).called(2);
    });

    test('Error Path: Null Session/User Error throws Exception', () async {
      fakeAuth.currentSessionMock = null;
      fakeAuth.verifyOtpCallback =
          () => FakeAuthResponse(session: null, user: null);

      await expectLater(
        () => repository.verifyOtp(phone, otp, role),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'User session missing',
            ),
          ),
        ),
      );

      expect(fakeAuth.verifyOtpCallCount, 1);
      verifyNever(() => mockClient.from('users'));
    });

    test('Error Path: AuthException Propagation bubbles up', () async {
      fakeAuth.verifyOtpCallback = () {
        throw const AuthException('Invalid OTP');
      };

      await expectLater(
        () => repository.verifyOtp(phone, otp, role),
        throwsA(isA<AuthException>()),
      );

      expect(fakeAuth.verifyOtpCallCount, 1);
      verifyNever(() => mockClient.from('users'));
    });

    test('Error Path: Profile Insert Error bubbles up', () async {
      fakeAuth.currentSessionMock = fakeSession;
      fakeAuth.verifyOtpCallback =
          () => FakeAuthResponse(session: fakeSession, user: fakeUser);

      var calls = 0;
      when(() => mockClient.from(
            'users',
          ),).thenAnswer((_) {
        calls++;
        if (calls == 1) {
          return FakeSupabaseQueryBuilder(null, null);
        } else {
          return FakeSupabaseQueryBuilder(
            null,
            const PostgrestException(
              message: 'DB error',
            ),
          );
        }
      });

      await expectLater(
        () => repository.verifyOtp(phone, otp, role),
        throwsA(isA<PostgrestException>()),
      );

      expect(fakeAuth.verifyOtpCallCount, 1);
      verify(() => mockClient.from(
            'users',
          ),).called(2);
    });
  });

  group('Helper Methods', () {
    test('sendOtp calls signInWithOtp with correct phone', () async {
      await repository.sendOtp('+1234567890');
      expect(fakeAuth.lastSignInPhone, '+1234567890');
    });

    test('fetchUserRole returns role on success', () async {
      when(() => mockClient.from(
            'users',
          ),).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          {
            'role': 'teacher',
          },
          null,
        ),
      );

      final role = await repository.fetchUserRole('user-123');

      expect(role, 'teacher');
      verify(() => mockClient.from(
            'users',
          ),).called(1);
    });

    test('isStudentPhoneRegistered returns true if user exists', () async {
      when(() => mockClient.from(
            'users',
          ),).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
          {
            'id': 'user-123',
          },
          null,
        ),
      );

      final isRegistered =
          await repository.isStudentPhoneRegistered('+1234567890');

      expect(isRegistered, true);
      verify(() => mockClient.from(
            'users',
          ),).called(1);
    });

    test('isStudentPhoneRegistered returns false if user does not exist',
        () async {
      when(() => mockClient.from(
            'users',
          ),).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(null, null),
      );

      final isRegistered =
          await repository.isStudentPhoneRegistered('+1234567890');

      expect(isRegistered, false);
      verify(() => mockClient.from(
            'users',
          ),).called(1);
    });
  });
}
