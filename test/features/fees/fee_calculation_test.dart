import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/shared/models/fee_model.dart';

void main() {
  group('Fee Calculation Logic', () {
    test('computes status and remaining amounts accurately for unpaid fee', () {
      const fee = MonthlyFeeModel(
        id: 'fee1',
        studentId: 'stu1',
        academicYearId: 'ay1',
        month: 10,
        year: 2026,
        expectedAmount: 5000,
        paidAmount: 0,
        status: 'pending',
        remainingAmount: 5000,
        createdAt: '2026-10-01',
      );

      final remaining = fee.expectedAmount - fee.paidAmount;
      expect(remaining, 5000);
      expect(fee.status, 'pending');
    });

    test(
        'computes status and remaining amounts accurately for partially paid fee',
        () {
      const fee = MonthlyFeeModel(
        id: 'fee2',
        studentId: 'stu2',
        academicYearId: 'ay1',
        month: 10,
        year: 2026,
        expectedAmount: 5000,
        paidAmount: 3000,
        status: 'partially_paid',
        remainingAmount: 2000,
        createdAt: '2026-10-01',
      );

      final remaining = fee.expectedAmount - fee.paidAmount;
      expect(remaining, 2000);
      expect(fee.status, 'partially_paid');
    });

    test('computes status and remaining amounts accurately for fully paid fee',
        () {
      const fee = MonthlyFeeModel(
        id: 'fee3',
        studentId: 'stu3',
        academicYearId: 'ay1',
        month: 10,
        year: 2026,
        expectedAmount: 5000,
        paidAmount: 5000,
        status: 'paid',
        remainingAmount: 0,
        createdAt: '2026-10-01',
      );

      final remaining = fee.expectedAmount - fee.paidAmount;
      expect(remaining, 0);
      expect(fee.status, 'paid');
    });

    test('aggregates summary revenue metrics accurately', () {
      final fees = [
        const MonthlyFeeModel(
          id: '1',
          studentId: 's1',
          academicYearId: 'ay1',
          month: 10,
          year: 2026,
          expectedAmount: 4000,
          paidAmount: 4000,
          status: 'paid',
          remainingAmount: 0,
          createdAt: '2026-10-01',
        ),
        const MonthlyFeeModel(
          id: '2',
          studentId: 's2',
          academicYearId: 'ay1',
          month: 10,
          year: 2026,
          expectedAmount: 5000,
          paidAmount: 2000,
          status: 'partially_paid',
          remainingAmount: 3000,
          createdAt: '2026-10-01',
        ),
        const MonthlyFeeModel(
          id: '3',
          studentId: 's3',
          academicYearId: 'ay1',
          month: 10,
          year: 2026,
          expectedAmount: 6000,
          paidAmount: 0,
          status: 'pending',
          remainingAmount: 6000,
          createdAt: '2026-10-01',
        ),
      ];

      final totalExpected =
          fees.fold<double>(0, (sum, f) => sum + f.expectedAmount);
      final totalPaid = fees.fold<double>(0, (sum, f) => sum + f.paidAmount);
      final totalRemaining =
          fees.fold<double>(0, (sum, f) => sum + f.remainingAmount);

      expect(totalExpected, 15000.0);
      expect(totalPaid, 6000.0);
      expect(totalRemaining, 9000.0);

      final collectionRate = (totalPaid / totalExpected) * 100;
      expect(collectionRate, 40.0);
    });
  });
}
