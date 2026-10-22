import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../shared/models/student_model.dart';

class StudentRepository {
  StudentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<StudentModel>> fetchStudents({
    String? status,
    String? searchQuery,
    String? board,
    String? standard,
    int page = 0,
    int pageSize = AppConstants.pageSize,
  }) async {
    dynamic query = _client.from('student_profiles').select();

    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }

    if (board != null && board.isNotEmpty && board != 'all') {
      query = query.eq('board', board);
    }

    if (standard != null && standard.isNotEmpty && standard != 'all') {
      query = query.eq('standard', standard);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      query = query.or(
        'full_name.ilike.$q,parent_phone.ilike.$q,student_id.ilike.$q',
      );
    }

    final start = page * pageSize;
    final end = start + pageSize - 1;
    final data =
        await query.order('created_at', ascending: false).range(start, end);
    return (data as List).map((json) => StudentModel.fromJson(json)).toList();
  }

  Future<List<StudentModel>> fetchPendingStudents() async {
    return fetchStudents(status: 'pending');
  }

  Future<StudentModel?> fetchStudentDetail(String id) async {
    final data = await _client
        .from('student_profiles')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;
    return StudentModel.fromJson(data);
  }

  Future<String> getNextStudentId() async {
    try {
      final response = await _client.rpc('next_student_id');
      if (response != null) {
        return response.toString();
      }
    } catch (_) {}
    return 'STU0001';
  }

  Future<void> approveStudent({
    required String studentId,
    required String assignedStudentId,
    required double monthlyFee,
    required String adminId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await _client.from('student_profiles').update({
      'student_id': assignedStudentId,
      'status': 'active',
      'approved_by': adminId,
      'approved_at': now,
      'updated_at': now,
    }).eq('id', studentId);

    final student = await fetchStudentDetail(studentId);
    if (student == null) return;

    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId = currentYearRes != null ? currentYearRes['id'] as String? : null;

    if (academicYearId != null) {
      await _client.from('fee_structure').upsert({
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'monthly_fee': monthlyFee,
        'updated_at': now,
      }, onConflict: 'student_id,academic_year_id',);

      await _client.from('student_enrollments').upsert({
        'student_id': studentId,
        'academic_year_id': academicYearId,
        'board': student.board,
        'standard': student.standard,
      }, onConflict: 'student_id,academic_year_id',);
    }
  }

  /// Admin only (`create_student_account` RPC): creates the student, the
  /// login (mobile and/or email) and a generated access code in one step.
  /// Returns `{id, student_id, access_code, login}`.
  Future<Map<String, dynamic>> createStudent({
    required String fullName,
    required String gender,
    required DateTime dob,
    required String parentName,
    required String parentPhone,
    required String schoolName,
    required String board,
    required String standard,
    required double monthlyFee,
    String? loginPhone,
    String? loginEmail,
    String? whatsappNumber,
  }) async {
    String? clean(String? v) =>
        (v == null || v.trim().isEmpty) ? null : v.trim();

    final res = await _client.rpc('create_student_account', params: {
      'p_full_name': fullName.trim(),
      'p_gender': gender,
      'p_dob': dob.toIso8601String().split('T').first,
      'p_parent_name': parentName.trim(),
      'p_parent_phone': parentPhone.trim(),
      'p_school_name': schoolName.trim(),
      'p_board': board,
      'p_standard': standard,
      'p_monthly_fee': monthlyFee,
      'p_login_phone': clean(loginPhone),
      'p_login_email': clean(loginEmail),
      'p_whatsapp_number': clean(whatsappNumber),
    },);
    return Map<String, dynamic>.from(res as Map);
  }

  /// The mobile number the student logs in with (admin only).
  Future<String?> fetchLoginPhone(String studentId) async {
    final data = await _client
        .from('users')
        .select('phone')
        .eq('id', studentId)
        .maybeSingle();
    return data?['phone'] as String?;
  }

  /// The student's current access code (admin only; null if none stored).
  Future<String?> fetchAccessCode(String studentId) async {
    final data = await _client
        .from('student_access_codes')
        .select('access_code')
        .eq('student_id', studentId)
        .maybeSingle();
    return data?['access_code'] as String?;
  }

  /// Replaces a lost access code and returns the new one.
  Future<String> regenerateAccessCode(String studentId) async {
    final res = await _client.rpc(
      'regenerate_student_access_code',
      params: {'p_student_id': studentId},
    );
    return res as String;
  }

  Future<void> rejectStudent({
    required String studentId,
    required String reason,
  }) async {
    await _client.from('student_profiles').update({
      'status': 'rejected',
      'rejection_reason': reason,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', studentId);
  }

  Future<void> banStudent(String studentId) async {
    await _client.from('student_profiles').update({
      'status': 'banned',
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', studentId);
  }

  Future<void> updateStudentProfile(StudentModel student) async {
    await _client.from('student_profiles').update({
      'full_name': student.fullName,
      'parent_name': student.parentName,
      'parent_phone': student.parentPhone,
      'whatsapp_number': student.whatsappNumber,
      'email': student.email,
      'school_name': student.schoolName,
      'board': student.board,
      'standard': student.standard,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', student.id);
  }
}
