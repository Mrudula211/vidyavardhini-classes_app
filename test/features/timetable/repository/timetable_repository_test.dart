import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/timetable/repository/timetable_repository.dart';
import 'package:vidyavardhini_classes/shared/models/timetable_model.dart';

class FakeSupabaseClient extends Fake implements SupabaseClient {
  dynamic timetableSlotsBuilder;
  dynamic studentProfilesBuilder;

  @override
  SupabaseQueryBuilder from(String table) {
    if (table == 'timetable_slots' && timetableSlotsBuilder != null) {
      return timetableSlotsBuilder!;
    } else if (table == 'student_profiles' && studentProfilesBuilder != null) {
      return studentProfilesBuilder!;
    }
    throw UnimplementedError('Table $table not mocked');
  }
}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic filterBuilder;

  FakeSupabaseQueryBuilder([this.filterBuilder]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    return filterBuilder! as PostgrestFilterBuilder<List<Map<String, dynamic>>>;
  }
}

class FakeSupabaseQueryBuilderSingle extends Fake
    implements SupabaseQueryBuilder {
  final dynamic filterBuilder;

  FakeSupabaseQueryBuilderSingle([this.filterBuilder]);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([
    String columns = '*',
  ]) {
    // We need to return dynamic or fake it out if `select` is strictly typed.
    return filterBuilder as PostgrestFilterBuilder<List<Map<String, dynamic>>>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #select) {
      return filterBuilder!;
    }
    return super.noSuchMethod(invocation);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Object _result;
  final bool shouldThrow;

  // Track applied filters for verification
  final Map<String, dynamic> appliedFilters = {};

  FakePostgrestFilterBuilder(this._result, {this.shouldThrow = false});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    appliedFilters[column] = value;
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool ascending = false,
    bool nullsFirst = false,
    String? referencedTable,
  }) {
    return FakePostgrestTransformBuilder(_result, shouldThrow: shouldThrow);
  }
}

class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final Object _result;
  final bool shouldThrow;

  FakePostgrestTransformBuilder(this._result, {this.shouldThrow = false});

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then) {
      final onValue = invocation.positionalArguments[0] as FutureOr<dynamic>
          Function(List<Map<String, dynamic>>);

      if (shouldThrow) {
        return Future<List<Map<String, dynamic>>>.error(_result);
      }
      return Future.value(_result as List<Map<String, dynamic>>).then(onValue);
    }
    return super.noSuchMethod(invocation);
  }
}

void main() {
  group('TimetableRepository - fetchClassTimetable', () {
    late FakeSupabaseClient fakeClient;
    late TimetableRepository repository;

    final sampleData = [
      {
        'id': '1',
        'academic_year_id': 'ay1',
        'board': 'CBSE',
        'standard': '10th',
        'subject': 'Math',
        'teacher_id': 't1',
        'day_of_week': 'Monday',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'room_number': '101',
        'teacher_profiles': {'full_name': 'John Doe'},
      }
    ];

    setUp(() {
      fakeClient = FakeSupabaseClient();
      repository = TimetableRepository(client: fakeClient);
    });

    test('fetches timetable with day specific filter', () async {
      final filterBuilder = FakePostgrestFilterBuilder(sampleData);
      final queryBuilder = FakeSupabaseQueryBuilder(filterBuilder);
      fakeClient.timetableSlotsBuilder = queryBuilder;

      final result = await repository.fetchClassTimetable(
        board: 'CBSE',
        standard: '10th',
        dayOfWeek: 'Monday',
      );

      expect(result, isA<List<TimetableSlotModel>>());
      expect(result.length, 1);
      expect(result.first.subject, 'Math');
      expect(result.first.teacherName, 'John Doe');

      // Verify filters
      expect(filterBuilder.appliedFilters['board'], 'CBSE');
      expect(filterBuilder.appliedFilters['standard'], '10th');
      expect(filterBuilder.appliedFilters['day_of_week'], 'Monday');
    });

    test('fetches timetable without day filter (all days)', () async {
      final filterBuilder = FakePostgrestFilterBuilder(sampleData);
      final queryBuilder = FakeSupabaseQueryBuilder(filterBuilder);
      fakeClient.timetableSlotsBuilder = queryBuilder;

      final result = await repository.fetchClassTimetable(
        board: 'CBSE',
        standard: '10th',
        dayOfWeek: 'All', // Should not apply day_of_week eq filter
      );

      expect(result, isA<List<TimetableSlotModel>>());
      expect(result.length, 1);

      // Verify filters - day_of_week should NOT be present
      expect(filterBuilder.appliedFilters['board'], 'CBSE');
      expect(filterBuilder.appliedFilters['standard'], '10th');
      expect(filterBuilder.appliedFilters.containsKey('day_of_week'), isFalse);
    });

    test('fetches timetable with null day filter', () async {
      final filterBuilder = FakePostgrestFilterBuilder(sampleData);
      final queryBuilder = FakeSupabaseQueryBuilder(filterBuilder);
      fakeClient.timetableSlotsBuilder = queryBuilder;

      final result = await repository.fetchClassTimetable(
        board: 'CBSE',
        standard: '10th',
        dayOfWeek: null,
      );

      expect(result.length, 1);
      expect(filterBuilder.appliedFilters.containsKey('day_of_week'), isFalse);
    });

    test('fetches empty result', () async {
      final filterBuilder =
          FakePostgrestFilterBuilder(<Map<String, dynamic>>[]);
      final queryBuilder = FakeSupabaseQueryBuilder(filterBuilder);
      fakeClient.timetableSlotsBuilder = queryBuilder;

      final result = await repository.fetchClassTimetable(
        board: 'CBSE',
        standard: '10th',
        dayOfWeek: 'Tuesday',
      );

      expect(result, isA<List<TimetableSlotModel>>());
      expect(result, isEmpty);
    });
  });

  group('TimetableRepository - fetchStudentTimetable', () {
    late FakeSupabaseClient fakeClient;
    late TimetableRepository repository;

    final sampleData = [
      {
        'id': '1',
        'academic_year_id': 'ay1',
        'board': 'CBSE',
        'standard': '10th',
        'subject': 'Math',
        'teacher_id': 't1',
        'day_of_week': 'Monday',
        'start_time': '10:00:00',
        'end_time': '11:00:00',
        'room_number': '101',
        'teacher_profiles': {'full_name': 'John Doe'},
      }
    ];

    setUp(() {
      fakeClient = FakeSupabaseClient();
      repository = TimetableRepository(client: fakeClient);
    });

    test('fetches student timetable delegates to fetchClassTimetable',
        () async {
      // Mock student profile fetch - needs to be mapped to a map returning builder since it calls `.single()`
      final profileFilterBuilder = FakePostgrestFilterBuilderSingle({
        'board': 'CBSE',
        'standard': '10th',
      });
      final profileQueryBuilder =
          FakeSupabaseQueryBuilderSingle(profileFilterBuilder);
      fakeClient.studentProfilesBuilder = profileQueryBuilder;

      // Mock class timetable fetch
      final classFilterBuilder = FakePostgrestFilterBuilder(sampleData);
      final classQueryBuilder = FakeSupabaseQueryBuilder(classFilterBuilder);
      fakeClient.timetableSlotsBuilder = classQueryBuilder;

      final result = await repository.fetchStudentTimetable(
        studentId: 'student123',
        dayOfWeek: 'Monday',
      );

      // Verify student profile fetch filters
      expect(profileFilterBuilder.appliedFilters['id'], 'student123');

      // Verify class timetable fetch filters (delegated correctly)
      expect(classFilterBuilder.appliedFilters['board'], 'CBSE');
      expect(classFilterBuilder.appliedFilters['standard'], '10th');
      expect(classFilterBuilder.appliedFilters['day_of_week'], 'Monday');

      expect(result.length, 1);
      expect(result.first.subject, 'Math');
    });
  });
}

// Make this implement List so it can be returned from select(), but also have single() via noSuchMethod or dynamic cast
class FakePostgrestFilterBuilderSingle extends Fake
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic> _result;
  final Map<String, dynamic> appliedFilters = {};

  FakePostgrestFilterBuilderSingle(this._result);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(
    String column,
    Object value,
  ) {
    appliedFilters[column] = value;
    return this;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #single) {
      return FakePostgrestTransformBuilderSingle(_result);
    }
    return super.noSuchMethod(invocation);
  }
}

class FakePostgrestTransformBuilderSingle extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> _result;
  FakePostgrestTransformBuilderSingle(this._result);

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #then) {
      final onValue = invocation.positionalArguments[0] as FutureOr<dynamic>
          Function(Map<String, dynamic>);
      return Future.value(_result).then(onValue);
    }
    return super.noSuchMethod(invocation);
  }
}
