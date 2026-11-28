import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/utils/formatters.dart';

void main() {
  group('AppFormatters - formatCurrency', () {
    test('formats amounts to Indian Rupee without decimals by default', () {
      expect(AppFormatters.formatCurrency(0), '₹0');
      expect(AppFormatters.formatCurrency(500), '₹500');
      expect(AppFormatters.formatCurrency(15000), '₹15,000');
      expect(AppFormatters.formatCurrency(125000), '₹1,25,000');
    });

    test('formats amounts with decimals when requested', () {
      expect(
        AppFormatters.formatCurrency(1500.5, showDecimals: true),
        '₹1,500.50',
      );
      expect(AppFormatters.formatCurrency(0, showDecimals: true), '₹0.00');
    });
  });

  group('AppFormatters - formatDate', () {
    test('formats dates with default pattern dd MMM yyyy', () {
      final date = DateTime(2026, 10, 15);
      expect(AppFormatters.formatDate(date), '15 Oct 2026');
    });

    test('formats dates with custom pattern', () {
      final date = DateTime(2026, 1, 5);
      expect(
        AppFormatters.formatDate(date, pattern: 'yyyy-MM-dd'),
        '2026-01-05',
      );
      expect(
        AppFormatters.formatDate(date, pattern: 'MMMM yyyy'),
        'January 2026',
      );
    });
  });

  group('AppFormatters - formatMonthYear', () {
    test('formats month index and year into text label', () {
      expect(AppFormatters.formatMonthYear(1, 2026), 'January 2026');
      expect(AppFormatters.formatMonthYear(10, 2026), 'October 2026');
      expect(AppFormatters.formatMonthYear(12, 2026), 'December 2026');
    });

    test('handles out of range month gracefully', () {
      expect(AppFormatters.formatMonthYear(13, 2026), '13/2026');
      expect(AppFormatters.formatMonthYear(0, 2026), '0/2026');
    });
  });

  group('AppFormatters - formatPhoneNumber', () {
    test('formats 10-digit Indian phone numbers with spacing', () {
      expect(AppFormatters.formatPhoneNumber('9876543210'), '98765 43210');
    });

    test('formats 13-digit numbers with country code', () {
      expect(
        AppFormatters.formatPhoneNumber('+919876543210'),
        '+91 98765 43210',
      );
    });

    test('returns non-standard numbers as-is', () {
      expect(AppFormatters.formatPhoneNumber('12345'), '12345');
    });
  });

  group('AppFormatters - formatPercentage', () {
    test('formats whole numbers without decimal point', () {
      expect(AppFormatters.formatPercentage(100.0), '100%');
      expect(AppFormatters.formatPercentage(0.0), '0%');
      expect(AppFormatters.formatPercentage(75.0), '75%');
    });

    test('formats fractional percentages with decimals', () {
      expect(AppFormatters.formatPercentage(85.55, decimalPlaces: 1), '85.5%');
      expect(
        AppFormatters.formatPercentage(66.666, decimalPlaces: 2),
        '66.67%',
      );
    });
  });

  group('AppFormatters - formatStudentId & formatTeacherId', () {
    test('generates padded Student ID', () {
      expect(AppFormatters.formatStudentId(1, year: 2026), 'STU20260001');
      expect(AppFormatters.formatStudentId(42, year: 2026), 'STU20260042');
      expect(AppFormatters.formatStudentId(1234, year: 2026), 'STU20261234');
    });

    test('generates padded Teacher ID', () {
      expect(AppFormatters.formatTeacherId(1), 'TCH0001');
      expect(AppFormatters.formatTeacherId(25), 'TCH0025');
    });
  });
}
