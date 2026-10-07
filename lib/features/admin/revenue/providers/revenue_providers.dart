import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../fees/providers/fee_providers.dart' show selectedFeeYearProvider;
import '../repository/revenue_repository.dart';

final revenueRepositoryProvider = Provider<RevenueRepository>((ref) {
  return RevenueRepository();
});

/// Yearly revenue analytics (totals + monthly breakdown) for the year
/// currently selected in [selectedFeeYearProvider].
final yearlyRevenueProvider =
    FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(revenueRepositoryProvider);
  final year = ref.watch(selectedFeeYearProvider);
  return repo.fetchYearlyRevenue(year: year);
});

/// Revenue analytics for a single (year, month) pair.
final monthlyRevenueProvider =
    FutureProvider.family<Map<String, double>, ({int year, int month})>(
        (ref, params) async {
  final repo = ref.watch(revenueRepositoryProvider);
  return repo.fetchMonthlyRevenue(year: params.year, month: params.month);
});
