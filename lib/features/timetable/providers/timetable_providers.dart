import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/timetable_model.dart';
import '../repository/timetable_repository.dart';

final timetableRepositoryProvider = Provider<TimetableRepository>((ref) {
  return TimetableRepository();
});

String getCurrentDayName() {
  final now = DateTime.now();
  switch (now.weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    case DateTime.wednesday:
      return 'Wednesday';
    case DateTime.thursday:
      return 'Thursday';
    case DateTime.friday:
      return 'Friday';
    case DateTime.saturday:
      return 'Saturday';
    case DateTime.sunday:
      return 'Sunday';
    default:
      return 'Monday';
  }
}

final selectedTimetableDayProvider = StateProvider<String>((ref) => getCurrentDayName());
final selectedTimetableBoardProvider = StateProvider<String>((ref) => 'SSC');
final selectedTimetableStandardProvider = StateProvider<String>((ref) => '10th');

final adminClassTimetableProvider = FutureProvider<List<TimetableSlotModel>>((ref) async {
  final repo = ref.watch(timetableRepositoryProvider);
  final board = ref.watch(selectedTimetableBoardProvider);
  final standard = ref.watch(selectedTimetableStandardProvider);
  final day = ref.watch(selectedTimetableDayProvider);

  return repo.fetchClassTimetable(
    board: board,
    standard: standard,
    dayOfWeek: day,
  );
});

final studentTimetableProvider = FutureProvider.family<List<TimetableSlotModel>, String>((ref, studentId) async {
  final repo = ref.watch(timetableRepositoryProvider);
  final day = ref.watch(selectedTimetableDayProvider);

  return repo.fetchStudentTimetable(
    studentId: studentId,
    dayOfWeek: day,
  );
});

final teacherTimetableProvider = FutureProvider.family<List<TimetableSlotModel>, String>((ref, teacherId) async {
  final repo = ref.watch(timetableRepositoryProvider);
  final day = ref.watch(selectedTimetableDayProvider);

  return repo.fetchTeacherTimetable(
    teacherId: teacherId,
    dayOfWeek: day,
  );
});
