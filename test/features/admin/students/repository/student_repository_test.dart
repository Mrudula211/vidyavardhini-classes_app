import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/admin/students/repository/student_repository.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {
  T mockResult;
  Object? mockError;
  MockPostgrestFilterBuilder([T? result, this.mockError]) : mockResult = result ?? (T == typeOf<List<Map<String, dynamic>>>() ? <Map<String, dynamic>>[] as T : null as T);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    if (mockError != null) {
      if (onError != null) {
        return Future<R>.error(mockError!).catchError(onError);
      }
      return Future<R>.error(mockError!);
    }
    return Future.value(mockResult).then(onValue, onError: onError);
  }
}

class MockPostgrestTransformBuilder<T> extends Mock implements PostgrestTransformBuilder<T> {
  T mockResult;
  MockPostgrestTransformBuilder([T? result]) : mockResult = result ?? (T == typeOf<List<Map<String, dynamic>>>() ? <Map<String, dynamic>>[] as T : null as T);

  @override
  Future<R> then<R>(
    FutureOr<R> Function(T value) onValue, {
    Function? onError,
  }) {
    return Future.value(mockResult).then(onValue, onError: onError);
  }
}

Type typeOf<T>() => T;

void main() {
  group('StudentRepository approveStudent Tests', () {
    late StudentRepository repository;
    late MockSupabaseClient mockClient;

    late MockSupabaseQueryBuilder mockStudentProfilesTable;
    late MockSupabaseQueryBuilder mockAcademicYearsTable;
    late MockSupabaseQueryBuilder mockFeeStructureTable;
    late MockSupabaseQueryBuilder mockStudentEnrollmentsTable;

    setUp(() {
      mockClient = MockSupabaseClient();
      repository = StudentRepository(client: mockClient);

      mockStudentProfilesTable = MockSupabaseQueryBuilder();
      mockAcademicYearsTable = MockSupabaseQueryBuilder();
      mockFeeStructureTable = MockSupabaseQueryBuilder();
      mockStudentEnrollmentsTable = MockSupabaseQueryBuilder();

      when(() => mockClient.from('student_profiles')).thenAnswer((_) => mockStudentProfilesTable);
      when(() => mockClient.from('academic_years')).thenAnswer((_) => mockAcademicYearsTable);
      when(() => mockClient.from('fee_structure')).thenAnswer((_) => mockFeeStructureTable);
      when(() => mockClient.from('student_enrollments')).thenAnswer((_) => mockStudentEnrollmentsTable);
    });

    test('Happy Path: Successfully approves student and sets up fees and enrollments', () async {
      final mockProfilesUpdateBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockStudentProfilesTable.update(any())).thenAnswer((_) => mockProfilesUpdateBuilder);
      when(() => mockProfilesUpdateBuilder.eq(any(), any())).thenAnswer((_) => mockProfilesUpdateBuilder);

      final mockProfilesSelectBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesEqBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesMaybeSingleBuilder = MockPostgrestTransformBuilder<Map<String, dynamic>?>({
        'id': 'test_student_id',
        'student_id': 'STU001',
        'full_name': 'Test Student',
        'parent_name': 'Test Parent',
        'parent_phone': '1234567890',
        'whatsapp_number': '1234567890',
        'email': 'test@test.com',
        'school_name': 'Test School',
        'board': 'CBSE',
        'standard': '10th',
        'status': 'active',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
      when(() => mockStudentProfilesTable.select(any())).thenAnswer((_) => mockProfilesSelectBuilder);
      when(() => mockProfilesSelectBuilder.eq('id', 'test_student_id')).thenAnswer((_) => mockProfilesEqBuilder);
      when(() => mockProfilesEqBuilder.maybeSingle()).thenAnswer((_) => mockProfilesMaybeSingleBuilder);

      final mockAcademicYearsSelectBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockAcademicYearsEqBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockAcademicYearsMaybeSingleBuilder = MockPostgrestTransformBuilder<Map<String, dynamic>?>({
        'id': 'test_academic_year_id'
      });
      when(() => mockAcademicYearsTable.select('id')).thenAnswer((_) => mockAcademicYearsSelectBuilder);
      when(() => mockAcademicYearsSelectBuilder.eq('is_current', true)).thenAnswer((_) => mockAcademicYearsEqBuilder);
      when(() => mockAcademicYearsEqBuilder.maybeSingle()).thenAnswer((_) => mockAcademicYearsMaybeSingleBuilder);

      final mockFeeStructureUpsertBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockFeeStructureTable.upsert(any(), onConflict: 'student_id,academic_year_id'))
          .thenAnswer((_) => mockFeeStructureUpsertBuilder);

      final mockStudentEnrollmentsUpsertBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockStudentEnrollmentsTable.upsert(any(), onConflict: 'student_id,academic_year_id'))
          .thenAnswer((_) => mockStudentEnrollmentsUpsertBuilder);

      await repository.approveStudent(
        studentId: 'test_student_id',
        assignedStudentId: 'STU001',
        monthlyFee: 1000.0,
        adminId: 'admin_1',
      );

      verify(() => mockStudentProfilesTable.update(any())).called(1);
      verify(() => mockProfilesUpdateBuilder.eq('id', 'test_student_id')).called(1);

      verify(() => mockStudentProfilesTable.select()).called(1);
      verify(() => mockProfilesSelectBuilder.eq('id', 'test_student_id')).called(1);
      verify(() => mockProfilesEqBuilder.maybeSingle()).called(1);

      verify(() => mockAcademicYearsTable.select('id')).called(1);
      verify(() => mockAcademicYearsSelectBuilder.eq('is_current', true)).called(1);
      verify(() => mockAcademicYearsEqBuilder.maybeSingle()).called(1);

      verify(() => mockFeeStructureTable.upsert(any(), onConflict: 'student_id,academic_year_id')).called(1);
      verify(() => mockStudentEnrollmentsTable.upsert(any(), onConflict: 'student_id,academic_year_id')).called(1);
    });

    test('Active Academic Year Not Found: skips fee and enrollment upserts', () async {
      final mockProfilesUpdateBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockStudentProfilesTable.update(any())).thenAnswer((_) => mockProfilesUpdateBuilder);
      when(() => mockProfilesUpdateBuilder.eq(any(), any())).thenAnswer((_) => mockProfilesUpdateBuilder);

      final mockProfilesSelectBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesEqBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesMaybeSingleBuilder = MockPostgrestTransformBuilder<Map<String, dynamic>?>({
        'id': 'test_student_id',
        'student_id': 'STU001',
        'full_name': 'Test Student',
        'board': 'CBSE',
        'standard': '10th',
      });
      when(() => mockStudentProfilesTable.select(any())).thenAnswer((_) => mockProfilesSelectBuilder);
      when(() => mockProfilesSelectBuilder.eq('id', 'test_student_id')).thenAnswer((_) => mockProfilesEqBuilder);
      when(() => mockProfilesEqBuilder.maybeSingle()).thenAnswer((_) => mockProfilesMaybeSingleBuilder);

      // Return null for academic year
      final mockAcademicYearsSelectBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockAcademicYearsEqBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockAcademicYearsMaybeSingleBuilder = MockPostgrestTransformBuilder<Map<String, dynamic>?>(null);
      when(() => mockAcademicYearsTable.select('id')).thenAnswer((_) => mockAcademicYearsSelectBuilder);
      when(() => mockAcademicYearsSelectBuilder.eq('is_current', true)).thenAnswer((_) => mockAcademicYearsEqBuilder);
      when(() => mockAcademicYearsEqBuilder.maybeSingle()).thenAnswer((_) => mockAcademicYearsMaybeSingleBuilder);

      await repository.approveStudent(
        studentId: 'test_student_id',
        assignedStudentId: 'STU001',
        monthlyFee: 1000.0,
        adminId: 'admin_1',
      );

      verify(() => mockStudentProfilesTable.update(any())).called(1);
      verify(() => mockAcademicYearsTable.select('id')).called(1);
      verifyNever(() => mockFeeStructureTable.upsert(any(), onConflict: any(named: 'onConflict')));
      verifyNever(() => mockStudentEnrollmentsTable.upsert(any(), onConflict: any(named: 'onConflict')));
    });

    test('Student Not Found after Update: early return', () async {
      final mockProfilesUpdateBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      when(() => mockStudentProfilesTable.update(any())).thenAnswer((_) => mockProfilesUpdateBuilder);
      when(() => mockProfilesUpdateBuilder.eq(any(), any())).thenAnswer((_) => mockProfilesUpdateBuilder);

      final mockProfilesSelectBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesEqBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>();
      final mockProfilesMaybeSingleBuilder = MockPostgrestTransformBuilder<Map<String, dynamic>?>(null);
      when(() => mockStudentProfilesTable.select(any())).thenAnswer((_) => mockProfilesSelectBuilder);
      when(() => mockProfilesSelectBuilder.eq('id', 'test_student_id')).thenAnswer((_) => mockProfilesEqBuilder);
      when(() => mockProfilesEqBuilder.maybeSingle()).thenAnswer((_) => mockProfilesMaybeSingleBuilder);

      await repository.approveStudent(
        studentId: 'test_student_id',
        assignedStudentId: 'STU001',
        monthlyFee: 1000.0,
        adminId: 'admin_1',
      );

      verify(() => mockStudentProfilesTable.update(any())).called(1);
      verify(() => mockStudentProfilesTable.select()).called(1);
      verifyNever(() => mockAcademicYearsTable.select('id'));
      verifyNever(() => mockFeeStructureTable.upsert(any(), onConflict: any(named: 'onConflict')));
      verifyNever(() => mockStudentEnrollmentsTable.upsert(any(), onConflict: any(named: 'onConflict')));
    });

    test('Supabase Exception Handling: fails gracefully when update throws', () async {
      final exception = PostgrestException(message: 'Database error');
      final mockProfilesUpdateBuilder = MockPostgrestFilterBuilder<List<Map<String, dynamic>>>(null, exception);

      when(() => mockStudentProfilesTable.update(any())).thenAnswer((_) => mockProfilesUpdateBuilder);
      when(() => mockProfilesUpdateBuilder.eq(any(), any())).thenAnswer((_) => mockProfilesUpdateBuilder);

      expect(
        () => repository.approveStudent(
          studentId: 'test_student_id',
          assignedStudentId: 'STU001',
          monthlyFee: 1000.0,
          adminId: 'admin_1',
        ),
        throwsA(isA<PostgrestException>()),
      );

      verify(() => mockStudentProfilesTable.update(any())).called(1);
      verifyNever(() => mockStudentProfilesTable.select());
    });
  });
}
