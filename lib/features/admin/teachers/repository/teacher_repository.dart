import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/teacher_model.dart';

class TeacherRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<TeacherModel>> fetchTeachers({String? searchQuery}) async {
    dynamic query = _client.from('teacher_profiles').select();

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      query = query.or('full_name.ilike.$q,teacher_id.ilike.$q,email.ilike.$q');
    }

    final data = await query;
    final list =
        (data as List).map((json) => TeacherModel.fromJson(json)).toList();
    list.sort((a, b) => b.teacherId.compareTo(a.teacherId));
    return list;
  }

  Future<TeacherModel?> fetchTeacherDetail(String id) async {
    final data = await _client
        .from('teacher_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return TeacherModel.fromJson(data);
  }

  /// Creates a teacher login (the 6-digit access code is the password) through the
  /// `create_teacher_profile` RPC (SECURITY DEFINER — creates the auth account
  /// and the profile rows atomically; admin only). The database rejects
  /// duplicate mobile numbers/emails with a readable message.
  Future<Map<String, dynamic>> createTeacher({
    required String fullName,
    required String phone,
    String? email,
    String? gender,
    String? dob,
    String? joiningDate,
    required double monthlySalary,
    required String accessCode,
  }) async {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();

    final response = await _client.rpc(
      'create_teacher_profile',
      params: {
        'p_full_name': fullName.trim(),
        // The 6-digit access code IS the login password (no second step).
        'p_password': accessCode.trim(),
        'p_access_code': accessCode.trim(),
        'p_phone': clean(phone),
        'p_email': clean(email),
        'p_gender': clean(gender),
        'p_dob': clean(dob),
        'p_joining_date': clean(joiningDate),
        'p_monthly_salary': monthlySalary,
      },
    );

    if (response is! Map<String, dynamic> || response.isEmpty) {
      throw Exception('Teacher creation did not return the expected result.');
    }

    return response;
  }

  /// Sets a new 6-digit access code (= login password) for a teacher
  /// (`admin_reset_user_password`, admin only).
  Future<void> resetAccessCode(String teacherId, String newCode) async {
    await _client.rpc(
      'admin_reset_user_password',
      params: {'p_user_id': teacherId, 'p_new_password': newCode.trim()},
    );
  }

  Future<void> deleteTeacher(String teacherId) async {
    // Delete assignments first
    await _client
        .from('teacher_assignments')
        .delete()
        .eq('teacher_id', teacherId);
    // Delete teacher profile record
    await _client.from('teacher_profiles').delete().eq('id', teacherId);
    // Delete user record
    try {
      await _client.from('users').delete().eq('id', teacherId);
    } catch (_) {}
  }

  Future<List<TeacherAssignmentModel>> fetchTeacherAssignments(
    String teacherId,
  ) async {
    final data = await _client
        .from('teacher_assignments')
        .select()
        .eq('teacher_id', teacherId);

    return (data as List)
        .map((json) => TeacherAssignmentModel.fromJson(json))
        .toList();
  }

  Future<void> saveTeacherAssignments({
    required String teacherId,
    required List<Map<String, String>> assignments,
  }) async {
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId =
        currentYearRes != null ? currentYearRes['id'] as String? : null;

    if (academicYearId == null) {
      throw Exception('No active academic year found in database');
    }

    await _client
        .from('teacher_assignments')
        .delete()
        .eq('teacher_id', teacherId)
        .eq('academic_year_id', academicYearId);

    if (assignments.isEmpty) return;

    final rows = assignments
        .map(
          (a) => {
            'teacher_id': teacherId,
            'academic_year_id': academicYearId,
            'board': a['board'],
            'standard': a['standard'],
            'subject': a['subject'],
          },
        )
        .toList();

    await _client.from('teacher_assignments').insert(rows);
  }

  Future<void> updateTeacherSalary({
    required String teacherId,
    required double monthlySalary,
  }) async {
    await _client.from('teacher_profiles').update({
      'monthly_salary': monthlySalary,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', teacherId);
  }

  Future<void> toggleTeacherStatus({
    required String teacherId,
    required bool isActive,
  }) async {
    await _client.from('teacher_profiles').update({
      'is_active': isActive,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', teacherId);

    try {
      await _client.from('users').update({
        'is_active': isActive,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', teacherId);
    } catch (_) {}
  }
}
