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
