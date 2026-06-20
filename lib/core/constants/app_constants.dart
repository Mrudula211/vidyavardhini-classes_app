class AppConstants {
  AppConstants._();

  // Student / Teacher ID formats
  static const String studentIdPrefix = 'STU';
  static const int studentIdPadLength = 4;
  static const String teacherIdPrefix = 'TCH';
  static const int teacherIdPadLength = 4;

  // Fee reminder day
  static const int feeReminderDay = 10;

  // File upload limits
  static const int maxFileSizeMB = 20;
  static const int maxFileSizeBytes = maxFileSizeMB * 1024 * 1024;

  // Geofence
  static const double defaultGeofenceRadiusMeters = 100;

  // Pagination
  static const int pageSize = 25;

  // Cache durations (minutes)
  static const int announcementCacheMins = 60;
  static const int homeworkCacheMins = 30;
  static const int attendanceCacheMins = 60;
  static const int feeCacheMins = 30;

  // OTP
  static const int otpResendSeconds = 60;
  static const int otpLengthDigits = 6;

  // Boards
  static const List<String> boards = ['SSC', 'CBSE'];

  // Standards
  static const List<String> standards = [
    '1st', '2nd', '3rd', '4th', '5th',
    '6th', '7th', '8th', '9th', '10th',
  ];

  // Subjects (common)
  static const List<String> subjects = [
    'Mathematics',
    'Science',
    'English',
    'Hindi',
    'Marathi',
    'Social Studies',
    'History',
    'Geography',
    'Civics',
    'All Subjects',
  ];

  // Absence reasons
  static const Map<String, String> absenceReasons = {
    'sick': 'Sick',
    'family_function': 'Family Function',
    'travel': 'Travel',
    'personal': 'Personal',
    'other': 'Other',
  };

  // Payment methods
  static const Map<String, String> paymentMethods = {
    'cash': 'Cash',
    'upi': 'UPI',
    'bank_transfer': 'Bank Transfer',
    'cheque': 'Cheque',
  };

  // Storage bucket names
  static const String bucketProfilePhotos = 'profile-photos';
  static const String bucketHomework = 'homework-attachments';
  static const String bucketClasswork = 'classwork-attachments';
  static const String bucketChat = 'chat-files';

  // App info
  static const String appName = 'Vidyavardhini Classes';
  static const String appTaglineEnglish = 'Nurturing Minds, Shaping Futures';
  static const String appTaglineSanskrit = 'सा विद्या या विमुक्तये';
}
