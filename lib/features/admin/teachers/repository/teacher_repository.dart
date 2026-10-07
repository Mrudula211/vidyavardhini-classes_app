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
    final list = (data as List).map((json) => TeacherModel.fromJson(json)).toList();
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
    // 1. Check for duplicate phone in users table
    if (phone.trim().isNotEmpty) {
      final existingPhone = await _client
          .from('users')
          .select('id, phone')
          .eq('phone', phone.trim())
          .maybeSingle();

      if (existingPhone != null) {
        throw Exception('User with phone number $phone is already registered in the database.');
      }
    }

    // 2. Check for duplicate email in teacher_profiles table
    if (email != null && email.trim().isNotEmpty) {
      final existingEmail = await _client
          .from('teacher_profiles')
          .select('id, full_name, teacher_id')
          .eq('email', email.trim())
          .maybeSingle();

      if (existingEmail != null) {
        final teacherId = existingEmail['teacher_id'] ?? '';
        final name = existingEmail['full_name'] ?? 'Existing Teacher';
        throw Exception('Teacher "$name" ($teacherId) with email $email is already registered in the database.');
      }
    }

    // 3. Create via RPC (SECURITY DEFINER — creates matching auth.users,
    // public.users, and teacher_profiles rows atomically; see
    // supabase/migrations/007_fix_teacher_creation.sql). There is no
    // client-safe fallback: public.users.id is a foreign key to
    // auth.users.id, which only a privileged function can satisfy.
    final response = await _client.rpc('create_teacher_profile', params: {
      'p_phone': phone.trim(),
      'p_full_name': fullName.trim(),
      'p_gender': (gender != null && gender.isNotEmpty) ? gender : null,
      'p_dob': (dob != null && dob.isNotEmpty) ? dob : null,
      'p_email': (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      'p_joining_date': (joiningDate != null && joiningDate.isNotEmpty) ? joiningDate : null,
      'p_monthly_salary': monthlySalary,
      'p_access_code': accessCode.trim(),
    },);

    if (response is! Map<String, dynamic> || response.isEmpty) {
      throw Exception('Teacher creation did not return the expected result.');
    }

    return response;
  }

  Future<void> deleteTeacher(String teacherId) async {
    // Delete assignments first
    await _client.from('teacher_assignments').delete().eq('teacher_id', teacherId);
    // Delete teacher profile record
    await _client.from('teacher_profiles').delete().eq('id', teacherId);
    // Delete user record
    try {
      await _client.from('users').delete().eq('id', teacherId);
    } catch (_) {}
  }

  Future<List<TeacherAssignmentModel>> fetchTeacherAssignments(String teacherId) async {
    final data = await _client
        .from('teacher_assignments')
        .select()
        .eq('teacher_id', teacherId);

    return (data as List).map((json) => TeacherAssignmentModel.fromJson(json)).toList();
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

    final academicYearId = currentYearRes != null ? currentYearRes['id'] as String? : null;

    if (academicYearId == null) {
      throw Exception('No active academic year found in database');
    }

    await _client
        .from('teacher_assignments')
        .delete()
        .eq('teacher_id', teacherId)
        .eq('academic_year_id', academicYearId);

    if (assignments.isEmpty) return;

    final rows = assignments.map((a) => {
      'teacher_id': teacherId,
      'academic_year_id': academicYearId,
      'board': a['board'],
      'standard': a['standard'],
      'subject': a['subject'],
    },).toList();

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
