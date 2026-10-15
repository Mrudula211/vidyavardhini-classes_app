import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/models/teacher_salary_model.dart';
import '../../../auth/providers/auth_providers.dart';
import '../providers/teacher_salary_providers.dart';

class TeacherSalaryScreen extends ConsumerWidget {
  const TeacherSalaryScreen({super.key});

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Salary & Earnings')),
        body: const Center(child: Text('User session missing')),
      );
    }

    final salaryHistoryAsync =
        ref.watch(teacherSalaryHistoryProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Salary & Earnings'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () =>
                ref.invalidate(teacherSalaryHistoryProvider(user.id)),
          ),
        ],
      ),
      body: salaryHistoryAsync.when(
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
                  'Could not load salary records.\n$err',
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () =>
                      ref.invalidate(teacherSalaryHistoryProvider(user.id)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (records) {
          if (records.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(teacherSalaryHistoryProvider(user.id)),
              child: ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_outlined,
                                size: 48, color: AppColors.lightOutline,),
                            const SizedBox(height: 12),
                            Text(
                              'No salary records yet.',
                              style: AppTypography.poppins(
                                fontSize: 14,
                                color: AppColors.lightOutline,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final currentRecord = records.first;
          final history = records.skip(1).toList();

          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(teacherSalaryHistoryProvider(user.id)),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildCurrentSalaryCard(currentRecord),
                const SizedBox(height: 24),
                Text(
                  'Salary History',
                  style: AppTypography.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                if (history.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Text(
                      'No earlier records found.',
                      style: AppTypography.poppins(
                        fontSize: 13,
                        color: AppColors.lightOutline,
                      ),
                    ),
                  )
                else
                  ...history.map(_buildHistoryCard),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentSalaryCard(TeacherSalaryModel record) {
    final statusColor = _statusColor(record.status);
    final monthLabel = '${_months[record.month - 1]} ${record.year}';

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.primaryVariant],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$monthLabel Earnings',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    record.status.toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Earned Salary',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              '₹${record.earnedSalary.toStringAsFixed(0)}',
              style: const TextStyle(
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _summaryColumn('Base Salary',
                    '₹${record.monthlySalary.toStringAsFixed(0)}',),
                _summaryColumn(
                    'Present Days', '${record.presentDays}/${record.workingDays}',),
                _summaryColumn('Absent Days', '${record.absentDays}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value,
            style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold,),),
      ],
    );
  }

  Widget _buildHistoryCard(TeacherSalaryModel record) {
    final statusColor = _statusColor(record.status);
    final monthLabel = '${_months[record.month - 1]} ${record.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.1),
          child: Icon(
            record.isPaid ? Icons.check_circle : Icons.pending,
            color: statusColor,
          ),
        ),
        title: Text(
          monthLabel,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Present: ${record.presentDays}/${record.workingDays} days',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '₹${record.earnedSalary.toStringAsFixed(0)}',
              style: TextStyle(fontWeight: FontWeight.bold, color: statusColor),
            ),
            Text(
              record.status.toUpperCase(),
              style: TextStyle(fontSize: 10, color: statusColor),
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'paid':
        return AppColors.statusPaid;
      default:
        // 'pending' status renders as amber per salary chip convention.
        return AppColors.statusPartial;
    }
  }
}
