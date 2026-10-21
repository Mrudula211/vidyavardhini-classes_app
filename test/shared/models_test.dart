import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/features/admin/backup/screens/backup_screen.dart';
import 'package:vidyavardhini_classes/shared/models/attendance_model.dart';
import 'package:vidyavardhini_classes/shared/models/fee_model.dart';

void main() {
  group('formatBytes', () {
    test('handles null and non-positive', () {
      expect(formatBytes(null), '--');
      expect(formatBytes(0), '0 B');
      expect(formatBytes(-5), '0 B');
    });

    test('scales units', () {
      expect(formatBytes(512), '512 B');
      expect(formatBytes(1024), '1.0 KB');
      expect(formatBytes(12400000), '11.8 MB');
    });
  });

  group('MonthlyFeeModel.fromJson', () {
    test('parses amounts and joined student profile', () {
      final fee = MonthlyFeeModel.fromJson({
        'id': 'f1',
        'student_id': 's1',
        'academic_year_id': 'y1',
        'month': 4,
        'year': 2026,
        'expected_amount': 1500,
        'paid_amount': 500.5,
        'remaining_amount': 999.5,
        'status': 'partially_paid',
        'created_at': '2026-04-01',
        'student_profiles': {
          'full_name': 'Asha',
          'student_id': 'STU0001',
          'parent_phone': '9999999999',
          'board': 'SSC',
          'standard': '8th',
        },
      });
      expect(fee.expectedAmount, 1500.0);
      expect(fee.paidAmount, 500.5);
      expect(fee.remainingAmount, 999.5);
      expect(fee.studentName, 'Asha');
      expect(fee.studentIdCode, 'STU0001');
    });

    test('falls back to safe defaults on missing fields', () {
      final fee = MonthlyFeeModel.fromJson({'id': 'f1'});
      expect(fee.status, 'pending');
      expect(fee.expectedAmount, 0.0);
      expect(fee.studentName, isNull);
    });
  });

  group('FeePaymentModel.fromJson', () {
    test('defaults payment method to cash', () {
      final p = FeePaymentModel.fromJson({'id': 'p1', 'amount': 250});
      expect(p.amount, 250.0);
      expect(p.paymentMethod, 'cash');
    });
  });

  group('StudentAttendanceModel.fromJson', () {
    test('defaults status to absent and tolerates no reason', () {
      final a = StudentAttendanceModel.fromJson({'id': 'a1'});
      expect(a.status, 'absent');
      expect(a.absenceReason, isNull);
    });
  });
}
