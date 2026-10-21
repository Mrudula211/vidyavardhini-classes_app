import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/online_cache_fetch.dart';
import '../../../shared/models/content_model.dart';

class ContentRepository {
  ContentRepository({SupabaseClient? client, StorageService? storage})
      : _client = client ?? Supabase.instance.client,
        _storage = storage ?? StorageService(client: client);

  final SupabaseClient _client;
  final StorageService _storage;

  // ── Homework Operations ──────────────────────────────────────────
  Future<void> createHomework({
    required String teacherId,
    required String board,
    required String standard,
    required String subject,
    required String title,
    String? description,
    required String dueDate,
    List<PickedAttachment> attachments = const [],
  }) async {
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId =
        currentYearRes != null ? currentYearRes['id'] as String? : null;
    if (academicYearId == null) {
      throw Exception('No active academic year found');
    }

    await _insertWithAttachments(
      table: 'homework',
      attachmentTable: 'homework_attachments',
      foreignKey: 'homework_id',
      bucket: AttachmentModel.homeworkBucket,
      teacherId: teacherId,
      files: attachments,
      row: {
        'teacher_id': teacherId,
        'academic_year_id': academicYearId,
        'board': board,
        'standard': standard,
        'subject': subject,
        'title': title,
        'description': description,
        'due_date': dueDate,
        'is_active': true,
      },
    );
  }

  /// Uploads files, inserts the parent row, then the attachment rows. If the
  /// database writes fail, the uploaded objects are removed again.
  Future<void> _insertWithAttachments({
    required String table,
    required String attachmentTable,
    required String foreignKey,
    required String bucket,
    required String teacherId,
    required List<PickedAttachment> files,
    required Map<String, dynamic> row,
  }) async {
    final uploaded = await _storage.uploadAll(
      bucket: bucket,
      ownerId: teacherId,
      files: files,
    );
    try {
      final inserted =
          await _client.from(table).insert(row).select('id').single();
      if (uploaded.isNotEmpty) {
        await _client.from(attachmentTable).insert([
          for (final u in uploaded)
            {
              foreignKey: inserted['id'],
              'file_url': u.path,
              'file_type': u.fileType,
              'file_name': u.name,
              'file_size': u.size,
            },
        ]);
      }
    } catch (_) {
      await _storage.removeAll(bucket, uploaded.map((u) => u.path).toList());
      rethrow;
    }
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
    List<PickedAttachment> attachments = const [],
  }) async {
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId =
        currentYearRes != null ? currentYearRes['id'] as String? : null;
    if (academicYearId == null) {
      throw Exception('No active academic year found');
    }

    await _insertWithAttachments(
      table: 'classwork',
      attachmentTable: 'classwork_attachments',
      foreignKey: 'classwork_id',
      bucket: AttachmentModel.classworkBucket,
      teacherId: teacherId,
      files: attachments,
      row: {
        'teacher_id': teacherId,
        'academic_year_id': academicYearId,
        'board': board,
        'standard': standard,
        'subject': subject,
        'title': title,
        'description': description,
        'is_active': true,
      },
    );
  }

  Future<List<ClassworkModel>> fetchTeacherClassworkList(
    String teacherId,
  ) async {
    final data = await _client
        .from('classwork')
        .select('*, teacher_profiles(*), classwork_attachments(*)')
        .eq('teacher_id', teacherId)
        .order('created_at', ascending: false)
        .limit(AppConstants.pageSize);

    return (data as List).map((j) => ClassworkModel.fromJson(j)).toList();
  }

  Future<List<ClassworkModel>> fetchStudentClassworkList(
    String studentId,
  ) async {
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
