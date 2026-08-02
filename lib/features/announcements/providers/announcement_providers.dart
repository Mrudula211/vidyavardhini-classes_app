import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/announcement_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../repository/announcement_repository.dart';

final announcementRepositoryProvider = Provider<AnnouncementRepository>((ref) {
  return AnnouncementRepository();
});

final userAnnouncementsProvider = FutureProvider<List<AnnouncementModel>>((ref) async {
  final repo = ref.watch(announcementRepositoryProvider);
  final user = ref.watch(currentUserProvider);
  final role = ref.watch(currentUserRoleProvider).value;

  if (user == null || role == null) return [];

  return repo.fetchUserAnnouncements(
    userId: user.id,
    role: role,
  );
});
