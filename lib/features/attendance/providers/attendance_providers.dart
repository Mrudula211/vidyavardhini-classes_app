import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/attendance_model.dart';
import '../repository/attendance_repository.dart';

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return AttendanceRepository();
});

final selectedAttendanceDateProvider = StateProvider<String>((ref) {
  return DateTime.now().toIso8601String().split('T').first;
});

final selectedAttendanceBoardProvider = StateProvider<String>((ref) => 'SSC');
final selectedAttendanceStandardProvider = StateProvider<String>((ref) => '10th');

final teacherAssignedClassesProvider = FutureProvider.family<List<Map<String, String>>, String>((ref, teacherId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchTeacherAssignedClasses(teacherId);
});

final studentsForAttendanceProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final board = ref.watch(selectedAttendanceBoardProvider);
  final standard = ref.watch(selectedAttendanceStandardProvider);
  final date = ref.watch(selectedAttendanceDateProvider);

  return repo.fetchStudentsForAttendance(
    board: board,
    standard: standard,
    date: date,
  );
});

final studentAttendanceHistoryProvider = FutureProvider.family<List<StudentAttendanceModel>, String>((ref, studentId) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchStudentAttendanceHistory(studentId: studentId);
});

final adminAttendanceOverviewProvider = FutureProvider<List<StudentAttendanceModel>>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  final date = ref.watch(selectedAttendanceDateProvider);
  final board = ref.watch(selectedAttendanceBoardProvider);
  final standard = ref.watch(selectedAttendanceStandardProvider);

  return repo.fetchAdminAttendanceOverview(
    date: date,
    board: board,
    standard: standard,
  );
});

final geofenceSettingsProvider = FutureProvider<GeofenceSettingsModel?>((ref) async {
  final repo = ref.watch(attendanceRepositoryProvider);
  return repo.fetchGeofenceSettings();
});
