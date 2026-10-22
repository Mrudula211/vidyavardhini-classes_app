// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get retry => 'Retry';

  @override
  String get refresh => 'Refresh';

  @override
  String get logout => 'Logout';

  @override
  String get goBack => 'Go back';

  @override
  String get language => 'Language';

  @override
  String get announcements => 'Announcements';

  @override
  String get userSessionMissing =>
      'Your session has ended. Please log in again.';

  @override
  String errorWithDetails(String details) {
    return 'Something went wrong.\n$details';
  }

  @override
  String get offlineBanner =>
      'You are offline. Showing saved data where available. Changes are disabled until you reconnect.';

  @override
  String get offlineSnack => 'You are offline. Reconnect to make changes.';

  @override
  String get welcomeTagline => 'Nurturing Minds, Shaping Futures';

  @override
  String get welcomeLogin => 'Login';

  @override
  String get welcomeRegister => 'New student? Register here';

  @override
  String get welcomeHint =>
      'Log in with the mobile number or email and the access code given by the institute.';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get registerTitle => 'New student registration';

  @override
  String get loginSubtitle =>
      'Enter your mobile number or email and your access code (or password).';

  @override
  String get registerSubtitle =>
      'Enter your mobile number to begin. We will send you a 6-digit code.';

  @override
  String get mobileNumber => 'Mobile number';

  @override
  String get sendCode => 'Send code';

  @override
  String get emailAddress => 'Email address';

  @override
  String get password => 'Password';

  @override
  String get loginButton => 'Login';

  @override
  String get enterEmail => 'Enter your email address';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get loginFailedCredentials =>
      'Incorrect email or password. Please try again.';

  @override
  String get loginFailedGeneric =>
      'Could not log in. Please check your details and try again.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get otpTitle => 'Check your email';

  @override
  String otpSubtitle(String email) {
    return 'Enter the 6-digit code sent to $email';
  }

  @override
  String get otpVerify => 'Verify';

  @override
  String get otpInvalid => 'That code is not correct. Please try again.';

  @override
  String otpResendIn(String seconds) {
    return 'Resend code in $seconds seconds';
  }

  @override
  String get otpResend => 'Resend code';

  @override
  String get otpResent => 'A new code has been sent.';

  @override
  String get teacherLoginTitle => 'Teacher verification';

  @override
  String get teacherLoginSubtitle =>
      'Enter the access code given by the admin.';

  @override
  String get accessCode => 'Access code';

  @override
  String get accessCodeHint => '6-digit code';

  @override
  String get enterAccessCode => 'Enter the 6-digit access code';

  @override
  String get invalidAccessCode =>
      'Invalid access code. Please check with the admin.';

  @override
  String get tooManyAttempts =>
      'Too many wrong attempts. Please try again in a few minutes.';

  @override
  String get adminLoginTitle => 'Admin verification';

  @override
  String get adminLoginSubtitle =>
      'Enter your password and 6-digit access code.';

  @override
  String get adminLoginSubtitleFull =>
      'Log in with your email, password and 6-digit access code.';

  @override
  String get adminEmail => 'Admin email';

  @override
  String get enterAdminEmail => 'Enter your admin email';

  @override
  String get invalidAdminCredentials => 'Invalid admin credentials.';

  @override
  String get useDifferentAccount => 'Use a different account';

  @override
  String get registrationSubmitted => 'Registration submitted';

  @override
  String get awaitingApproval =>
      'Your registration is waiting for approval from the admin.';

  @override
  String get notifyOnApproval =>
      'You will get a notification once your account is approved. Please check back later.';

  @override
  String get statusPending => 'Status: Pending';

  @override
  String get checkStatus => 'Check status';

  @override
  String get stillPending => 'Still waiting for approval.';

  @override
  String get setPasswordTitle => 'Set your password';

  @override
  String get setPasswordBody =>
      'Your registration is approved. Create a password so you can also log in with email & password next time.';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDontMatch => 'Passwords do not match';

  @override
  String get setPasswordContinue => 'Set password & continue';

  @override
  String get sessionExpired => 'Session expired. Please log in again.';

  @override
  String get couldNotSetPassword =>
      'Could not set the password. Please try again.';

  @override
  String get studentRegistration => 'Student registration';

  @override
  String get addPhotoOptional => 'Add photo (optional)';

  @override
  String get addPhotoHint => 'Tap to choose a photo from your gallery';

  @override
  String get sectionPersonal => 'Student details';

  @override
  String get sectionParent => 'Parent / guardian';

  @override
  String get sectionContact => 'Contact & school';

  @override
  String get fullName => 'Full name';

  @override
  String get gender => 'Gender';

  @override
  String get male => 'Male';

  @override
  String get female => 'Female';

  @override
  String get other => 'Other';

  @override
  String get dateOfBirth => 'Date of birth';

  @override
  String get selectDate => 'Select date';

  @override
  String get parentName => 'Parent name';

  @override
  String get parentMobile => 'Parent mobile number';

  @override
  String get whatsappNumber => 'WhatsApp number';

  @override
  String get schoolName => 'School name';

  @override
  String get board => 'Board';

  @override
  String get standardClass => 'Standard / class';

  @override
  String get submitRegistration => 'Submit registration';

  @override
  String get registrationReviewNote =>
      'The admin will review your registration.';

  @override
  String get pleaseSelectGender => 'Please select gender';

  @override
  String get pleaseSelectDob => 'Please select date of birth';

  @override
  String get pleaseSelectBoard => 'Please select board';

  @override
  String get pleaseSelectStandard => 'Please select standard';

  @override
  String pleaseEnterField(String field) {
    return 'Please enter $field';
  }

  @override
  String get registrationFailed =>
      'Registration could not be submitted. Please try again.';

  @override
  String get studentDashboardTitle => 'Student dashboard';

  @override
  String get welcomeStudent => 'Welcome';

  @override
  String get myStudentHub => 'My student hub';

  @override
  String get tileAttendance => 'My attendance';

  @override
  String get tileAttendanceSub => 'History & stats';

  @override
  String get tileHomework => 'Homework';

  @override
  String get tileHomeworkSub => 'Pending tasks & files';

  @override
  String get tileClasswork => 'Classwork';

  @override
  String get tileClassworkSub => 'Notes & attachments';

  @override
  String get tileFees => 'My fee status';

  @override
  String get tileFeesSub => 'Payment records';

  @override
  String get tileChat => 'Ask a doubt';

  @override
  String get tileChatSub => 'Chat with your teacher';

  @override
  String get tileTimetable => 'Timetable';

  @override
  String get tileTimetableSub => 'Class schedule';

  @override
  String get tileAnnouncements => 'Announcements';

  @override
  String get tileAnnouncementsSub => 'Notices & alerts';

  @override
  String navigateTo(String title) {
    return 'Open $title';
  }

  @override
  String get attendanceTitle => 'My attendance';

  @override
  String get selectMonth => 'Select month';

  @override
  String get pickMonth => 'Pick month';

  @override
  String get attendancePercent => 'Attendance';

  @override
  String get presentDays => 'Present days';

  @override
  String get absentDays => 'Absent days';

  @override
  String get noAttendanceRecords => 'No attendance records yet.';

  @override
  String get statusPresent => 'Present';

  @override
  String get statusAbsent => 'Absent';

  @override
  String reasonLabel(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get couldNotLoadAttendance => 'Could not load attendance.';

  @override
  String get feesTitle => 'My fee status';

  @override
  String get noFeeRecords => 'No fee records yet.';

  @override
  String get expectedFee => 'Fee';

  @override
  String get paidAmount => 'Paid';

  @override
  String get remainingAmount => 'Remaining';

  @override
  String get feeHistory => 'Fee payment history';

  @override
  String feeExpectedPaid(String expected, String paid) {
    return 'Fee: ₹$expected • Paid: ₹$paid';
  }

  @override
  String feeRemainingShort(String amount) {
    return 'Remaining\n₹$amount';
  }

  @override
  String get couldNotLoadFees => 'Could not load fees.';

  @override
  String get feeStatusPaid => 'Paid';

  @override
  String get feeStatusPartial => 'Partly paid';

  @override
  String get feeStatusPending => 'Pending';

  @override
  String get homeworkTitle => 'My homework';

  @override
  String get noActiveHomework => 'No homework for your class right now.';

  @override
  String get couldNotLoadHomework => 'Could not load homework.';

  @override
  String dueDate(String date) {
    return 'Due: $date';
  }

  @override
  String teacherName(String name) {
    return 'Teacher: $name';
  }

  @override
  String get classworkTitle => 'Classwork & study notes';

  @override
  String get noClasswork => 'No classwork notes yet.';

  @override
  String get couldNotLoadClasswork => 'Could not load classwork.';

  @override
  String publishedBy(String name) {
    return 'Published by: $name';
  }

  @override
  String attachmentsCount(String count) {
    return 'Attachments ($count)';
  }

  @override
  String get announcementsFeed => 'Announcements';

  @override
  String get noAnnouncements => 'No announcements yet.';

  @override
  String get couldNotLoadAnnouncements => 'Could not load announcements.';

  @override
  String get newAnnouncement => 'New announcement';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get noNotifications => 'No notifications yet.';

  @override
  String get couldNotLoadNotifications => 'Could not load notifications.';

  @override
  String notificationsUnread(String count) {
    return 'Notifications ($count unread)';
  }

  @override
  String get chatTitle => 'Doubt-clearing chat';

  @override
  String get couldNotLoadChats => 'Could not load chats.';

  @override
  String get noChatsStudent =>
      'No conversations yet.\nTap \"Ask a doubt\" to chat with your teacher.';

  @override
  String get noChatsTeacher => 'No doubt requests yet.';

  @override
  String get teacherFallback => 'Teacher';

  @override
  String get studentFallback => 'Student';

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get askDoubt => 'Ask a doubt';

  @override
  String get selectTeacherToAsk => 'Choose a teacher';

  @override
  String get noActiveTeachers => 'No teachers available.';

  @override
  String subjectsLabel(String subjects) {
    return 'Subjects: $subjects';
  }

  @override
  String get chatRoomTitle => 'Chat';

  @override
  String get loadingEllipsis => 'Loading...';

  @override
  String get noMessagesTypeDoubt => 'No messages yet. Type your doubt below!';

  @override
  String get typeDoubtHint => 'Type your doubt here...';

  @override
  String get sendMessage => 'Send message';

  @override
  String get failedToSend => 'Message could not be sent. Please try again.';

  @override
  String get couldNotLoadMessages => 'Could not load messages.';

  @override
  String get timetableTitle => 'My class timetable';

  @override
  String get noClassesToday => 'No classes on this day.';

  @override
  String slotDetails(String end, String room, String start, String teacher) {
    return '$start - $end\nTeacher: $teacher • $room';
  }

  @override
  String slotDetailsNoRoom(String end, String start, String teacher) {
    return '$start - $end\nTeacher: $teacher';
  }

  @override
  String get couldNotLoadTimetable => 'Could not load the timetable.';

  @override
  String get tbd => 'To be announced';

  @override
  String get dayMonday => 'Monday';

  @override
  String get dayTuesday => 'Tuesday';

  @override
  String get dayWednesday => 'Wednesday';

  @override
  String get dayThursday => 'Thursday';

  @override
  String get dayFriday => 'Friday';

  @override
  String get daySaturday => 'Saturday';

  @override
  String get daySunday => 'Sunday';

  @override
  String get identifierLabel => 'Mobile number or email';

  @override
  String get enterIdentifier => 'Enter your mobile number or email';

  @override
  String get invalidIdentifier =>
      'Enter a 10-digit mobile number or a valid email';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get useEmailCodeInstead => 'Email me a code instead';

  @override
  String get usePasswordInstead => 'Log in with a password instead';

  @override
  String get emailCodeSubtitle =>
      'Enter your email address. We will send you a 6-digit code.';

  @override
  String get emailCodeNotice =>
      'Mobile-only accounts cannot use a code. Ask the institute to reset your password.';

  @override
  String get sendCodeFailed =>
      'Could not send the code. Check the email address and try again.';

  @override
  String get createAccountTitle => 'Create your account';

  @override
  String get createAccountSubtitle =>
      'Use a mobile number or an email, and choose a password.';

  @override
  String get createAccountButton => 'Create account';

  @override
  String get tabMobile => 'Mobile number';

  @override
  String get tabEmail => 'Email';

  @override
  String get passwordHelper => 'At least 6 characters';

  @override
  String get accountAlreadyExists =>
      'An account with this mobile number or email already exists. Please log in.';

  @override
  String get accountCreatedConfirm =>
      'Account created. Please confirm it using the message we sent, then log in.';

  @override
  String get alreadyHaveAccount => 'Already have an account? Log in';

  @override
  String get newPasswordTitle => 'Set a new password';

  @override
  String get newPasswordBody =>
      'Choose a password you will remember. You can use it to log in next time.';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get savePassword => 'Save password';

  @override
  String get passwordSaved => 'Password saved.';

  @override
  String get passwordSaveFailed =>
      'Could not save the password. Please try again.';

  @override
  String get contactEmailNote =>
      'We will use this email only to contact you about your account.';

  @override
  String get passwordOrCode => 'Access code or password';

  @override
  String get noLoginHint =>
      'Do not have a login yet? Ask the institute. They will give you a mobile number or email and an access code.';
}
