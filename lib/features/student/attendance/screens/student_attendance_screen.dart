import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../attendance/providers/attendance_providers.dart';

class StudentAttendanceScreen extends ConsumerWidget {
  const StudentAttendanceScreen({super.key});

  Future<void> _pickMonth(BuildContext context, WidgetRef ref) async {
    final current = ref.read(studentAttendanceMonthProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(current.year - 3),
      lastDate: DateTime.now(),
      helpText: 'Select month',
    );
    if (picked != null) {
      ref.read(studentAttendanceMonthProvider.notifier).state =
          DateTime(picked.year, picked.month);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Attendance')),
        body: const Center(child: Text('User session not found')),
      );
    }

    final historyAsync = ref.watch(studentAttendanceHistoryProvider(user.id));
    final selectedMonth = ref.watch(studentAttendanceMonthProvider);
    final monthLabel = DateFormat('MMMM yyyy').format(selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance'),
        actions: [
          IconButton(
            tooltip: 'Pick month',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _pickMonth(context, ref),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () =>
                ref.invalidate(studentAttendanceHistoryProvider(user.id)),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          final totalDays = records.length;
          final presentDays = records.where((r) => r.status == 'present').length;
          final absentDays = records.where((r) => r.status == 'absent').length;
          final percentage = totalDays > 0
              ? (presentDays / totalDays * 100).toStringAsFixed(1)
              : '0.0';

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: OutlinedButton.icon(
                  onPressed: () => _pickMonth(context, ref),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(monthLabel),
                ),
              ),
              // Summary Cards
              Container(
                padding: const EdgeInsets.all(16.0),
                color: AppColors.primary.withValues(alpha: 0.05),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Attendance',
                            value: '$percentage%',
                            color: double.parse(percentage) >= 75 ? Colors.green : Colors.orange,
                            icon: Icons.pie_chart,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Present Days',
                            value: '$presentDays / $totalDays',
                            color: Colors.green,
                            icon: Icons.check_circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryCard(
                            title: 'Absent Days',
                            value: '$absentDays',
                            color: Colors.red,
                            icon: Icons.cancel,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Attendance History List
              Expanded(
                child: records.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.event_busy_outlined, size: 48, color: AppColors.lightOutline),
                              const SizedBox(height: 12),
                              Text(
                                'No attendance records found yet.',
                                textAlign: TextAlign.center,
                                style: AppTypography.poppins(fontSize: 14, color: AppColors.lightOutline),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => ref.invalidate(studentAttendanceHistoryProvider(user.id)),
                        child: ListView.builder(
                        padding: const EdgeInsets.all(16.0),
                        itemCount: records.length,
                        itemBuilder: (context, index) {
                          final item = records[index];
                          final isPresent = item.status == 'present';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                child: Icon(
                                  isPresent ? Icons.check : Icons.close,
                                  color: isPresent ? Colors.green : Colors.red,
                                ),
                              ),
                              title: Text(
                                item.date,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: item.absenceReason != null
                                  ? Text('Reason: ${item.absenceReason!.reason.toUpperCase()}')
                                  : null,
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isPresent ? Colors.green : Colors.red).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: isPresent ? Colors.green : Colors.red),
                                ),
                                child: Text(
                                  item.status.toUpperCase(),
                                  style: TextStyle(
                                    color: isPresent ? Colors.green : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                        ),
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline_rounded, size: 40, color: AppColors.maroon),
                const SizedBox(height: 12),
                Text(
                  'Could not load attendance.\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(studentAttendanceHistoryProvider(user.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withValues(alpha: 0.1),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
