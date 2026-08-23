import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/models/fee_model.dart';
import '../../../fees/providers/fee_providers.dart';
import '../widgets/add_payment_sheet.dart';

class FeeOverviewScreen extends ConsumerStatefulWidget {
  const FeeOverviewScreen({super.key});

  @override
  ConsumerState<FeeOverviewScreen> createState() => _FeeOverviewScreenState();
}

class _FeeOverviewScreenState extends ConsumerState<FeeOverviewScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isGenerating = false;

  final List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _generateMonthlyFees() async {
    final month = ref.read(selectedFeeMonthProvider);
    final year = ref.read(selectedFeeYearProvider);

    setState(() => _isGenerating = true);
    try {
      final count = await ref.read(feeRepositoryProvider).generateMonthlyFees(
            month: month,
            year: year,
          );

      ref.invalidate(adminFeeOverviewProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(count > 0
                ? 'Generated $count fee records for ${_months[month - 1]} $year!'
                : 'Fee records already exist for active students.'),
            backgroundColor: count > 0 ? Colors.green : Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate fees: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedMonth = ref.watch(selectedFeeMonthProvider);
    final selectedYear = ref.watch(selectedFeeYearProvider);
    final selectedStatus = ref.watch(selectedFeeStatusFilterProvider);
    final feeOverviewAsync = ref.watch(adminFeeOverviewProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fee Register & Collections'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminFeeOverviewProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter & Header Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Month & Year Selector
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<int>(
                        value: selectedMonth,
                        decoration: const InputDecoration(labelText: 'Month', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: List.generate(12, (index) {
                          return DropdownMenuItem(
                            value: index + 1,
                            child: Text(_months[index]),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) ref.read(selectedFeeMonthProvider.notifier).state = val;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<int>(
                        value: selectedYear,
                        decoration: const InputDecoration(labelText: 'Year', contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                        items: const [
                          DropdownMenuItem(value: 2025, child: Text('2025')),
                          DropdownMenuItem(value: 2026, child: Text('2026')),
                          DropdownMenuItem(value: 2027, child: Text('2027')),
                        ],
                        onChanged: (val) {
                          if (val != null) ref.read(selectedFeeYearProvider.notifier).state = val;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Search Bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by student name or STU ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref.read(feeSearchQueryProvider.notifier).state = '';
                            },
                          )
                        : null,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) {
                    ref.read(feeSearchQueryProvider.notifier).state = val;
                  },
                ),
                const SizedBox(height: 12),

                // Status Filter Chips & Generate Button
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('all', 'All'),
                            _buildFilterChip('pending', 'Pending'),
                            _buildFilterChip('partially_paid', 'Partial'),
                            _buildFilterChip('paid', 'Paid'),
                          ],
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                      onPressed: _isGenerating ? null : _generateMonthlyFees,
                      icon: _isGenerating
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.autorenew, size: 18),
                      label: const Text('Generate'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Overview Stats & List
          Expanded(
            child: feeOverviewAsync.when(
              data: (feeList) {
                final totalExpected = feeList.fold<double>(0, (sum, f) => sum + f.expectedAmount);
                final totalPaid = feeList.fold<double>(0, (sum, f) => sum + f.paidAmount);
                final totalPending = feeList.fold<double>(0, (sum, f) => sum + f.remainingAmount);

                return Column(
                  children: [
                    // Summary Banner
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          Expanded(child: _buildSummaryCard('Expected', '₹${totalExpected.toStringAsFixed(0)}', Colors.blue)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('Collected', '₹${totalPaid.toStringAsFixed(0)}', Colors.green)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildSummaryCard('Pending', '₹${totalPending.toStringAsFixed(0)}', Colors.red)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Student Fee List
                    Expanded(
                      child: feeList.isEmpty
                          ? const Center(
                              child: Text('No fee records for this period.\nTap "Generate" to create monthly fee records.'),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              itemCount: feeList.length,
                              itemBuilder: (context, index) {
                                final item = feeList[index];
                                return _buildFeeCard(context, item);
                              },
                            ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error loading fee overview: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final selectedStatus = ref.watch(selectedFeeStatusFilterProvider);
    final isSelected = selectedStatus == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        selectedColor: AppColors.primary.withOpacity(0.2),
        checkmarkColor: AppColors.primary,
        onSelected: (selected) {
          ref.read(selectedFeeStatusFilterProvider.notifier).state = value;
        },
      ),
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildFeeCard(BuildContext context, MonthlyFeeModel item) {
    Color statusColor;
    switch (item.status) {
      case 'paid':
        statusColor = Colors.green;
        break;
      case 'partially_paid':
        statusColor = Colors.orange;
        break;
      default:
        statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    item.studentName != null && item.studentName!.isNotEmpty ? item.studentName![0].toUpperCase() : 'S',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.studentName ?? 'Student',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        '${item.studentIdCode ?? "STU0000"} • ${item.board ?? ""} Standard ${item.standard ?? ""}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    item.status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const Divider(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Expected: ₹${item.expectedAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12)),
                    Text('Paid: ₹${item.paidAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                    Text('Remaining: ₹${item.remainingAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (item.status != 'paid')
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Record Payment'),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                        ),
                        builder: (ctx) => AddPaymentSheet(monthlyFee: item),
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
