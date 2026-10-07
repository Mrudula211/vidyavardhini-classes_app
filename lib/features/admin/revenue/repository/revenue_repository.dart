import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for admin revenue & fee-collection analytics.
///
/// Reads from the `monthly_fees` table (populated by the monthly fee
/// generation job, see [CLAUDE.md] business rule 8) and derives
/// expected / collected / pending totals for a given year or month.
/// This is read-only: revenue data is never written here, matching the
/// "admin-only write" business rule for fees/revenue.
class RevenueRepository {
  final SupabaseClient _client;

  RevenueRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  /// Fetches the aggregated revenue analytics for an entire [year],
  /// broken down by month (1-12).
  ///
  /// Returns a map with:
  /// - `totalExpected`  : double, sum of expected_amount for the year
  /// - `totalCollected` : double, sum of paid_amount for the year
  /// - `totalPending`   : double, sum of remaining_amount for the year
  /// - `monthlyBreakdown` : Map<int, Map<String, double>> keyed by month
  ///   (1-12), each containing `expected`, `collected`, `pending`.
  Future<Map<String, dynamic>> fetchYearlyRevenue({required int year}) async {
    final data = await _client
        .from('monthly_fees')
        .select('month, expected_amount, paid_amount, remaining_amount')
        .eq('year', year);

    double totalExpected = 0.0;
    double totalCollected = 0.0;
    double totalPending = 0.0;

    final Map<int, Map<String, double>> monthlyBreakdown = {};
    for (int i = 1; i <= 12; i++) {
      monthlyBreakdown[i] = {
        'expected': 0.0,
        'collected': 0.0,
        'pending': 0.0,
      };
    }

    for (final row in data as List) {
      final month = row['month'] as int? ?? 1;
      final exp = (row['expected_amount'] as num?)?.toDouble() ?? 0.0;
      final paid = (row['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final rem =
          (row['remaining_amount'] as num?)?.toDouble() ?? (exp - paid);

      totalExpected += exp;
      totalCollected += paid;
      totalPending += rem;

      if (monthlyBreakdown.containsKey(month)) {
        monthlyBreakdown[month]!['expected'] =
            (monthlyBreakdown[month]!['expected'] ?? 0.0) + exp;
        monthlyBreakdown[month]!['collected'] =
            (monthlyBreakdown[month]!['collected'] ?? 0.0) + paid;
        monthlyBreakdown[month]!['pending'] =
            (monthlyBreakdown[month]!['pending'] ?? 0.0) + rem;
      }
    }

    return {
      'totalExpected': totalExpected,
      'totalCollected': totalCollected,
      'totalPending': totalPending,
      'monthlyBreakdown': monthlyBreakdown,
    };
  }

  /// Fetches the aggregated revenue analytics for a single [month] of
  /// [year].
  ///
  /// Returns a map with `expected`, `collected`, `pending` double totals
  /// for that month only.
  Future<Map<String, double>> fetchMonthlyRevenue({
    required int year,
    required int month,
  }) async {
    final data = await _client
        .from('monthly_fees')
        .select('expected_amount, paid_amount, remaining_amount')
        .eq('year', year)
        .eq('month', month);

    double expected = 0.0;
    double collected = 0.0;
    double pending = 0.0;

    for (final row in data as List) {
      final exp = (row['expected_amount'] as num?)?.toDouble() ?? 0.0;
      final paid = (row['paid_amount'] as num?)?.toDouble() ?? 0.0;
      final rem =
          (row['remaining_amount'] as num?)?.toDouble() ?? (exp - paid);

      expected += exp;
      collected += paid;
      pending += rem;
    }

    return {
      'expected': expected,
      'collected': collected,
      'pending': pending,
    };
  }
}
