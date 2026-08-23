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

    Map<String, dynamic> result = {};

    // 3. Try RPC creation first
    try {
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

      if (response is Map<String, dynamic> && response.isNotEmpty) {
        result = response;
      }
    } catch (_) {}

    // 4. Direct table insert fallback if RPC returned empty or failed
    if (result.isEmpty) {
      // Create user entry first
      final userRes = await _client.from('users').insert({
        'phone': phone.trim(),
        'role': 'teacher',
        'is_active': true,
      }).select('id').single();

      final userId = userRes['id'] as String;

      final existingRes = await _client.from('teacher_profiles').select('id');
      final count = (existingRes as List).length + 1;
      final assignedId = 'TCH${count.toString().padLeft(4, '0')}';

      final insertData = await _client.from('teacher_profiles').insert({
        'id': userId,
        'teacher_id': assignedId,
        'full_name': fullName.trim(),
        'gender': (gender != null && gender.isNotEmpty) ? gender : null,
        'dob': (dob != null && dob.isNotEmpty) ? dob : null,
        'email': (email != null && email.trim().isNotEmpty) ? email.trim() : null,
        'joining_date': (joiningDate != null && joiningDate.isNotEmpty) ? joiningDate : DateTime.now().toIso8601String().split('T')[0],
        'monthly_salary': monthlySalary,
        'is_active': true,
      }).select().single();

      result = Map<String, dynamic>.from(insertData);
    }

    return result;
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
