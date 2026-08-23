import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/attendance/repository/attendance_repository.dart';
import 'package:vidyavardhini_classes/shared/models/student_model.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class TestableAttendanceRepository extends AttendanceRepository {
  final Map<String, dynamic>? mockAcademicYear;
  final bool throwOnUpsert;

  int upsertCount = 0;
  int deleteReasonsCount = 0;
  int insertReasonsCount = 0;
  List<Map<String, dynamic>> upsertedData = [];
  List<String> deletedReasonAttendanceIds = [];
  List<Map<String, String>> insertedReasons = [];

  TestableAttendanceRepository({
    super.client,
    this.mockAcademicYear = const {'id': 'test_year_id'},
    this.throwOnUpsert = false,
  });

  @override
  Future<Map<String, dynamic>?> getCurrentAcademicYearForTest() async {
    return mockAcademicYear;
  }

  @override
  Future<void> upsertStudentAttendanceForTest(Map<String, dynamic> data) async {
    if (throwOnUpsert) {
      throw const PostgrestException(message: 'Network Error');
    }
    upsertCount++;
    upsertedData.add(Map.from(data));
    data['_attendanceId'] = 'attendance_$upsertCount';
  }

  @override
  Future<void> deleteAbsenceReasonsForTest(String attendanceId) async {
    deleteReasonsCount++;
    deletedReasonAttendanceIds.add(attendanceId);
  }

  @override
  Future<void> insertAbsenceReasonForTest(
      String attendanceId, String reason) async {
    insertReasonsCount++;
    insertedReasons.add({'attendance_id': attendanceId, 'reason': reason});
  }
}

void main() {
  late MockSupabaseClient mockClient;

  setUp(() {
    mockClient = MockSupabaseClient();
  });

  group('submitBatchAttendance', () {
    final testStudent = StudentModel(
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
      createdAt: DateTime.now().toIso8601String(),
    );

    test('Happy Path (Present Student)', () async {
      final repository = TestableAttendanceRepository(client: mockClient);

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

      expect(repository.upsertCount, 1);
      expect(repository.upsertedData.first['status'], 'present');
      expect(repository.deleteReasonsCount, 1);
      expect(repository.deletedReasonAttendanceIds.first, 'attendance_1');
      expect(repository.insertReasonsCount, 0);
    });

    test('Happy Path (Absent Student with Reason)', () async {
      final repository = TestableAttendanceRepository(client: mockClient);

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

      expect(repository.upsertCount, 1);
      expect(repository.upsertedData.first['status'], 'absent');
      expect(repository.deleteReasonsCount, 1);
      expect(repository.insertReasonsCount, 1);
      expect(repository.insertedReasons.first['reason'], 'Sick leave');
    });

    test('Status Transition (Absent -> Present)', () async {
      final repository = TestableAttendanceRepository(client: mockClient);

      final records = [
        {
          'student': testStudent,
          'status': 'present',
          'reason': 'was sick yesterday',
        }
      ];

      await repository.submitBatchAttendance(
        date: '2024-01-01',
        markedBy: 'teacher_1',
        records: records,
      );

      expect(repository.upsertCount, 1);
      expect(repository.upsertedData.first['status'], 'present');
      expect(repository.deleteReasonsCount, 1);
      expect(repository.insertReasonsCount, 0);
    });

    test('Empty Records List', () async {
      final repository = TestableAttendanceRepository(client: mockClient);

      await repository.submitBatchAttendance(
        date: '2024-01-01',
        markedBy: 'teacher_1',
        records: [],
      );

      expect(repository.upsertCount, 0);
      expect(repository.deleteReasonsCount, 0);
    });

    test('No Active Academic Year Error', () async {
      final repository = TestableAttendanceRepository(
        client: mockClient,
        mockAcademicYear: null,
      );

      await expectLater(
        () async => await repository.submitBatchAttendance(
          date: '2024-01-01',
          markedBy: 'teacher_1',
          records: [
            {'student': testStudent, 'status': 'present'}
          ],
        ),
        throwsA(isA<Exception>().having((e) => e.toString(), 'message',
            contains('No active academic year found'))),
      );

      expect(repository.upsertCount, 0);
    });

    test('Supabase Network / Database Exception', () async {
      final repository = TestableAttendanceRepository(
        client: mockClient,
        throwOnUpsert: true,
      );

      await expectLater(
        () async => await repository.submitBatchAttendance(
          date: '2024-01-01',
          markedBy: 'teacher_1',
          records: [
            {'student': testStudent, 'status': 'present', 'reason': null}
          ],
        ),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}
