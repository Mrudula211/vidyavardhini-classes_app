import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/online_cache_fetch.dart';
import '../../../shared/models/attendance_model.dart';
import '../../../shared/models/student_model.dart';

class AttendanceRepository {
  final SupabaseClient _client;

  AttendanceRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  Future<List<Map<String, String>>> fetchTeacherAssignedClasses(
    String teacherId,
  ) async {
    final data = await _client
        .from('teacher_assignments')
        .select('board, standard, subject')
        .eq('teacher_id', teacherId);

    final Set<String> uniqueKeys = {};
    final List<Map<String, String>> result = [];

    for (final row in data as List) {
      final key = '${row['board']}_${row['standard']}';
      if (!uniqueKeys.contains(key)) {
        uniqueKeys.add(key);
        result.add({
          'board': row['board'] as String,
          'standard': row['standard'] as String,
        });
      }
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> fetchStudentsForAttendance({
    required String board,
    required String standard,
    required String date,
  }) async {
    final studentsData = await _client
        .from('student_profiles')
        .select()
        .eq('board', board)
        .eq('standard', standard)
        .eq('status', 'active')
        .order('full_name');

    final students =
        (studentsData as List).map((j) => StudentModel.fromJson(j)).toList();
    if (students.isEmpty) return [];

    final studentIds = students.map((s) => s.id).toList();

    final existingAttendance = await _client
        .from('student_attendance')
        .select('*, absence_reasons(*)')
        .filter('student_id', 'in', studentIds)
        .eq('date', date);

    final Map<String, Map<String, dynamic>> attendanceMap = {};
    for (final record in existingAttendance as List) {
      attendanceMap[record['student_id'] as String] = record;
    }

    return students.map((s) {
      final existing = attendanceMap[s.id];
      String status = 'present';
      String? reason;

      if (existing != null) {
        status = existing['status'] as String? ?? 'present';
        final reasons = existing['absence_reasons'] as List?;
        if (reasons != null && reasons.isNotEmpty) {
          reason = reasons.first['reason'] as String?;
        }
      }

      return {
        'student': s,
        'status': status,
        'reason': reason ?? 'sick',
        'attendance_id': existing?['id'],
      };
    }).toList();
  }

  Future<void> submitBatchAttendance({
    required String date,
    required String markedBy,
    required List<Map<String, dynamic>> records,
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

    for (final record in records) {
      final student = record['student'] as StudentModel;
      final status = record['status'] as String;
      final reason = record['reason'] as String?;

      final upsertRes = await _client
          .from('student_attendance')
          .upsert(
            {
              'student_id': student.id,
              'academic_year_id': academicYearId,
              'date': date,
              'status': status,
              'marked_by': markedBy,
              'updated_at': DateTime.now().toIso8601String(),
            },
            onConflict: 'student_id,date',
          )
          .select('id')
          .single();

      final attendanceId = upsertRes['id'] as String;

      // Handle absence reason
      if (status == 'absent' && reason != null && reason.isNotEmpty) {
        await _client
            .from('absence_reasons')
            .delete()
            .eq('attendance_id', attendanceId);
        await _client.from('absence_reasons').insert({
          'attendance_id': attendanceId,
          'reason': reason,
        });
      } else {
        await _client
            .from('absence_reasons')
            .delete()
            .eq('attendance_id', attendanceId);
      }
    }
  }

  /// Attendance for [studentId] within [month] (year+month). Defaults to the
  /// current calendar month so the query stays bounded as history grows.
  Future<List<StudentAttendanceModel>> fetchStudentAttendanceHistory({
    required String studentId,
    DateTime? month,
  }) {
    final target = month ?? DateTime.now();
    final start =
        DateTime(target.year, target.month, 1).toIso8601String().split('T').first;
    final endDay = DateTime(target.year, target.month + 1, 0).day;
    final end = DateTime(target.year, target.month, endDay)
        .toIso8601String()
        .split('T')
        .first;
    final cacheKey =
        'attendance_${studentId}_${target.year}_${target.month}';

    return fetchWithCacheFallback<StudentAttendanceModel>(
      cacheKey: cacheKey,
      ttlMinutes: AppConstants.attendanceCacheMins,
      fromJson: StudentAttendanceModel.fromJson,
      load: () async {
        final data = await _client
            .from('student_attendance')
            .select('*, absence_reasons(*)')
            .eq('student_id', studentId)
            .gte('date', start)
            .lte('date', end)
            .order('date', ascending: false);
        return normalizeCacheRows(data as List);
      },
    );
  }

  Future<List<StudentAttendanceModel>> fetchAdminAttendanceOverview({
    required String date,
    String? board,
    String? standard,
  }) async {
    dynamic query = _client
        .from('student_attendance')
        .select('*, student_profiles!inner(*), absence_reasons(*)')
        .eq('date', date);

    if (board != null && board != 'all') {
      query = query.eq('student_profiles.board', board);
    }
    if (standard != null && standard != 'all') {
      query = query.eq('student_profiles.standard', standard);
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List)
        .map((j) => StudentAttendanceModel.fromJson(j))
        .toList();
  }

  Future<GeofenceSettingsModel?> fetchGeofenceSettings() async {
    final data =
        await _client.from('geofence_settings').select().limit(1).maybeSingle();
    if (data == null) return null;
    return GeofenceSettingsModel.fromJson(data);
  }

  Future<void> updateGeofenceSettings({
    required double lat,
    required double lng,
    required int radiusMeters,
    required String updatedBy,
  }) async {
    final existing = await fetchGeofenceSettings();
    if (existing != null) {
      await _client.from('geofence_settings').update({
        'latitude': lat,
        'longitude': lng,
        'radius_meters': radiusMeters,
        'updated_by': updatedBy,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', existing.id);
    } else {
      await _client.from('geofence_settings').insert({
        'latitude': lat,
        'longitude': lng,
        'radius_meters': radiusMeters,
        'updated_by': updatedBy,
      });
    }
  }

  Future<bool> checkAndMarkTeacherGeofence({
    required String teacherId,
    required double userLat,
    required double userLng,
  }) async {
    final settings = await fetchGeofenceSettings();
    if (settings == null) return false;

    final distanceMeters = calculateDistance(
      userLat,
      userLng,
      settings.latitude,
      settings.longitude,
    );

    if (distanceMeters <= settings.radiusMeters) {
      final today = DateTime.now().toIso8601String().split('T').first;
      final now = DateTime.now().toIso8601String();

      await _client.from('teacher_attendance').upsert(
        {
          'teacher_id': teacherId,
          'date': today,
          'status': 'present',
          'check_in_time': now,
          'latitude': userLat,
          'longitude': userLng,
          'updated_at': now,
        },
        onConflict: 'teacher_id,date',
      );
      return true;
    }
    return false;
  }

  @visibleForTesting
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) * (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a)) * 1000; // Returns distance in meters
  }
}
