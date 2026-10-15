import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers/connectivity_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Thin strip shown under the status bar when the device is offline.
/// Cached read-only data may still be visible; write actions should be blocked.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider);
    if (online) return const SizedBox.shrink();

    return Material(
      color: AppColors.maroonDark,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.parchment,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You are offline. Showing cached data where available. '
                  'Changes are disabled until you reconnect.',
                  style: AppTypography.poppins(
                    fontSize: 12,
                    color: AppColors.parchment,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Returns `false` (and shows a snackbar) when the device is offline.
bool guardOnline(BuildContext context, WidgetRef ref) {
  if (ref.read(isOnlineProvider)) return true;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('You are offline. Reconnect to make changes.'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.maroon,
    ),
  );
  return false;
}
