import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../fees/providers/fee_providers.dart';

class RevenueScreen extends ConsumerWidget {
  const RevenueScreen({super.key});

  final List<String> _months = const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedYear = ref.watch(selectedFeeYearProvider);
    final revenueAsync = ref.watch(annualRevenueAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Revenue & Fee Analytics'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(annualRevenueAnalyticsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Year Selector
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial Analytics Year',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                DropdownButton<int>(
                  value: selectedYear,
                  items: const [
                    DropdownMenuItem(value: 2025, child: Text('2025')),
                    DropdownMenuItem(value: 2026, child: Text('2026')),
                    DropdownMenuItem(value: 2027, child: Text('2027')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(selectedFeeYearProvider.notifier).state = val;
                    }
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: revenueAsync.when(
              data: (data) {
                final double totalExp = data['totalExpected'] ?? 0.0;
                final double totalColl = data['totalCollected'] ?? 0.0;
                final double totalPend = data['totalPending'] ?? 0.0;
                final Map<int, Map<String, double>> monthlyMap =
                    data['monthlyBreakdown'] ?? {};

                final overallRate = totalExp > 0
                    ? (totalColl / totalExp * 100).toStringAsFixed(1)
                    : '0.0';

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Annual Summary Banner
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.primaryVariant
                              ],
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Annual Collections ($selectedYear)',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '$overallRate% Collected',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Expected Revenue',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      Text('₹${totalExp.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Total Collected',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      Text('₹${totalColl.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: Colors.greenAccent,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text('Pending Balance',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 12)),
                                      Text('₹${totalPend.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              color: Colors.orangeAccent,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'Monthly Revenue Breakdown',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: 12,
                        itemBuilder: (context, index) {
                          final mIndex = index + 1;
                          final mData = monthlyMap[mIndex] ??
                              {
                                'expected': 0.0,
                                'collected': 0.0,
                                'pending': 0.0
                              };
                          final exp = mData['expected'] ?? 0.0;
                          final coll = mData['collected'] ?? 0.0;
                          final pend = mData['pending'] ?? 0.0;
                          final ratio =
                              exp > 0 ? (coll / exp).clamp(0.0, 1.0) : 0.0;

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _months[index],
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      Text(
                                        '₹${coll.toStringAsFixed(0)} / ₹${exp.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: ratio,
                                      minHeight: 8,
                                      backgroundColor: Colors.grey.shade200,
                                      color: ratio >= 0.8
                                          ? Colors.green
                                          : (ratio >= 0.5
                                              ? Colors.orange
                                              : Colors.red),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          'Collected: ₹${coll.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.green)),
                                      Text(
                                          'Pending: ₹${pend.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                              fontSize: 11, color: Colors.red)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error loading revenue: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
