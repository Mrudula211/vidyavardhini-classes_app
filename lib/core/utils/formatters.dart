import 'package:intl/intl.dart';

/// Formatting utility functions for consistent presentation across the app.
class AppFormatters {
  AppFormatters._();

  static const List<String> months = [
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
    'December',
  ];

  /// Formats numeric currency to Indian Rupee representation (e.g. ₹15,000 or ₹0).
  static String formatCurrency(num amount, {bool showDecimals = false}) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹',
      decimalDigits: showDecimals ? 2 : 0,
    );
    return formatter.format(amount);
  }

  /// Formats date to a standard readable string (e.g. 15 Oct 2026).
  static String formatDate(DateTime date, {String pattern = 'dd MMM yyyy'}) {
    return DateFormat(pattern).format(date);
  }

  /// Formats month index (1-12) and year into a label (e.g. October 2026).
  static String formatMonthYear(int month, int year) {
    if (month >= 1 && month <= 12) {
      return '${months[month - 1]} $year';
    }
    return '$month/$year';
  }

  /// Formats a phone number with spacing for display (e.g. +91 98765 43210).
  static String formatPhoneNumber(String phone) {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    if (clean.startsWith('+91') && clean.length == 13) {
      final country = clean.substring(0, 3);
      final part1 = clean.substring(3, 8);
      final part2 = clean.substring(8);
      return '$country $part1 $part2';
    }
    if (clean.length == 10) {
      final part1 = clean.substring(0, 5);
      final part2 = clean.substring(5);
      return '$part1 $part2';
    }
    return phone;
  }

  /// Formats percentage value (e.g. 85.5% or 100%).
  static String formatPercentage(double value, {int decimalPlaces = 1}) {
    if (value % 1 == 0) {
      return '${value.toInt()}%';
    }
    return '${value.toStringAsFixed(decimalPlaces)}%';
  }

  /// Generates a standardized Student ID string (e.g. STU20260001).
  static String formatStudentId(int seqNumber, {int? year}) {
    final currentYear = year ?? DateTime.now().year;
    final padded = seqNumber.toString().padLeft(4, '0');
    return 'STU$currentYear$padded';
  }

  /// Generates a standardized Teacher ID string (e.g. TCH0001).
  static String formatTeacherId(int seqNumber) {
    final padded = seqNumber.toString().padLeft(4, '0');
    return 'TCH$padded';
  }
}
