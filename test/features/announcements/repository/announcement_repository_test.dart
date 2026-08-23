import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vidyavardhini_classes/features/announcements/repository/announcement_repository.dart';

// Provides a Fake SupabaseClient that overrides only the 'from' method
class FakeSupabaseClient extends Fake implements SupabaseClient {
  final List<Map<String, dynamic>> announcements;
  final Map<String, dynamic> studentProfile;
  final List<String> queries; // to track queried tables

  FakeSupabaseClient({
    this.announcements = const [],
    this.studentProfile = const {},
    List<String>? queries,
  }) : queries = queries ?? [];

  @override
  SupabaseQueryBuilder from(String table) {
    queries.add(table);
    if (table == 'announcements') {
      return FakeQueryBuilder(data: announcements, table: table, queries: queries);
    } else if (table == 'student_profiles') {
      return FakeStudentProfileQuery(data: studentProfile, table: table, queries: queries);
    }
    throw UnimplementedError('Table $table not mocked');
  }
}

class FakeQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final List<Map<String, dynamic>> data;
  final String table;
  final List<String> queries;

  FakeQueryBuilder({required this.data, required this.table, required this.queries});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    queries.add('$table.select($columns)');
    return FakeFilterBuilder(data: data, table: table, queries: queries);
  }
}

class FakeFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  final String table;
  final List<String> queries;

  FakeFilterBuilder({required this.data, required this.table, required this.queries});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    queries.add('$table.eq($column, $value)');
    return this;
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> or(String filters, {String? referencedTable}) {
    queries.add('$table.or($filters)');
    return this;
  }

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(String column,
      {bool ascending = false, bool nullsFirst = false, String? referencedTable}) {
    queries.add('$table.order($column, ascending: $ascending)');
    return FakeTransformBuilder(data: data, table: table, queries: queries);
  }
}

class FakeTransformBuilder extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final List<Map<String, dynamic>> data;
  final String table;
  final List<String> queries;

  FakeTransformBuilder({required this.data, required this.table, required this.queries});

  @override
  Future<U> then<U>(
      FutureOr<U> Function(List<Map<String, dynamic>> value) onValue,
      {Function? onError}) {
    return Future.value(onValue(data));
  }
}

class FakeStudentProfileQuery extends Fake implements SupabaseQueryBuilder {
  final Map<String, dynamic> data;
  final String table;
  final List<String> queries;

  FakeStudentProfileQuery({required this.data, required this.table, required this.queries});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    queries.add('$table.select($columns)');
    return FakeStudentProfileFilter(data: data, table: table, queries: queries);
  }
}

class FakeStudentProfileFilter extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final Map<String, dynamic> data;
  final String table;
  final List<String> queries;

  FakeStudentProfileFilter({required this.data, required this.table, required this.queries});

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object value) {
    queries.add('$table.eq($column, $value)');
    return this;
  }

  @override
  PostgrestTransformBuilder<Map<String, dynamic>> single() {
    queries.add('$table.single()');
    return FakeStudentProfileTransform(data: data, table: table, queries: queries);
  }
}

class FakeStudentProfileTransform extends Fake implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> data;
  final String table;
  final List<String> queries;

  FakeStudentProfileTransform({required this.data, required this.table, required this.queries});

  @override
  Future<U> then<U>(
      FutureOr<U> Function(Map<String, dynamic> value) onValue,
      {Function? onError}) {
    return Future.value(onValue(data));
  }
}

void main() {
  final sampleAnnouncement = {
    'id': '1',
    'title': 'Test Title',
    'content': 'Test Content',
    'priority': 'high',
    'target_type': 'all',
    'created_by': 'Admin',
    'created_at': '2023-10-01T12:00:00Z',
  };

  group('AnnouncementRepository - fetchUserAnnouncements', () {
    test('admin role should fetch all announcements ordered by created_at', () async {
      final queries = <String>[];
      final fakeClient = FakeSupabaseClient(
        announcements: [sampleAnnouncement],
        queries: queries,
      );
      final repository = AnnouncementRepository(client: fakeClient);

      final result = await repository.fetchUserAnnouncements(userId: '123', role: 'admin');

      expect(result.length, 1);
      expect(result.first.id, '1');
      expect(queries, contains('announcements.select(*)'));
      expect(queries, contains('announcements.order(created_at, ascending: false)'));
    });

    test('teacher role should fetch filtered announcements', () async {
      final queries = <String>[];
      final fakeClient = FakeSupabaseClient(
        announcements: [sampleAnnouncement],
        queries: queries,
      );
      final repository = AnnouncementRepository(client: fakeClient);

      final result = await repository.fetchUserAnnouncements(userId: '123', role: 'teacher');

      expect(result.length, 1);
      expect(queries, contains('announcements.or(target_type.eq.all,target_type.eq.teachers)'));
    });

    test('student role should fetch student profile and then filter announcements based on board and standard', () async {
      final queries = <String>[];
      final fakeClient = FakeSupabaseClient(
        announcements: [sampleAnnouncement],
        studentProfile: {'board': 'CBSE', 'standard': '10'},
        queries: queries,
      );
      final repository = AnnouncementRepository(client: fakeClient);

      final result = await repository.fetchUserAnnouncements(userId: '123', role: 'student');

      expect(result.length, 1);
      expect(queries, contains('student_profiles'));
      expect(queries, contains('student_profiles.select(board, standard)'));
      expect(queries, contains('student_profiles.eq(id, 123)'));
      expect(queries, contains('student_profiles.single()'));
      expect(queries, contains('announcements.or(target_type.eq.all,target_type.eq.students,and(target_type.eq.specific_class,target_board.eq.CBSE,target_standard.eq.10))'));
    });

    test('fallback role should fetch target_type all', () async {
      final queries = <String>[];
      final fakeClient = FakeSupabaseClient(
        announcements: [sampleAnnouncement],
        queries: queries,
      );
      final repository = AnnouncementRepository(client: fakeClient);

      final result = await repository.fetchUserAnnouncements(userId: '123', role: 'unknown');

      expect(result.length, 1);
      expect(queries, contains('announcements.eq(target_type, all)'));
    });
  });
}
