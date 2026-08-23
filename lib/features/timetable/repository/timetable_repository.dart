import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/timetable_model.dart';

class TimetableRepository {
  final SupabaseClient _client;

  TimetableRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<void> createTimetableSlot({
    required String board,
    required String standard,
    required String subject,
    String? teacherId,
    required String dayOfWeek,
    required String startTime,
    required String endTime,
    String? roomNumber,
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

    await _client.from('timetable_slots').insert({
      'academic_year_id': academicYearId,
      'board': board,
      'standard': standard,
      'subject': subject,
      'teacher_id': teacherId,
      'day_of_week': dayOfWeek,
      'start_time': startTime,
      'end_time': endTime,
      'room_number': roomNumber,
    });
  }

  Future<List<TimetableSlotModel>> fetchClassTimetable({
    required String board,
    required String standard,
    String? dayOfWeek,
  }) async {
    dynamic query = _client
        .from('timetable_slots')
        .select('*, teacher_profiles(*)')
        .eq('board', board)
        .eq('standard', standard);

    if (dayOfWeek != null && dayOfWeek.isNotEmpty && dayOfWeek != 'All') {
      query = query.eq('day_of_week', dayOfWeek);
    }

    final data = await query.order('start_time', ascending: true);
    return (data as List).map((j) => TimetableSlotModel.fromJson(j)).toList();
  }

  Future<List<TimetableSlotModel>> fetchStudentTimetable({
    required String studentId,
    String? dayOfWeek,
  }) async {
    final profile = await _client
        .from('student_profiles')
        .select('board, standard')
        .eq('id', studentId)
        .single();

    final board = profile['board'] as String;
    final standard = profile['standard'] as String;

    return fetchClassTimetable(
      board: board,
      standard: standard,
      dayOfWeek: dayOfWeek,
    );
  }

  Future<List<TimetableSlotModel>> fetchTeacherTimetable({
    required String teacherId,
    String? dayOfWeek,
  }) async {
    dynamic query = _client
        .from('timetable_slots')
        .select('*, teacher_profiles(*)')
        .eq('teacher_id', teacherId);

    if (dayOfWeek != null && dayOfWeek.isNotEmpty && dayOfWeek != 'All') {
      query = query.eq('day_of_week', dayOfWeek);
    }

    final data = await query.order('start_time', ascending: true);
    return (data as List).map((j) => TimetableSlotModel.fromJson(j)).toList();
  }

  Future<void> deleteTimetableSlot(String slotId) async {
    await _client.from('timetable_slots').delete().eq('id', slotId);
  }
}
