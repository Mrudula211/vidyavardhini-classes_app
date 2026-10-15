import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/online_cache_fetch.dart';
import '../../../shared/models/content_model.dart';

class ContentRepository {
  ContentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  // ── Homework Operations ──────────────────────────────────────────
  Future<void> createHomework({
    required String teacherId,
    required String board,
    required String standard,
    required String subject,
    required String title,
    String? description,
    required String dueDate,
  }) async {
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId = currentYearRes != null ? currentYearRes['id'] as String? : null;
    if (academicYearId == null) throw Exception('No active academic year found');

    await _client.from('homework').insert({
      'teacher_id': teacherId,
      'academic_year_id': academicYearId,
      'board': board,
      'standard': standard,
      'subject': subject,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'is_active': true,
    });
  }

  Future<List<HomeworkModel>> fetchTeacherHomeworkList(String teacherId) {
    return fetchWithCacheFallback<HomeworkModel>(
      cacheKey: 'homework_teacher_$teacherId',
      ttlMinutes: AppConstants.homeworkCacheMins,
      fromJson: HomeworkModel.fromJson,
      load: () async {
        final data = await _client
            .from('homework')
            .select('*, teacher_profiles(*), homework_attachments(*)')
            .eq('teacher_id', teacherId)
            .order('created_at', ascending: false)
            .limit(AppConstants.pageSize);
        return normalizeCacheRows(data as List);
      },
    );
  }

  Future<List<HomeworkModel>> fetchStudentHomeworkList(String studentId) {
    return fetchWithCacheFallback<HomeworkModel>(
      cacheKey: 'homework_student_$studentId',
      ttlMinutes: AppConstants.homeworkCacheMins,
      fromJson: HomeworkModel.fromJson,
      load: () async {
        final profile = await _client
            .from('student_profiles')
            .select('board, standard')
            .eq('id', studentId)
            .single();

        final board = profile['board'] as String;
        final standard = profile['standard'] as String;

        final data = await _client
            .from('homework')
            .select('*, teacher_profiles(*), homework_attachments(*)')
            .eq('board', board)
            .eq('standard', standard)
            .eq('is_active', true)
            .order('due_date', ascending: true)
            .limit(AppConstants.pageSize);
        return normalizeCacheRows(data as List);
      },
    );
  }

  // ── Classwork Operations ─────────────────────────────────────────
  Future<void> createClasswork({
    required String teacherId,
    required String board,
    required String standard,
    required String subject,
    required String title,
    String? description,
  }) async {
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId = currentYearRes != null ? currentYearRes['id'] as String? : null;
    if (academicYearId == null) throw Exception('No active academic year found');

    await _client.from('classwork').insert({
      'teacher_id': teacherId,
      'academic_year_id': academicYearId,
      'board': board,
      'standard': standard,
      'subject': subject,
      'title': title,
      'description': description,
      'is_active': true,
    });
  }

  Future<List<ClassworkModel>> fetchTeacherClassworkList(String teacherId) async {
    final data = await _client
        .from('classwork')
        .select('*, teacher_profiles(*), classwork_attachments(*)')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(AppConstants.pageSize);

    return (data as List).map((j) => ClassworkModel.fromJson(j)).toList();
  }

  Future<List<ClassworkModel>> fetchStudentClassworkList(String studentId) async {
    final profile = await _client
        .from('student_profiles')
        .select('board, standard')
        .eq('id', studentId)
        .single();

    final board = profile['board'] as String;
    final standard = profile['standard'] as String;

    final data = await _client
        .from('classwork')
        .select('*, teacher_profiles(*), classwork_attachments(*)')
        .eq('board', board)
        .eq('standard', standard)
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .limit(AppConstants.pageSize);

    return (data as List).map((j) => ClassworkModel.fromJson(j)).toList();
  }
}
