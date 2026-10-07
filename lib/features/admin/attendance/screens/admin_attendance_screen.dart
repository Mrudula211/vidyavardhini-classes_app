import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../attendance/providers/attendance_providers.dart';

class AdminAttendanceScreen extends ConsumerWidget {
  const AdminAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedAttendanceDateProvider);
    final selectedBoard = ref.watch(selectedAttendanceBoardProvider);
    final selectedStandard = ref.watch(selectedAttendanceStandardProvider);
    final overviewAsync = ref.watch(adminAttendanceOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Overview'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminAttendanceOverviewProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today),
                        label: Text('Date: $selectedDate'),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.parse(selectedDate),
                            firstDate: DateTime(2025),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) {
                            ref.read(selectedAttendanceDateProvider.notifier).state =
                                picked.toIso8601String().split('T').first;
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedBoard,
                        decoration: const InputDecoration(labelText: 'Board'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Boards')),
                          DropdownMenuItem(value: 'SSC', child: Text('SSC')),
                          DropdownMenuItem(value: 'CBSE', child: Text('CBSE')),
                        ],
                        onChanged: (val) {
                          if (val != null) ref.read(selectedAttendanceBoardProvider.notifier).state = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: selectedStandard,
                        decoration: const InputDecoration(labelText: 'Standard'),
                        items: const [
                          DropdownMenuItem(value: 'all', child: Text('All Standards')),
                          DropdownMenuItem(value: '1st', child: Text('1st Std')),
                          DropdownMenuItem(value: '2nd', child: Text('2nd Std')),
                          DropdownMenuItem(value: '3rd', child: Text('3rd Std')),
                          DropdownMenuItem(value: '4th', child: Text('4th Std')),
                          DropdownMenuItem(value: '5th', child: Text('5th Std')),
                          DropdownMenuItem(value: '6th', child: Text('6th Std')),
                          DropdownMenuItem(value: '7th', child: Text('7th Std')),
                          DropdownMenuItem(value: '8th', child: Text('8th Std')),
                          DropdownMenuItem(value: '9th', child: Text('9th Std')),
                          DropdownMenuItem(value: '10th', child: Text('10th Std')),
                        ],
                        onChanged: (val) {
                          if (val != null) ref.read(selectedAttendanceStandardProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Overview Results
          Expanded(
            child: overviewAsync.when(
              data: (records) {
                final total = records.length;
                final present = records.where((r) => r.status == 'present').length;
                final absent = records.where((r) => r.status == 'absent').length;
                final rate = total > 0 ? (present / total * 100).toStringAsFixed(1) : '0.0';

                return Column(
                  children: [
                    // Summary Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: _buildBadgeCard('Total', '$total', Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBadgeCard('Present', '$present', Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBadgeCard('Absent', '$absent', Colors.red)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildBadgeCard('Rate', '$rate%', AppColors.primary)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Expanded(
                      child: records.isEmpty
                          ? RefreshIndicator(
                              onRefresh: () async =>
                                  ref.invalidate(adminAttendanceOverviewProvider),
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 60),
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.event_busy_outlined,
                                            size: 48,
                                            color: AppColors.lightOutline,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'No attendance recorded for this date/filter.',
                                            textAlign: TextAlign.center,
                                            style: AppTypography.poppins(
                                              fontSize: 14,
                                              color: AppColors.lightOutline,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: () async =>
                                  ref.invalidate(adminAttendanceOverviewProvider),
                              child: ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.all(16.0),
                              itemCount: records.length,
                              itemBuilder: (context, index) {
                                final r = records[index];
                                final isPresent = r.status == 'present';

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: (isPresent ? Colors.green : Colors.red).withOpacity(0.1),
                                      child: Icon(
                                        isPresent ? Icons.check : Icons.close,
                                        color: isPresent ? Colors.green : Colors.red,
                                      ),
                                    ),
                                    title: Text(r.studentName ?? 'Student', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ID: ${r.studentIdCode ?? "N/A"}'),
                                        if (r.absenceReason != null)
                                          Text('Reason: ${r.absenceReason!.reason}', style: const TextStyle(color: Colors.red, fontSize: 12)),
                                      ],
                                    ),
                                    trailing: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (isPresent ? Colors.green : Colors.red).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: isPresent ? Colors.green : Colors.red),
                                      ),
                                      child: Text(
                                        r.status.toUpperCase(),
                                        style: TextStyle(
                                          color: isPresent ? Colors.green : Colors.red,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
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
                      const Icon(Icons.error_outline_rounded,
                          size: 40, color: AppColors.maroon),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load attendance overview.\n$err',
                        textAlign: TextAlign.center,
                        style: AppTypography.poppins(fontSize: 13),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(adminAttendanceOverviewProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }
}
