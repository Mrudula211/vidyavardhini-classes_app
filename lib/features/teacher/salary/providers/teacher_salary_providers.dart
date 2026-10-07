import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/teacher_salary_model.dart';
import '../repository/teacher_salary_repository.dart';

final teacherSalaryRepositoryProvider =
    Provider<TeacherSalaryRepository>((ref) {
  return TeacherSalaryRepository();
});

/// Full salary history (newest first) for the teacher identified by
/// [teacherId]. The teacher's own id must be passed in by the caller
/// (from `currentUserProvider`) so results are always scoped to the
/// signed-in teacher.
final teacherSalaryHistoryProvider =
    FutureProvider.autoDispose.family<List<TeacherSalaryModel>, String>(
        (ref, teacherId) async {
  final repo = ref.watch(teacherSalaryRepositoryProvider);
  return repo.fetchSalaryHistory(teacherId: teacherId);
});
