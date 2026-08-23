import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/attendance/repository/attendance_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic _returnValue;
  final Exception? _error;

  FakeSupabaseQueryBuilder([this._returnValue, this._error]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder(_returnValue, _error);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> upsert(
    Object values, {
    String? onConflict,
    bool ignoreDuplicates = false,
    bool defaultToNull = true,
  }) {
    return FakePostgrestFilterBuilder(_returnValue, _error);
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestFilterBuilder(this._returnValue, this._error);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> limit(int count, {String? referencedTable}) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(_returnValue, _error);
  }

  @override
  Future<R> then<R>(FutureOr<R> Function(List<Map<String, dynamic>> value) onValue, {Function? onError}) {
    if (_error != null) {
      final fut = Future<List<Map<String, dynamic>>>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    return Future.value(_returnValue).then((val) => onValue(val as List<Map<String, dynamic>>), onError: onError);
  }
}

class FakePostgrestTransformBuilder extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestTransformBuilder(this._returnValue, this._error);

  @override
  Future<R> then<R>(FutureOr<R> Function(Map<String, dynamic>? value) onValue, {Function? onError}) {
    if (_error != null) {
      final fut = Future<Map<String, dynamic>?>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    return Future.value(_returnValue).then((val) => onValue(val as Map<String, dynamic>?), onError: onError);
  }
}

void main() {
  late AttendanceRepository repository;
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = AttendanceRepository(client: mockClient);
  });

  group('AttendanceRepository - calculateDistance', () {
    test('calculates correct distance between same points', () {
      final distance = repository.calculateDistance(19.3831, 72.8286, 19.3831, 72.8286);
      expect(distance, 0.0);
    });

    test('calculates correct distance for known points', () {
      final distance = repository.calculateDistance(19.3831, 72.8286, 19.4583, 72.8064);
      expect(distance, greaterThan(8000));
      expect(distance, lessThan(9000));
    });
  });

  group('AttendanceRepository - checkAndMarkTeacherGeofence', () {
    test('returns false when geofence settings are null', () async {
      when(() => mockClient.from('geofence_settings'))
          .thenAnswer((_) => FakeSupabaseQueryBuilder(null));

      final result = await repository.checkAndMarkTeacherGeofence(
        teacherId: 'teacher1',
        userLat: 19.3831,
        userLng: 72.8286,
      );

      expect(result, isFalse);
    });

    test('returns false when distance is strictly greater than radius', () async {
      when(() => mockClient.from('geofence_settings')).thenAnswer((_) =>
        FakeSupabaseQueryBuilder({
          'id': '1',
          'latitude': 19.3831,
          'longitude': 72.8286,
          'radius_meters': 100,
          'updated_by': 'admin',
        }),
      );

      final result = await repository.checkAndMarkTeacherGeofence(
        teacherId: 'teacher1',
        userLat: 19.4583,
        userLng: 72.8064,
      );

      expect(result, isFalse);
    });

    test('returns true and calls upsert when distance is less than or equal to radius', () async {
      when(() => mockClient.from('geofence_settings')).thenAnswer((_) =>
        FakeSupabaseQueryBuilder({
          'id': '1',
          'latitude': 19.3831,
          'longitude': 72.8286,
          'radius_meters': 100,
        }),
      );

      // We only care about it not throwing, the fake will return []
      when(() => mockClient.from('teacher_attendance')).thenAnswer((_) =>
        FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]),
      );

      final result = await repository.checkAndMarkTeacherGeofence(
        teacherId: 'teacher1',
        userLat: 19.3831,
        userLng: 72.8286,
      );

      expect(result, isTrue);
    });

    test('propagates exception when Supabase upsert throws', () async {
      when(() => mockClient.from('geofence_settings')).thenAnswer((_) =>
        FakeSupabaseQueryBuilder({
          'id': '1',
          'latitude': 19.3831,
          'longitude': 72.8286,
          'radius_meters': 100,
        }),
      );

      when(() => mockClient.from('teacher_attendance')).thenAnswer((_) =>
        FakeSupabaseQueryBuilder(null, const PostgrestException(message: 'Database error')),
      );

      try {
        await repository.checkAndMarkTeacherGeofence(
          teacherId: 'teacher1',
          userLat: 19.3831,
          userLng: 72.8286,
        );
        fail('Exception not thrown');
      } catch (e) {
        expect(e, isA<PostgrestException>());
      }
    });
  });
}
