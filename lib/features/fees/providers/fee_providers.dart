import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/fee_model.dart';
import '../repository/fee_repository.dart';

final feeRepositoryProvider = Provider<FeeRepository>((ref) {
  return FeeRepository();
});

final selectedFeeMonthProvider = StateProvider<int>((ref) => DateTime.now().month);
final selectedFeeYearProvider = StateProvider<int>((ref) => DateTime.now().year);
final selectedFeeStatusFilterProvider = StateProvider<String>((ref) => 'all');
final feeSearchQueryProvider = StateProvider<String>((ref) => '');

final adminFeeOverviewProvider = FutureProvider<List<MonthlyFeeModel>>((ref) async {
  final repo = ref.watch(feeRepositoryProvider);
  final month = ref.watch(selectedFeeMonthProvider);
  final year = ref.watch(selectedFeeYearProvider);
  final status = ref.watch(selectedFeeStatusFilterProvider);
  final search = ref.watch(feeSearchQueryProvider);

  return repo.fetchAdminFeeOverview(
    month: month,
    year: year,
    status: status,
    searchQuery: search,
  );
});

final studentFeeHistoryProvider = FutureProvider.family<List<MonthlyFeeModel>, String>((ref, studentId) async {
  final repo = ref.watch(feeRepositoryProvider);
  return repo.fetchStudentFeeHistory(studentId: studentId);
});

final monthlyFeePaymentsProvider = FutureProvider.family<List<FeePaymentModel>, String>((ref, monthlyFeeId) async {
  final repo = ref.watch(feeRepositoryProvider);
  return repo.fetchFeePayments(monthlyFeeId);
});

final annualRevenueAnalyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repo = ref.watch(feeRepositoryProvider);
  final year = ref.watch(selectedFeeYearProvider);
  return repo.fetchAnnualRevenueAnalytics(year: year);
});
