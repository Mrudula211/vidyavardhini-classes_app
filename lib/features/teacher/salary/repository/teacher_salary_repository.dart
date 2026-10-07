import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../shared/models/teacher_salary_model.dart';

/// Repository for a teacher's own salary records.
///
/// Reads from `teacher_salary`. The table's RLS policy
/// ("teacher_salary: own read") already restricts rows to
/// `auth.uid() = teacher_id`, but every query here also filters by
/// [teacherId] explicitly as defense in depth, per CLAUDE.md business
/// rules: teachers must only ever see their own salary data and never
/// get write access to fee/revenue/salary records.
class TeacherSalaryRepository {
  final SupabaseClient _client;

  TeacherSalaryRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches the full salary history for [teacherId], ordered by
  /// year/month descending (most recent first).
  Future<List<TeacherSalaryModel>> fetchSalaryHistory({
    required String teacherId,
  }) async {
    final data = await _client
        .from('teacher_salary')
        .select()
        .eq('teacher_id', teacherId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (data as List)
        .map((json) => TeacherSalaryModel.fromJson(json))
        .toList();
  }

  /// Fetches a single salary record for [teacherId] in a given
  /// [month]/[year], or null if no record exists yet (e.g. the record
  /// has not been generated for the current month).
  Future<TeacherSalaryModel?> fetchSalaryForMonth({
    required String teacherId,
    required int month,
    required int year,
  }) async {
    final data = await _client
        .from('teacher_salary')
        .select()
        .eq('teacher_id', teacherId)
        .eq('month', month)
        .eq('year', year)
        .maybeSingle();

    if (data == null) return null;
    return TeacherSalaryModel.fromJson(data);
  }
}
