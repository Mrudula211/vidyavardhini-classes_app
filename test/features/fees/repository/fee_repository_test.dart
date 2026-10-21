import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/fees/repository/fee_repository.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class FakeFilterBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakeFilterBuilder(this._returnValue, {Exception? error}) : _error = error;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>?> maybeSingle() {
    return FakeTransformBuilder<Map<String, dynamic>?>(
      _returnValue,
      error: _error,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    if (_error != null) {
      return Future<U>.error(_error).catchError(onError ?? (e) => throw e);
    }
    return Future<List<Map<String, dynamic>>>.value(
      _returnValue as List<Map<String, dynamic>>,
    ).then(onValue).catchError(onError ?? (e) => throw e);
  }
}

class FakeTransformBuilder<T> implements PostgrestTransformBuilder<T> {
  final T? _returnValue;
  final Exception? _error;

  FakeTransformBuilder(this._returnValue, {Exception? error}) : _error = error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<U> then<U>(FutureOr<U> Function(T) onValue, {Function? onError}) {
    if (_error != null) {
      return Future<U>.error(_error).catchError(onError ?? (e) => throw e);
    }
    return Future<T>.value(_returnValue as T)
        .then(onValue)
        .catchError(onError ?? (e) => throw e);
  }
}

class FakeInsertBuilder
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic _returnValue;
  final Exception? _error;

  FakeInsertBuilder(this._returnValue, {Exception? error}) : _error = error;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    if (_error != null) {
      return Future<U>.error(_error).catchError(onError ?? (e) => throw e);
    }
    return Future<List<Map<String, dynamic>>>.value(
      _returnValue as List<Map<String, dynamic>>,
    ).then(onValue).catchError(onError ?? (e) => throw e);
  }
}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  late FeeRepository repository;
  late MockSupabaseClient mockClient;

  late MockSupabaseQueryBuilder mockAcademicYearsQuery;
  late MockSupabaseQueryBuilder mockFeeStructureQuery;
  late MockSupabaseQueryBuilder mockMonthlyFeesQuery;

  setUpAll(() {
    registerFallbackValue(const <String, dynamic>{});
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    repository = FeeRepository(client: mockClient);

    mockAcademicYearsQuery = MockSupabaseQueryBuilder();
    mockFeeStructureQuery = MockSupabaseQueryBuilder();
    mockMonthlyFeesQuery = MockSupabaseQueryBuilder();

    when(() => mockClient.from('academic_years'))
        .thenAnswer((_) => mockAcademicYearsQuery);
    when(() => mockClient.from('fee_structure'))
        .thenAnswer((_) => mockFeeStructureQuery);
    when(() => mockClient.from('monthly_fees'))
        .thenAnswer((_) => mockMonthlyFeesQuery);
  });

  group('generateMonthlyFees', () {
    test('returns 0 when no current academic year exists', () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder(null));

      final result = await repository.generateMonthlyFees(month: 1, year: 2024);

      expect(result, 0);
      verify(() => mockAcademicYearsQuery.select('id')).called(1);
      verifyNever(() => mockClient.from('fee_structure'));
    });

    test('returns 0 when no active fee structures are found', () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder({'id': 'year_1'}));
      when(
        () => mockFeeStructureQuery.select(
          'student_id, monthly_fee, student_profiles!inner(status)',
        ),
      ).thenAnswer((_) => FakeFilterBuilder(<Map<String, dynamic>>[]));

      final result = await repository.generateMonthlyFees(month: 1, year: 2024);

      expect(result, 0);
      verify(() => mockFeeStructureQuery.select(any())).called(1);
      verifyNever(() => mockClient.from('monthly_fees'));
    });

    test('Happy Path: generates fees for students without existing fees',
        () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder({'id': 'year_1'}));
      when(
        () => mockFeeStructureQuery.select(
          'student_id, monthly_fee, student_profiles!inner(status)',
        ),
      ).thenAnswer(
        (_) => FakeFilterBuilder(<Map<String, dynamic>>[
          {'student_id': 'student_1', 'monthly_fee': 1000.0},
          {'student_id': 'student_2', 'monthly_fee': 1500.0},
        ]),
      );

      when(() => mockMonthlyFeesQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder(null));
      when(() => mockMonthlyFeesQuery.insert(any()))
          .thenAnswer((_) => FakeInsertBuilder(<Map<String, dynamic>>[]));

      final result = await repository.generateMonthlyFees(month: 1, year: 2024);

      expect(result, 2);
      verify(() => mockMonthlyFeesQuery.insert(any())).called(2);
    });

    test('Partial / Deduplication: skips students with existing fee records',
        () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder({'id': 'year_1'}));
      when(
        () => mockFeeStructureQuery.select(
          'student_id, monthly_fee, student_profiles!inner(status)',
        ),
      ).thenAnswer(
        (_) => FakeFilterBuilder(<Map<String, dynamic>>[
          {'student_id': 'student_1', 'monthly_fee': 1000.0},
          {'student_id': 'student_2', 'monthly_fee': 1500.0},
        ]),
      );

      int selectCallCount = 0;
      when(() => mockMonthlyFeesQuery.select('id')).thenAnswer((_) {
        selectCallCount++;
        if (selectCallCount == 1) {
          return FakeFilterBuilder({'id': 'existing_1'});
        }
        return FakeFilterBuilder(null);
      });

      when(() => mockMonthlyFeesQuery.insert(any()))
          .thenAnswer((_) => FakeInsertBuilder(<Map<String, dynamic>>[]));

      final result = await repository.generateMonthlyFees(month: 1, year: 2024);

      expect(result, 1);
      verify(() => mockMonthlyFeesQuery.insert(any())).called(1);
    });

    test(
        'Zero / Null Monthly Fee Value: handles missing or zero fees correctly',
        () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder({'id': 'year_1'}));
      when(
        () => mockFeeStructureQuery.select(
          'student_id, monthly_fee, student_profiles!inner(status)',
        ),
      ).thenAnswer(
        (_) => FakeFilterBuilder(<Map<String, dynamic>>[
          {'student_id': 'student_1', 'monthly_fee': 0.0},
          {'student_id': 'student_2'}, // null fee
        ]),
      );

      when(() => mockMonthlyFeesQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder(null));
      when(() => mockMonthlyFeesQuery.insert(any()))
          .thenAnswer((_) => FakeInsertBuilder(<Map<String, dynamic>>[]));

      final result = await repository.generateMonthlyFees(month: 1, year: 2024);

      expect(result, 2);

      final capturedInserts =
          verify(() => mockMonthlyFeesQuery.insert(captureAny())).captured;
      expect(capturedInserts.length, 2);
      expect(
        (capturedInserts[0] as Map<String, dynamic>)['expected_amount'],
        0.0,
      );
      expect(
        (capturedInserts[1] as Map<String, dynamic>)['expected_amount'],
        0.0,
      );
    });

    test(
        'Database Exception Handling: propagates database exceptions during queries',
        () async {
      when(() => mockAcademicYearsQuery.select('id')).thenAnswer(
        (_) => FakeFilterBuilder(
          null,
          error: const PostgrestException(message: 'Database error'),
        ),
      );

      expect(
        () => repository.generateMonthlyFees(month: 1, year: 2024),
        throwsA(isA<PostgrestException>()),
      );
    });

    test(
        'Database Exception Handling: propagates database exceptions during inserts',
        () async {
      when(() => mockAcademicYearsQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder({'id': 'year_1'}));
      when(
        () => mockFeeStructureQuery.select(
          'student_id, monthly_fee, student_profiles!inner(status)',
        ),
      ).thenAnswer(
        (_) => FakeFilterBuilder(<Map<String, dynamic>>[
          {'student_id': 'student_1', 'monthly_fee': 1000.0},
        ]),
      );

      when(() => mockMonthlyFeesQuery.select('id'))
          .thenAnswer((_) => FakeFilterBuilder(null));
      when(() => mockMonthlyFeesQuery.insert(any())).thenAnswer(
        (_) => FakeInsertBuilder(
          null,
          error: const PostgrestException(message: 'Insert error'),
        ),
      );

      expect(
        () => repository.generateMonthlyFees(month: 1, year: 2024),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
