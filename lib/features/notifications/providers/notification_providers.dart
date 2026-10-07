import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../repository/notification_repository.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository();
});

final notificationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return ref.watch(notificationRepositoryProvider).fetchNotifications(user.id);
});

final unreadNotificationCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return 0;
  return ref.watch(notificationRepositoryProvider).unreadCount(user.id);
});
