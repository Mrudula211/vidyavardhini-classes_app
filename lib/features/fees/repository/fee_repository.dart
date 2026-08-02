import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../shared/models/fee_model.dart';

class FeeRepository {
  final SupabaseClient _client = Supabase.instance.client;

  Future<List<MonthlyFeeModel>> fetchAdminFeeOverview({
    int? month,
    int? year,
    String? status,
    String? searchQuery,
  }) async {
    dynamic query = _client.from('monthly_fees').select('*, student_profiles!inner(*)');

    if (month != null) {
      query = query.eq('month', month);
    }
    if (year != null) {
      query = query.eq('year', year);
    }
    if (status != null && status.isNotEmpty && status != 'all') {
      query = query.eq('status', status);
    }
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = '%${searchQuery.trim()}%';
      query = query.or('student_profiles.full_name.ilike.$q,student_profiles.student_id.ilike.$q');
    }

    final data = await query.order('created_at', ascending: false);
    return (data as List).map((json) => MonthlyFeeModel.fromJson(json)).toList();
  }

  Future<void> recordFeePayment({
    required String monthlyFeeId,
    required double amount,
    required String paymentMethod,
    required String paymentDate,
    String? referenceNumber,
    String? notes,
    required String collectedBy,
  }) async {
    // 1. Insert fee_payments record
    await _client.from('fee_payments').insert({
      'monthly_fee_id': monthlyFeeId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'reference_number': referenceNumber,
      'notes': notes,
      'collected_by': collectedBy,
    });

    // 2. Update paid_amount in monthly_fees
    final monthlyFeeRes = await _client
        .from('monthly_fees')
        .select('paid_amount')
        .eq('id', monthlyFeeId)
        .single();

    final currentPaid = (monthlyFeeRes['paid_amount'] as num?)?.toDouble() ?? 0.0;
    final newPaid = currentPaid + amount;

    await _client.from('monthly_fees').update({
      'paid_amount': newPaid,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', monthlyFeeId);
  }

  Future<List<MonthlyFeeModel>> fetchStudentFeeHistory({
    required String studentId,
  }) async {
    final data = await _client
        .from('monthly_fees')
        .select('*, student_profiles(*)')
        .eq('student_id', studentId)
        .order('year', ascending: false)
        .order('month', ascending: false);

    return (data as List).map((json) => MonthlyFeeModel.fromJson(json)).toList();
  }

  Future<List<FeePaymentModel>> fetchFeePayments(String monthlyFeeId) async {
    final data = await _client
        .from('fee_payments')
        .select()
        .eq('monthly_fee_id', monthlyFeeId)
        .order('payment_date', ascending: false);

    return (data as List).map((json) => FeePaymentModel.fromJson(json)).toList();
  }

  Future<int> generateMonthlyFees({
    required int month,
    required int year,
  }) async {
    // Fetch active academic year
    final currentYearRes = await _client
        .from('academic_years')
        .select('id')
        .eq('is_current', true)
        .maybeSingle();

    final academicYearId = currentYearRes != null ? currentYearRes['id'] as String? : null;
    if (academicYearId == null) return 0;

    // Fetch active fee structures
    final structures = await _client
        .from('fee_structure')
        .select('student_id, monthly_fee, student_profiles!inner(status)')
        .eq('academic_year_id', academicYearId)
        .eq('student_profiles.status', 'active');

    int generatedCount = 0;

    for (final row in structures as List) {
      final studentId = row['student_id'] as String;
      final expectedAmount = (row['monthly_fee'] as num?)?.toDouble() ?? 0.0;

      final existing = await _client
          .from('monthly_fees')
          .select('id')
          .eq('student_id', studentId)
          .eq('month', month)
          .eq('year', year)
          .maybeSingle();

      if (existing == null) {
        await _client.from('monthly_fees').insert({
          'student_id': studentId,
          'academic_year_id': academicYearId,
          'month': month,
          'year': year,
          'expected_amount': expectedAmount,
          'paid_amount': 0.0,
          'status': 'pending',
        });
        generatedCount++;
      }
    }

    return generatedCount;
  }
}
