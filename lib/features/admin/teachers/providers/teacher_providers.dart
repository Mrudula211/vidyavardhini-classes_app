import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/teacher_model.dart';
import '../repository/teacher_repository.dart';

final teacherRepositoryProvider = Provider<TeacherRepository>((ref) {
  return TeacherRepository();
});

final teacherSearchQueryProvider = StateProvider<String>((ref) => '');

final teacherListProvider = FutureProvider<List<TeacherModel>>((ref) async {
  final repo = ref.watch(teacherRepositoryProvider);
  final search = ref.watch(teacherSearchQueryProvider);
  return repo.fetchTeachers(searchQuery: search);
});

final teacherDetailProvider = FutureProvider.family<TeacherModel?, String>((ref, id) async {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.fetchTeacherDetail(id);
});

final teacherAssignmentsProvider = FutureProvider.family<List<TeacherAssignmentModel>, String>((ref, teacherId) async {
  final repo = ref.watch(teacherRepositoryProvider);
  return repo.fetchTeacherAssignments(teacherId);
});
