import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/audit_log_providers.dart';

const _entityTypeOptions = <String>[
  'students',
  'teachers',
  'fees',
  'attendance',
  'announcements',
  'homework',
  'classwork',
  'users',
];

class AuditLogsScreen extends ConsumerStatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  ConsumerState<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends ConsumerState<AuditLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickDateRange() async {
    final filter = ref.read(auditLogFilterProvider);
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: (filter.from != null && filter.to != null)
          ? DateTimeRange(start: filter.from!, end: filter.to!)
          : null,
    );
    if (range != null) {
      ref.read(auditLogFilterProvider.notifier).state = filter.copyWith(
        from: DateTime(range.start.year, range.start.month, range.start.day),
        to: DateTime(
            range.end.year, range.end.month, range.end.day, 23, 59, 59),
        page: 0,
      );
    }
  }

  void _clearDateRange() {
    final filter = ref.read(auditLogFilterProvider);
    ref.read(auditLogFilterProvider.notifier).state = filter.copyWith(
      clearFrom: true,
      clearTo: true,
      page: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(auditLogsProvider);
    final filter = ref.watch(auditLogFilterProvider);
    final dateFormat = DateFormat('d MMM yyyy, h:mm a');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Logs'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(auditLogsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by action (e.g. fee_updated)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(auditLogFilterProvider.notifier).state =
                                  filter.copyWith(
                                      clearAction: true, page: 0);
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onSubmitted: (value) {
                    ref.read(auditLogFilterProvider.notifier).state =
                        filter.copyWith(action: value, page: 0);
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: filter.entityType,
                        decoration: InputDecoration(
                          labelText: 'Entity Type',
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ..._entityTypeOptions.map(
                            (type) => DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            ),
                          ),
                        ],
                        onChanged: (val) {
                          ref.read(auditLogFilterProvider.notifier).state =
                              filter.copyWith(
                            entityType: val,
                            clearEntityType: val == null,
                            page: 0,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.date_range_rounded, size: 18),
                        label: Text(
                          filter.from != null && filter.to != null
                              ? '${DateFormat('d MMM').format(filter.from!)} - ${DateFormat('d MMM').format(filter.to!)}'
                              : 'Date Range',
                          overflow: TextOverflow.ellipsis,
                        ),
                        onPressed: _pickDateRange,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    if (filter.from != null || filter.to != null)
                      IconButton(
                        tooltip: 'Clear date range',
                        icon: const Icon(Icons.close_rounded, size: 18),
                        onPressed: _clearDateRange,
                      ),
                  ],
                ),
              ],
            ),
          ),
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
                      const Icon(Icons.error_outline_rounded,
                          size: 40, color: AppColors.maroon),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load audit logs.\n$err',
                        textAlign: TextAlign.center,
                        style: AppTypography.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(auditLogsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return RefreshIndicator(
                    onRefresh: () async => ref.invalidate(auditLogsProvider),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        const SizedBox(height: 120),
                        Center(
                          child: Column(
                            children: [
                              const Icon(Icons.fact_check_outlined,
                                  size: 48, color: AppColors.lightOutline),
                              const SizedBox(height: 12),
                              Text(
                                'No audit log entries found.',
                                style: AppTypography.poppins(
                                  fontSize: 14,
                                  color: AppColors.lightOutline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(auditLogsProvider),
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return _AuditLogCard(
                        log: log,
                        dateFormat: dateFormat,
                        onTap: () => _showDetail(context, log),
                      );
                    },
                  ),
                );
              },
            ),
          ),
          if (filter.page > 0 || ((logsAsync.value?.length ?? 0) >= 25))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Previous'),
                    onPressed: filter.page > 0
                        ? () => ref.read(auditLogFilterProvider.notifier).state =
                            filter.copyWith(page: filter.page - 1)
                        : null,
                  ),
                  Text('Page ${filter.page + 1}',
                      style: AppTypography.poppins(fontSize: 12)),
                  TextButton.icon(
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                    onPressed: (logsAsync.value?.length ?? 0) >= 25
                        ? () => ref.read(auditLogFilterProvider.notifier).state =
                            filter.copyWith(page: filter.page + 1)
                        : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showDetail(BuildContext context, Map<String, dynamic> log) {
    const encoder = JsonEncoder.withIndent('  ');
    final oldValue = log['old_value'];
    final newValue = log['new_value'];
    final oldPretty = oldValue != null ? encoder.convert(oldValue) : 'null';
    final newPretty = newValue != null ? encoder.convert(newValue) : 'null';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: ListView(
                controller: scrollController,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: AppColors.lightOutline,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Text(
                    log['action']?.toString() ?? 'Audit Entry',
                    style: AppTypography.cinzel(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Entity: ${log['entity_type'] ?? '-'}  (${log['entity_id'] ?? '-'})',
                    style: AppTypography.poppins(
                        fontSize: 12, color: AppColors.lightOutline),
                  ),
                  const SizedBox(height: 16),
                  Text('Old Value',
                      style: AppTypography.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _JsonBox(text: oldPretty),
                  const SizedBox(height: 16),
                  Text('New Value',
                      style: AppTypography.poppins(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  _JsonBox(text: newPretty),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _AuditLogCard extends ConsumerWidget {
  const _AuditLogCard({
    required this.log,
    required this.dateFormat,
    required this.onTap,
  });

  final Map<String, dynamic> log;
  final DateFormat dateFormat;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = DateTime.tryParse(log['created_at']?.toString() ?? '');
    final performedBy = log['performed_by']?.toString();
    final performedByAsync = performedBy != null
        ? ref.watch(performedByNameProvider(performedBy))
        : const AsyncValue<String>.data('-');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: AppColors.gold.withValues(alpha: 0.15),
          foregroundColor: AppColors.goldDark,
          child: const Icon(Icons.history_rounded),
        ),
        title: Text(
          log['action']?.toString() ?? '-',
          style: AppTypography.poppins(fontWeight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${log['entity_type'] ?? 'unknown'} • ${log['entity_id'] ?? '-'}',
              style: AppTypography.poppins(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              'By: ${performedByAsync.value ?? performedBy ?? '-'}',
              style: AppTypography.poppins(
                  fontSize: 11, color: AppColors.lightOutline),
            ),
            if (createdAt != null) ...[
              const SizedBox(height: 2),
              Text(
                dateFormat.format(createdAt),
                style: AppTypography.poppins(
                    fontSize: 11, color: AppColors.lightOutline),
              ),
            ],
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _JsonBox extends StatelessWidget {
  const _JsonBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SelectableText(
        text,
        style: AppTypography.poppins(fontSize: 12).copyWith(
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
