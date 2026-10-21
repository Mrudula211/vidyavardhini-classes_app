import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/providers/auth_providers.dart';
import '../../../fees/providers/fee_providers.dart';
import '../../../../l10n/l10n_context.dart';

class StudentFeesScreen extends ConsumerWidget {
  const StudentFeesScreen({super.key});

  String _monthName(BuildContext context, int month) {
    return DateFormat.MMMM(Localizations.localeOf(context).toString())
        .format(DateTime(2000, month));
  }

  String _statusLabel(BuildContext context, String status) {
    switch (status) {
      case 'paid':
        return context.l10n.feeStatusPaid;
      case 'partially_paid':
        return context.l10n.feeStatusPartial;
      default:
        return context.l10n.feeStatusPending;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(context.l10n.feesTitle)),
        body: Center(child: Text(context.l10n.userSessionMissing)),
      );
    }

    final historyAsync = ref.watch(studentFeeHistoryProvider(user.id));

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.feesTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(studentFeeHistoryProvider(user.id)),
          ),
        ],
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.receipt_long_outlined, size: 48, color: AppColors.lightOutline),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.noFeeRecords,
                      textAlign: TextAlign.center,
                      style: AppTypography.poppins(fontSize: 14, color: AppColors.lightOutline),
                    ),
                  ],
                ),
              ),
            );
          }

          final currentMonthRecord = records.first;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(studentFeeHistoryProvider(user.id)),
            child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Prominent Current Month Card
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
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_monthName(context, currentMonthRecord.month)} ${currentMonthRecord.year}',
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(currentMonthRecord.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                _statusLabel(context, currentMonthRecord.status),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.expectedFee, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('₹${currentMonthRecord.expectedAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.paidAmount, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('₹${currentMonthRecord.paidAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.greenAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(context.l10n.remainingAmount, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                                Text('₹${currentMonthRecord.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.orangeAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  context.l10n.feeHistory,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final item = records[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(item.status).withValues(alpha: 0.1),
                          child: Icon(
                            item.status == 'paid' ? Icons.check_circle : Icons.pending,
                            color: _getStatusColor(item.status),
                          ),
                        ),
                        title: Text(
                          '${_monthName(context, item.month)} ${item.year}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          context.l10n.feeExpectedPaid(
                            item.expectedAmount.toStringAsFixed(0),
                            item.paidAmount.toStringAsFixed(0),
                          ),
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        trailing: Text(
                          context.l10n.feeRemainingShort(item.remainingAmount.toStringAsFixed(0)),
                          textAlign: TextAlign.right,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: item.remainingAmount > 0 ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            ),
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
                  context.l10n.couldNotLoadFees,
                  textAlign: TextAlign.center,
                  style: AppTypography.poppins(fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => ref.invalidate(studentFeeHistoryProvider(user.id)),
                  child: Text(context.l10n.retry),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'paid':
        return Colors.green;
      case 'partially_paid':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}
