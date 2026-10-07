import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../auth/providers/auth_providers.dart';
import '../providers/backup_providers.dart';

/// Human-readable byte size formatter, e.g. 12400000 -> "11.8 MB".
String formatBytes(int? bytes) {
  if (bytes == null) return '--';
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unitIndex = 0;
  while (size >= 1024 && unitIndex < units.length - 1) {
    size /= 1024;
    unitIndex++;
  }
  return '${size.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
}

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isTriggering = false;

  Future<void> _triggerManualBackup() async {
    final admin = ref.read(currentUserProvider);
    if (admin == null) return;

    setState(() => _isTriggering = true);
    try {
      await ref.read(backupRepositoryProvider).triggerManualBackup(admin.id);
      ref.invalidate(backupLogsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Backup request logged. Automated backup execution is not '
              'yet wired up for this version; this entry is a manual '
              'record of the request.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to log backup request: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isTriggering = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'success':
        return AppColors.success;
      case 'failed':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(backupLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backups'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(backupLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Manual Backup',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automated backups are not yet scheduled for this '
                      'app. Triggering a manual backup records a pending '
                      'request in the log below; it does not yet run an '
                      'actual backup job.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.lightOutline,
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _isTriggering ? null : _triggerManualBackup,
                        icon: _isTriggering
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.backup_rounded),
                        label: const Text('Trigger Manual Backup'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logsAsync.when(
              loading: () => ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 6,
                itemBuilder: (context, index) => Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  height: 88,
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
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: AppColors.maroon,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load backup logs.\n$err',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => ref.invalidate(backupLogsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.history_rounded,
                            size: 48,
                            color: AppColors.lightOutline,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No backup logs yet.',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppColors.lightOutline),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(backupLogsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final status = log['status']?.toString() ?? 'pending';
                      final createdAt = DateTime.tryParse(
                        log['created_at']?.toString() ?? '',
                      );
                      final completedAt = DateTime.tryParse(
                        log['completed_at']?.toString() ?? '',
                      );
                      final sizeBytes = log['size_bytes'] as int?;
                      final errorMsg = log['error_msg']?.toString();
                      final statusColor = _statusColor(status);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: statusColor),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Tooltip(
                                    message: 'Restore is not yet available '
                                        'in this version.',
                                    child: TextButton.icon(
                                      onPressed: null,
                                      icon: const Icon(
                                        Icons.restore_rounded,
                                        size: 18,
                                      ),
                                      label: const Text('Restore'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (createdAt != null)
                                Text(
                                  'Requested: '
                                  '${DateFormat('d MMM yyyy, h:mm a').format(createdAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              if (completedAt != null)
                                Text(
                                  'Completed: '
                                  '${DateFormat('d MMM yyyy, h:mm a').format(completedAt)}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              Text(
                                'Size: ${formatBytes(sizeBytes)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              if (status == 'failed' &&
                                  errorMsg != null &&
                                  errorMsg.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  errorMsg,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(color: AppColors.error),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
