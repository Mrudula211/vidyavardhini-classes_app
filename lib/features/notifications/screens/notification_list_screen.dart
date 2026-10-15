import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../providers/notification_providers.dart';

class NotificationListScreen extends ConsumerWidget {
  const NotificationListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(notificationsProvider),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: 6,
          itemBuilder: (context, index) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 40, color: AppColors.maroon,),
                const SizedBox(height: 12),
                Text(
                  'Could not load notifications.\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(notificationsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.notifications_none_rounded,
                        size: 48, color: AppColors.lightOutline,),
                    const SizedBox(height: 12),
                    Text(
                      'No notifications yet.',
                      style: AppTypography.poppins(
                        fontSize: 14,
                        color: AppColors.lightOutline,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final item = notifications[index];
                final isRead = item['is_read'] == true;
                final createdAt = DateTime.tryParse(
                  item['created_at']?.toString() ?? '',
                );

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  color: isRead
                      ? null
                      : AppColors.gold.withValues(alpha: 0.08),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Icon(
                      isRead
                          ? Icons.notifications_none_rounded
                          : Icons.notifications_active_rounded,
                      color: isRead ? AppColors.lightOutline : AppColors.gold,
                    ),
                    title: Text(
                      item['title']?.toString() ?? '',
                      style: AppTypography.poppins(
                        fontWeight:
                            isRead ? FontWeight.w400 : FontWeight.w700,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(item['body']?.toString() ?? ''),
                        if (createdAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('d MMM, h:mm a').format(createdAt),
                            style: AppTypography.poppins(
                              fontSize: 11,
                              color: AppColors.lightOutline,
                            ),
                          ),
                        ],
                      ],
                    ),
                    isThreeLine: true,
                    onTap: isRead
                        ? null
                        : () async {
                            await ref
                                .read(notificationRepositoryProvider)
                                .markAsRead(item['id'].toString());
                            ref.invalidate(notificationsProvider);
                            ref.invalidate(unreadNotificationCountProvider);
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
