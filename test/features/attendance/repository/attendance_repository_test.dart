import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/attendance/repository/attendance_repository.dart';
import 'package:vidyavardhini_classes/shared/models/student_model.dart';

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

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> delete() {
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

  FakePostgrestFilterBuilder(this._returnValue, this._error);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> limit(int count,
      {String? referencedTable,}) {
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakePostgrestTransformBuilder(_returnValue, _error);
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestSingleTransformBuilder(_returnValue ?? {'id': 'att_123'}, _error);
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestListTransformBuilder(_returnValue ?? {'id': 'att_123'}, _error);
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
            (_returnValue).map((x) => Map<String, dynamic>.from(x as Map)),)
        : <Map<String, dynamic>>[];
    return Future.value(list)
        .then((val) => onValue(val), onError: onError);
  }
}

class FakePostgrestListTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestListTransformBuilder(this._returnValue, this._error);

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    return FakePostgrestSingleTransformBuilder(_returnValue, _error);
  }
}

class FakePostgrestSingleTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestSingleTransformBuilder(this._returnValue, this._error);

  @override
  Future<R> then<R>(
      FutureOr<R> Function(Map<String, dynamic> value) onValue,
      {Function? onError,}) {
    if (_error != null) {
      final fut = Future<Map<String, dynamic>>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    final res = (_returnValue is Map<String, dynamic>)
        ? _returnValue
        : {'id': 'att_123'};
    return Future.value(res).then((val) => onValue(val), onError: onError);
  }
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>?> {
  final dynamic _returnValue;
  final Exception? _error;

  FakePostgrestTransformBuilder(this._returnValue, this._error);

  @override
  Future<R> then<R>(
      FutureOr<R> Function(Map<String, dynamic>? value) onValue,
      {Function? onError,}) {
    if (_error != null) {
      final fut = Future<Map<String, dynamic>?>.error(_error);
      return fut.then((val) => onValue(val), onError: onError);
    }
    return Future.value(_returnValue)
        .then((val) => onValue(val as Map<String, dynamic>?), onError: onError);
  }
}

void main() {
  late AttendanceRepository repository;
  late MockSupabaseClient mockClient;

  const testStudent = StudentModel(
    id: 'student_1',
    fullName: 'Test Student',
    gender: 'Male',
    dob: '2010-01-01',
    parentName: 'Parent',
    parentPhone: '1234567890',
    whatsappNumber: '1234567890',
    schoolName: 'Test School',
    board: 'CBSE',
    standard: '10',
    status: 'active',
    createdAt: '2024-01-01T00:00:00.000Z',
  );

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = AttendanceRepository(client: mockClient);
  });

  group('AttendanceRepository - calculateDistance', () {
    test('calculates correct distance between same points', () {
      final distance =
          repository.calculateDistance(19.3831, 72.8286, 19.3831, 72.8286);
      expect(distance, 0.0);
    });

    test('calculates correct distance for known points', () {
      final distance =
          repository.calculateDistance(19.3831, 72.8286, 19.4583, 72.8064);
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
      when(() => mockClient.from('geofence_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({
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

    test('returns true and calls upsert when distance is less than or equal to radius',
        () async {
      when(() => mockClient.from('geofence_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({
          'id': '1',
          'latitude': 19.3831,
          'longitude': 72.8286,
          'radius_meters': 100,
        }),
      );

      when(() => mockClient.from('teacher_attendance')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]),
      );

      final result = await repository.checkAndMarkTeacherGeofence(
        teacherId: 'teacher1',
        userLat: 19.3831,
        userLng: 72.8286,
      );

      expect(result, isTrue);
    });

    test('propagates exception when Supabase upsert throws', () async {
      when(() => mockClient.from('geofence_settings')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({
          'id': '1',
          'latitude': 19.3831,
          'longitude': 72.8286,
          'radius_meters': 100,
        }),
      );

      when(() => mockClient.from('teacher_attendance')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
            null, const PostgrestException(message: 'Database error'),),
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

  group('AttendanceRepository - submitBatchAttendance', () {
    test('Happy Path (Present Student)', () async {
      when(() => mockClient.from('academic_years')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'ay_123'}),
      );
      when(() => mockClient.from('student_attendance')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'att_123'}),
      );
      when(() => mockClient.from('absence_reasons')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder([]),
      );

      final records = [
        {
          'student': testStudent,
          'status': 'present',
          'reason': null,
        }
      ];

      await repository.submitBatchAttendance(
        date: '2024-01-01',
        markedBy: 'teacher_1',
        records: records,
      );

      verify(() => mockClient.from('student_attendance')).called(1);
    });

    test('Happy Path (Absent Student with Reason)', () async {
      when(() => mockClient.from('academic_years')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'ay_123'}),
      );
      when(() => mockClient.from('student_attendance')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'att_123'}),
      );
      when(() => mockClient.from('absence_reasons')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder([]),
      );

      final records = [
        {
          'student': testStudent,
          'status': 'absent',
          'reason': 'Sick leave',
        }
      ];

      await repository.submitBatchAttendance(
        date: '2024-01-01',
        markedBy: 'teacher_1',
        records: records,
      );

      verify(() => mockClient.from('student_attendance')).called(1);
      verify(() => mockClient.from('absence_reasons')).called(2); // delete & insert
    });

    test('Empty Records List resolves without querying attendance', () async {
      when(() => mockClient.from('academic_years')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'ay_123'}),
      );

      await repository.submitBatchAttendance(
        date: '2024-01-01',
        markedBy: 'teacher_1',
        records: [],
      );

      verify(() => mockClient.from('academic_years')).called(1);
      verifyNever(() => mockClient.from('student_attendance'));
    });

    test('No Active Academic Year throws Exception', () async {
      when(() => mockClient.from('academic_years')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(null),
      );

      await expectLater(
        () async => await repository.submitBatchAttendance(
          date: '2024-01-01',
          markedBy: 'teacher_1',
          records: [
            {'student': testStudent, 'status': 'present'},
          ],
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('No active academic year found'),
          ),
        ),
      );

      verifyNever(() => mockClient.from('student_attendance'));
    });

    test('Supabase Network / Database Exception propagates', () async {
      when(() => mockClient.from('academic_years')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder({'id': 'ay_123'}),
      );
      when(() => mockClient.from('student_attendance')).thenAnswer(
        (_) => FakeSupabaseQueryBuilder(
            null, const PostgrestException(message: 'Database error'),),
      );

      await expectLater(
        () async => await repository.submitBatchAttendance(
          date: '2024-01-01',
          markedBy: 'teacher_1',
          records: [
            {'student': testStudent, 'status': 'present', 'reason': null},
          ],
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
