import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../admin/teachers/providers/teacher_providers.dart';
import '../../../auth/providers/auth_providers.dart';

class TeacherSalaryScreen extends ConsumerWidget {
  const TeacherSalaryScreen({super.key});

  final List<String> _months = const [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Salary & Earnings')),
        body: const Center(child: Text('User session missing')),
      );
    }

    final teacherDetailAsync = ref.watch(teacherDetailProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Salary & Earnings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(teacherDetailProvider(user.id)),
          ),
        ],
      ),
      body: teacherDetailAsync.when(
        data: (teacher) {
          if (teacher == null) {
            return const Center(child: Text('Teacher record not found.'));
          }

          final monthlySalary = teacher.monthlySalary ?? 0.0;
          final currentMonthName = _months[DateTime.now().month - 1];
          final currentYear = DateTime.now().year;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Salary Summary Card
                Card(
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
                              '$currentMonthName $currentYear Earnings',
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'ACTIVE PAYOUT',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Text(
                          'Base Monthly Salary',
                          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${monthlySalary.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Salary Payout Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _buildDetailRow('Teacher ID', teacher.teacherIdCode),
                        const Divider(),
                        _buildDetailRow('Full Name', teacher.fullName),
                        const Divider(),
                        _buildDetailRow('Qualification', teacher.qualification ?? 'N/A'),
                        const Divider(),
                        _buildDetailRow('Assigned Subjects', teacher.subjects.join(', ')),
                        const Divider(),
                        _buildDetailRow('Monthly Base Pay', '₹${monthlySalary.toStringAsFixed(0)}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading salary: $err')),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }
}
