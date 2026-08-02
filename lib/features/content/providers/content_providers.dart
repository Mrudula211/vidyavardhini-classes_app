import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/content_model.dart';
import '../repository/content_repository.dart';

final contentRepositoryProvider = Provider<ContentRepository>((ref) {
  return ContentRepository();
});

final teacherHomeworkListProvider = FutureProvider.family<List<HomeworkModel>, String>((ref, teacherId) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchTeacherHomeworkList(teacherId);
});

final studentHomeworkListProvider = FutureProvider.family<List<HomeworkModel>, String>((ref, studentId) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchStudentHomeworkList(studentId);
});

final teacherClassworkListProvider = FutureProvider.family<List<ClassworkModel>, String>((ref, teacherId) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchTeacherClassworkList(teacherId);
});

final studentClassworkListProvider = FutureProvider.family<List<ClassworkModel>, String>((ref, studentId) async {
  final repo = ref.watch(contentRepositoryProvider);
  return repo.fetchStudentClassworkList(studentId);
});
