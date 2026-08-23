import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/teacher_model.dart';

String _generateUuid() {
  final random = Random.secure();
  final values = List<int>.generate(16, (i) => random.nextInt(256));
  values[6] = (values[6] & 0x0f) | 0x40; // set version to 4
  values[8] = (values[8] & 0x3f) | 0x80; // set variant to IETF
  return [
    values.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    values.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    values.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    values.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    values.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
  ].join('-');
}

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
    final cleanPhone = phone.trim();
    final cleanEmail = (email != null && email.trim().isNotEmpty) ? email.trim() : null;

    // 1. Check for duplicate phone in users table
    if (cleanPhone.isNotEmpty) {
      final existingPhone = await _client
          .from('users')
          .select('id, phone')
          .eq('phone', cleanPhone)
          .maybeSingle();

      if (existingPhone != null) {
        throw Exception('User with phone number $cleanPhone is already registered in the database.');
      }
    }

    // 2. Check for duplicate email in teacher_profiles table
    if (cleanEmail != null) {
      final existingEmail = await _client
          .from('teacher_profiles')
          .select('id, full_name, teacher_id')
          .eq('email', cleanEmail)
          .maybeSingle();

      if (existingEmail != null) {
        final teacherId = existingEmail['teacher_id'] ?? '';
        final name = existingEmail['full_name'] ?? 'Existing Teacher';
        throw Exception('Teacher "$name" ($teacherId) with email $cleanEmail is already registered in the database.');
      }
    }

    // 3. Try RPC creation first (runs server-side with full permissions)
    try {
      final response = await _client.rpc('create_teacher_profile', params: {
        'p_phone': cleanPhone,
        'p_full_name': fullName.trim(),
        'p_gender': (gender != null && gender.isNotEmpty) ? gender : null,
        'p_dob': (dob != null && dob.isNotEmpty) ? dob : null,
        'p_email': cleanEmail,
        'p_joining_date': (joiningDate != null && joiningDate.isNotEmpty) ? joiningDate : null,
        'p_monthly_salary': monthlySalary,
        'p_access_code': accessCode.trim(),
      });

      if (response is Map<String, dynamic> && response.isNotEmpty) {
        return response;
      }
    } catch (rpcError) {
      // If RPC failed due to missing function or foreign key constraint, proceed to direct fallback
    }

    // 4. Direct Table Insertion Fallback
    String userId = _generateUuid();

    // Insert user row
    try {
      await _client.from('users').insert({
        'id': userId,
        'phone': cleanPhone,
        'role': 'teacher',
        'is_active': true,
      });
    } catch (e) {
      final existingUser = await _client.from('users').select('id').eq('phone', cleanPhone).maybeSingle();
      if (existingUser != null) {
        userId = existingUser['id'] as String;
      } else {
        throw Exception(
          'Supabase database foreign key constraint error. Please execute the provided SQL setup script in your Supabase SQL Editor once.',
        );
      }
    }

    // Insert teacher_profiles row
    final existingRes = await _client.from('teacher_profiles').select('id');
    final count = (existingRes as List).length + 1;
    final assignedId = 'TCH${count.toString().padLeft(4, '0')}';

    Map<String, dynamic> profileRow = {
      'id': userId,
      'teacher_id': assignedId,
      'full_name': fullName.trim(),
      'gender': (gender != null && gender.isNotEmpty) ? gender : null,
      'dob': (dob != null && dob.isNotEmpty) ? dob : null,
      'email': cleanEmail,
      'joining_date': (joiningDate != null && joiningDate.isNotEmpty) ? joiningDate : DateTime.now().toIso8601String().split('T')[0],
      'monthly_salary': monthlySalary,
      'is_active': true,
    };

    dynamic insertData;
    try {
      profileRow['access_code'] = accessCode.trim();
      insertData = await _client.from('teacher_profiles').insert(profileRow).select().single();
    } catch (_) {
      profileRow.remove('access_code');
      profileRow['access_code_hash'] = accessCode.trim();
      insertData = await _client.from('teacher_profiles').insert(profileRow).select().single();
    }

    return Map<String, dynamic>.from(insertData);
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
    }).toList();

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
