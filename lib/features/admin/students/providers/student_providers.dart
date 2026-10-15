import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/student_model.dart';
import '../repository/student_repository.dart';

final studentRepositoryProvider = Provider<StudentRepository>((ref) {
  return StudentRepository();
});

final studentFilterStatusProvider = StateProvider<String>((ref) => 'all');
final studentSearchQueryProvider = StateProvider<String>((ref) => '');
final studentFilterBoardProvider = StateProvider<String>((ref) => 'all');
final studentFilterStandardProvider = StateProvider<String>((ref) => 'all');
final studentListPageProvider = StateProvider<int>((ref) => 0);

final studentListProvider = FutureProvider<List<StudentModel>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  final status = ref.watch(studentFilterStatusProvider);
  final search = ref.watch(studentSearchQueryProvider);
  final board = ref.watch(studentFilterBoardProvider);
  final standard = ref.watch(studentFilterStandardProvider);
  final page = ref.watch(studentListPageProvider);

  return repo.fetchStudents(
    status: status,
    searchQuery: search,
    board: board,
    standard: standard,
    page: page,
  );
});

final pendingStudentsProvider = FutureProvider<List<StudentModel>>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.fetchPendingStudents();
});

final pendingStudentsCountProvider = FutureProvider<int>((ref) async {
  final pending = await ref.watch(pendingStudentsProvider.future);
  return pending.length;
});

final nextStudentIdProvider = FutureProvider<String>((ref) async {
  final repo = ref.watch(studentRepositoryProvider);
  return repo.getNextStudentId();
});
