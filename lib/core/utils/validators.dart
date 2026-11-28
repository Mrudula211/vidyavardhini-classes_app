/// Input validation utility functions for forms across Vidyavardhini Classes app.
class AppValidators {
  AppValidators._();

  /// Validates a 10-digit Indian phone number (without country code prefix).
  static String? validateIndianPhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter phone number';
    }
    final trimmed = value.trim().replaceAll(' ', '').replaceAll('-', '');
    final regex = RegExp(r'^[6-9]\d{9}$');
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid 10-digit mobile number';
    }
    return null;
  }

  /// Validates standard 6-digit access code / PIN.
  static String? validateAccessCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter 6-digit access code';
    }
    final trimmed = value.trim();
    if (trimmed.length != 6 || !RegExp(r'^\d{6}$').hasMatch(trimmed)) {
      return 'Access code must be exactly 6 digits';
    }
    return null;
  }

  /// Validates an optional or required email address.
  static String? validateEmail(String? value, {bool isRequired = false}) {
    if (value == null || value.trim().isEmpty) {
      if (isRequired) return 'Please enter email address';
      return null;
    }
    final trimmed = value.trim();
    final regex = RegExp(
      r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)+$',
    );
    if (!regex.hasMatch(trimmed)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  /// Validates a full name.
  static String? validateName(String? value, {String fieldName = 'Full Name'}) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    final trimmed = value.trim();
    if (trimmed.length < 2) {
      return '$fieldName must be at least 2 characters';
    }
    if (!RegExp(r"^[a-zA-Z\s.'-]+$").hasMatch(trimmed)) {
      return '$fieldName can only contain letters and spaces';
    }
    return null;
  }

  /// Validates a monetary fee amount.
  static String? validateFeeAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter fee amount';
    }
    final trimmed = value.trim().replaceAll(',', '');
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      return 'Enter a valid numeric amount';
    }
    if (parsed < 0) {
      return 'Amount cannot be negative';
    }
    if (parsed > 1000000) {
      return 'Amount exceeds maximum allowable limit';
    }
    return null;
  }

  /// Validates date of birth ensuring a minimum age requirement.
  static String? validateDob(DateTime? date, {int minimumAgeYears = 3}) {
    if (date == null) {
      return 'Please select date of birth';
    }
    final now = DateTime.now();
    if (date.isAfter(now)) {
      return 'Date of birth cannot be in the future';
    }
    final minimumAgeDate =
        DateTime(now.year - minimumAgeYears, now.month, now.day);
    if (date.isAfter(minimumAgeDate)) {
      return 'Student must be at least $minimumAgeYears years old';
    }
    return null;
  }
}
