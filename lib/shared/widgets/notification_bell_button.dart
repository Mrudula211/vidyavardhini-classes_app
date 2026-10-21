import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../features/notifications/providers/notification_providers.dart';
import '../../l10n/l10n_context.dart';

/// App-bar action that opens the in-app notification list and shows an
/// unread count badge when the signed-in user has unread rows.
class NotificationBellButton extends ConsumerWidget {
  const NotificationBellButton({
    super.key,
    this.iconColor = AppColors.gold,
  });

  final Color iconColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadAsync = ref.watch(unreadNotificationCountProvider);
    final unread = unreadAsync.when(
      data: (count) => count,
      loading: () => 0,
      error: (_, __) => 0,
    );

    return IconButton(
      tooltip: unread > 0
          ? context.l10n.notificationsUnread(unread.toString())
          : context.l10n.notificationsTitle,
      onPressed: () => context.push(Routes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.gold,
        textColor: AppColors.maroonDark,
        label: Text(
          unread > 99 ? '99+' : '$unread',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
        ),
        child: Icon(Icons.notifications_outlined, color: iconColor),
      ),
    );
  }
}
