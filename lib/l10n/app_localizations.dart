import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_mr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('hi'),
    Locale('mr')
  ];

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @goBack.
  ///
  /// In en, this message translates to:
  /// **'Go back'**
  String get goBack;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @announcements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcements;

  /// No description provided for @userSessionMissing.
  ///
  /// In en, this message translates to:
  /// **'Your session has ended. Please log in again.'**
  String get userSessionMissing;

  /// No description provided for @errorWithDetails.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong.\n{details}'**
  String errorWithDetails(String details);

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Showing saved data where available. Changes are disabled until you reconnect.'**
  String get offlineBanner;

  /// No description provided for @offlineSnack.
  ///
  /// In en, this message translates to:
  /// **'You are offline. Reconnect to make changes.'**
  String get offlineSnack;

  /// No description provided for @welcomeTagline.
  ///
  /// In en, this message translates to:
  /// **'Nurturing Minds, Shaping Futures'**
  String get welcomeTagline;

  /// No description provided for @welcomeLogin.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get welcomeLogin;

  /// No description provided for @welcomeRegister.
  ///
  /// In en, this message translates to:
  /// **'New student? Register here'**
  String get welcomeRegister;

  /// No description provided for @welcomeHint.
  ///
  /// In en, this message translates to:
  /// **'Log in with the mobile number or email and the access code given by the institute.'**
  String get welcomeHint;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'New student registration'**
  String get registerTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number or email and your access code (or password).'**
  String get loginSubtitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number to begin. We will send you a 6-digit code.'**
  String get registerSubtitle;

  /// No description provided for @mobileNumber.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get mobileNumber;

  /// No description provided for @sendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get emailAddress;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @loginButton.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButton;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address'**
  String get enterEmail;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @loginFailedCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get loginFailedCredentials;

  /// No description provided for @loginFailedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Could not log in. Please check your details and try again.'**
  String get loginFailedGeneric;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @otpTitle.
  ///
  /// In en, this message translates to:
  /// **'Check your email'**
  String get otpTitle;

  /// No description provided for @otpSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code sent to {email}'**
  String otpSubtitle(String email);

  /// No description provided for @otpVerify.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get otpVerify;

  /// No description provided for @otpInvalid.
  ///
  /// In en, this message translates to:
  /// **'That code is not correct. Please try again.'**
  String get otpInvalid;

  /// No description provided for @otpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds} seconds'**
  String otpResendIn(String seconds);

  /// No description provided for @otpResend.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get otpResend;

  /// No description provided for @otpResent.
  ///
  /// In en, this message translates to:
  /// **'A new code has been sent.'**
  String get otpResent;

  /// No description provided for @teacherLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Teacher verification'**
  String get teacherLoginTitle;

  /// No description provided for @teacherLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the access code given by the admin.'**
  String get teacherLoginSubtitle;

  /// No description provided for @accessCode.
  ///
  /// In en, this message translates to:
  /// **'Access code'**
  String get accessCode;

  /// No description provided for @accessCodeHint.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get accessCodeHint;

  /// No description provided for @enterAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit access code'**
  String get enterAccessCode;

  /// No description provided for @invalidAccessCode.
  ///
  /// In en, this message translates to:
  /// **'Invalid access code. Please check with the admin.'**
  String get invalidAccessCode;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many wrong attempts. Please try again in a few minutes.'**
  String get tooManyAttempts;

  /// No description provided for @adminLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Admin verification'**
  String get adminLoginTitle;

  /// No description provided for @adminLoginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your password and 6-digit access code.'**
  String get adminLoginSubtitle;

  /// No description provided for @adminLoginSubtitleFull.
  ///
  /// In en, this message translates to:
  /// **'Log in with your email, password and 6-digit access code.'**
  String get adminLoginSubtitleFull;

  /// No description provided for @adminEmail.
  ///
  /// In en, this message translates to:
  /// **'Admin email'**
  String get adminEmail;

  /// No description provided for @enterAdminEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your admin email'**
  String get enterAdminEmail;

  /// No description provided for @invalidAdminCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid admin credentials.'**
  String get invalidAdminCredentials;

  /// No description provided for @useDifferentAccount.
  ///
  /// In en, this message translates to:
  /// **'Use a different account'**
  String get useDifferentAccount;

  /// No description provided for @registrationSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Registration submitted'**
  String get registrationSubmitted;

  /// No description provided for @awaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Your registration is waiting for approval from the admin.'**
  String get awaitingApproval;

  /// No description provided for @notifyOnApproval.
  ///
  /// In en, this message translates to:
  /// **'You will get a notification once your account is approved. Please check back later.'**
  String get notifyOnApproval;

  /// No description provided for @statusPending.
  ///
  /// In en, this message translates to:
  /// **'Status: Pending'**
  String get statusPending;

  /// No description provided for @checkStatus.
  ///
  /// In en, this message translates to:
  /// **'Check status'**
  String get checkStatus;

  /// No description provided for @stillPending.
  ///
  /// In en, this message translates to:
  /// **'Still waiting for approval.'**
  String get stillPending;

  /// No description provided for @setPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set your password'**
  String get setPasswordTitle;

  /// No description provided for @setPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Your registration is approved. Create a password so you can also log in with email & password next time.'**
  String get setPasswordBody;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get passwordTooShort;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDontMatch;

  /// No description provided for @setPasswordContinue.
  ///
  /// In en, this message translates to:
  /// **'Set password & continue'**
  String get setPasswordContinue;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Session expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @couldNotSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Could not set the password. Please try again.'**
  String get couldNotSetPassword;

  /// No description provided for @studentRegistration.
  ///
  /// In en, this message translates to:
  /// **'Student registration'**
  String get studentRegistration;

  /// No description provided for @addPhotoOptional.
  ///
  /// In en, this message translates to:
  /// **'Add photo (optional)'**
  String get addPhotoOptional;

  /// No description provided for @addPhotoHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose a photo from your gallery'**
  String get addPhotoHint;

  /// No description provided for @sectionPersonal.
  ///
  /// In en, this message translates to:
  /// **'Student details'**
  String get sectionPersonal;

  /// No description provided for @sectionParent.
  ///
  /// In en, this message translates to:
  /// **'Parent / guardian'**
  String get sectionParent;

  /// No description provided for @sectionContact.
  ///
  /// In en, this message translates to:
  /// **'Contact & school'**
  String get sectionContact;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fullName;

  /// No description provided for @gender.
  ///
  /// In en, this message translates to:
  /// **'Gender'**
  String get gender;

  /// No description provided for @male.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get male;

  /// No description provided for @female.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get female;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @dateOfBirth.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get dateOfBirth;

  /// No description provided for @selectDate.
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// No description provided for @parentName.
  ///
  /// In en, this message translates to:
  /// **'Parent name'**
  String get parentName;

  /// No description provided for @parentMobile.
  ///
  /// In en, this message translates to:
  /// **'Parent mobile number'**
  String get parentMobile;

  /// No description provided for @whatsappNumber.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp number'**
  String get whatsappNumber;

  /// No description provided for @schoolName.
  ///
  /// In en, this message translates to:
  /// **'School name'**
  String get schoolName;

  /// No description provided for @board.
  ///
  /// In en, this message translates to:
  /// **'Board'**
  String get board;

  /// No description provided for @standardClass.
  ///
  /// In en, this message translates to:
  /// **'Standard / class'**
  String get standardClass;

  /// No description provided for @submitRegistration.
  ///
  /// In en, this message translates to:
  /// **'Submit registration'**
  String get submitRegistration;

  /// No description provided for @registrationReviewNote.
  ///
  /// In en, this message translates to:
  /// **'The admin will review your registration.'**
  String get registrationReviewNote;

  /// No description provided for @pleaseSelectGender.
  ///
  /// In en, this message translates to:
  /// **'Please select gender'**
  String get pleaseSelectGender;

  /// No description provided for @pleaseSelectDob.
  ///
  /// In en, this message translates to:
  /// **'Please select date of birth'**
  String get pleaseSelectDob;

  /// No description provided for @pleaseSelectBoard.
  ///
  /// In en, this message translates to:
  /// **'Please select board'**
  String get pleaseSelectBoard;

  /// No description provided for @pleaseSelectStandard.
  ///
  /// In en, this message translates to:
  /// **'Please select standard'**
  String get pleaseSelectStandard;

  /// No description provided for @pleaseEnterField.
  ///
  /// In en, this message translates to:
  /// **'Please enter {field}'**
  String pleaseEnterField(String field);

  /// No description provided for @registrationFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration could not be submitted. Please try again.'**
  String get registrationFailed;

  /// No description provided for @studentDashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Student dashboard'**
  String get studentDashboardTitle;

  /// No description provided for @welcomeStudent.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcomeStudent;

  /// No description provided for @myStudentHub.
  ///
  /// In en, this message translates to:
  /// **'My student hub'**
  String get myStudentHub;

  /// No description provided for @tileAttendance.
  ///
  /// In en, this message translates to:
  /// **'My attendance'**
  String get tileAttendance;

  /// No description provided for @tileAttendanceSub.
  ///
  /// In en, this message translates to:
  /// **'History & stats'**
  String get tileAttendanceSub;

  /// No description provided for @tileHomework.
  ///
  /// In en, this message translates to:
  /// **'Homework'**
  String get tileHomework;

  /// No description provided for @tileHomeworkSub.
  ///
  /// In en, this message translates to:
  /// **'Pending tasks & files'**
  String get tileHomeworkSub;

  /// No description provided for @tileClasswork.
  ///
  /// In en, this message translates to:
  /// **'Classwork'**
  String get tileClasswork;

  /// No description provided for @tileClassworkSub.
  ///
  /// In en, this message translates to:
  /// **'Notes & attachments'**
  String get tileClassworkSub;

  /// No description provided for @tileFees.
  ///
  /// In en, this message translates to:
  /// **'My fee status'**
  String get tileFees;

  /// No description provided for @tileFeesSub.
  ///
  /// In en, this message translates to:
  /// **'Payment records'**
  String get tileFeesSub;

  /// No description provided for @tileChat.
  ///
  /// In en, this message translates to:
  /// **'Ask a doubt'**
  String get tileChat;

  /// No description provided for @tileChatSub.
  ///
  /// In en, this message translates to:
  /// **'Chat with your teacher'**
  String get tileChatSub;

  /// No description provided for @tileTimetable.
  ///
  /// In en, this message translates to:
  /// **'Timetable'**
  String get tileTimetable;

  /// No description provided for @tileTimetableSub.
  ///
  /// In en, this message translates to:
  /// **'Class schedule'**
  String get tileTimetableSub;

  /// No description provided for @tileAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get tileAnnouncements;

  /// No description provided for @tileAnnouncementsSub.
  ///
  /// In en, this message translates to:
  /// **'Notices & alerts'**
  String get tileAnnouncementsSub;

  /// No description provided for @navigateTo.
  ///
  /// In en, this message translates to:
  /// **'Open {title}'**
  String navigateTo(String title);

  /// No description provided for @attendanceTitle.
  ///
  /// In en, this message translates to:
  /// **'My attendance'**
  String get attendanceTitle;

  /// No description provided for @selectMonth.
  ///
  /// In en, this message translates to:
  /// **'Select month'**
  String get selectMonth;

  /// No description provided for @pickMonth.
  ///
  /// In en, this message translates to:
  /// **'Pick month'**
  String get pickMonth;

  /// No description provided for @attendancePercent.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendancePercent;

  /// No description provided for @presentDays.
  ///
  /// In en, this message translates to:
  /// **'Present days'**
  String get presentDays;

  /// No description provided for @absentDays.
  ///
  /// In en, this message translates to:
  /// **'Absent days'**
  String get absentDays;

  /// No description provided for @noAttendanceRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records yet.'**
  String get noAttendanceRecords;

  /// No description provided for @statusPresent.
  ///
  /// In en, this message translates to:
  /// **'Present'**
  String get statusPresent;

  /// No description provided for @statusAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get statusAbsent;

  /// No description provided for @reasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason: {reason}'**
  String reasonLabel(String reason);

  /// No description provided for @couldNotLoadAttendance.
  ///
  /// In en, this message translates to:
  /// **'Could not load attendance.'**
  String get couldNotLoadAttendance;

  /// No description provided for @feesTitle.
  ///
  /// In en, this message translates to:
  /// **'My fee status'**
  String get feesTitle;

  /// No description provided for @noFeeRecords.
  ///
  /// In en, this message translates to:
  /// **'No fee records yet.'**
  String get noFeeRecords;

  /// No description provided for @expectedFee.
  ///
  /// In en, this message translates to:
  /// **'Fee'**
  String get expectedFee;

  /// No description provided for @paidAmount.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paidAmount;

  /// No description provided for @remainingAmount.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remainingAmount;

  /// No description provided for @feeHistory.
  ///
  /// In en, this message translates to:
  /// **'Fee payment history'**
  String get feeHistory;

  /// No description provided for @feeExpectedPaid.
  ///
  /// In en, this message translates to:
  /// **'Fee: ₹{expected} • Paid: ₹{paid}'**
  String feeExpectedPaid(String expected, String paid);

  /// No description provided for @feeRemainingShort.
  ///
  /// In en, this message translates to:
  /// **'Remaining\n₹{amount}'**
  String feeRemainingShort(String amount);

  /// No description provided for @couldNotLoadFees.
  ///
  /// In en, this message translates to:
  /// **'Could not load fees.'**
  String get couldNotLoadFees;

  /// No description provided for @feeStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get feeStatusPaid;

  /// No description provided for @feeStatusPartial.
  ///
  /// In en, this message translates to:
  /// **'Partly paid'**
  String get feeStatusPartial;

  /// No description provided for @feeStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get feeStatusPending;

  /// No description provided for @homeworkTitle.
  ///
  /// In en, this message translates to:
  /// **'My homework'**
  String get homeworkTitle;

  /// No description provided for @noActiveHomework.
  ///
  /// In en, this message translates to:
  /// **'No homework for your class right now.'**
  String get noActiveHomework;

  /// No description provided for @couldNotLoadHomework.
  ///
  /// In en, this message translates to:
  /// **'Could not load homework.'**
  String get couldNotLoadHomework;

  /// No description provided for @dueDate.
  ///
  /// In en, this message translates to:
  /// **'Due: {date}'**
  String dueDate(String date);

  /// No description provided for @teacherName.
  ///
  /// In en, this message translates to:
  /// **'Teacher: {name}'**
  String teacherName(String name);

  /// No description provided for @classworkTitle.
  ///
  /// In en, this message translates to:
  /// **'Classwork & study notes'**
  String get classworkTitle;

  /// No description provided for @noClasswork.
  ///
  /// In en, this message translates to:
  /// **'No classwork notes yet.'**
  String get noClasswork;

  /// No description provided for @couldNotLoadClasswork.
  ///
  /// In en, this message translates to:
  /// **'Could not load classwork.'**
  String get couldNotLoadClasswork;

  /// No description provided for @publishedBy.
  ///
  /// In en, this message translates to:
  /// **'Published by: {name}'**
  String publishedBy(String name);

  /// No description provided for @attachmentsCount.
  ///
  /// In en, this message translates to:
  /// **'Attachments ({count})'**
  String attachmentsCount(String count);

  /// No description provided for @announcementsFeed.
  ///
  /// In en, this message translates to:
  /// **'Announcements'**
  String get announcementsFeed;

  /// No description provided for @noAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'No announcements yet.'**
  String get noAnnouncements;

  /// No description provided for @couldNotLoadAnnouncements.
  ///
  /// In en, this message translates to:
  /// **'Could not load announcements.'**
  String get couldNotLoadAnnouncements;

  /// No description provided for @newAnnouncement.
  ///
  /// In en, this message translates to:
  /// **'New announcement'**
  String get newAnnouncement;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @noNotifications.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get noNotifications;

  /// No description provided for @couldNotLoadNotifications.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications.'**
  String get couldNotLoadNotifications;

  /// No description provided for @notificationsUnread.
  ///
  /// In en, this message translates to:
  /// **'Notifications ({count} unread)'**
  String notificationsUnread(String count);

  /// No description provided for @chatTitle.
  ///
  /// In en, this message translates to:
  /// **'Doubt-clearing chat'**
  String get chatTitle;

  /// No description provided for @couldNotLoadChats.
  ///
  /// In en, this message translates to:
  /// **'Could not load chats.'**
  String get couldNotLoadChats;

  /// No description provided for @noChatsStudent.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet.\nTap \"Ask a doubt\" to chat with your teacher.'**
  String get noChatsStudent;

  /// No description provided for @noChatsTeacher.
  ///
  /// In en, this message translates to:
  /// **'No doubt requests yet.'**
  String get noChatsTeacher;

  /// No description provided for @teacherFallback.
  ///
  /// In en, this message translates to:
  /// **'Teacher'**
  String get teacherFallback;

  /// No description provided for @studentFallback.
  ///
  /// In en, this message translates to:
  /// **'Student'**
  String get studentFallback;

  /// No description provided for @noMessagesYet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// No description provided for @askDoubt.
  ///
  /// In en, this message translates to:
  /// **'Ask a doubt'**
  String get askDoubt;

  /// No description provided for @selectTeacherToAsk.
  ///
  /// In en, this message translates to:
  /// **'Choose a teacher'**
  String get selectTeacherToAsk;

  /// No description provided for @noActiveTeachers.
  ///
  /// In en, this message translates to:
  /// **'No teachers available.'**
  String get noActiveTeachers;

  /// No description provided for @subjectsLabel.
  ///
  /// In en, this message translates to:
  /// **'Subjects: {subjects}'**
  String subjectsLabel(String subjects);

  /// No description provided for @chatRoomTitle.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatRoomTitle;

  /// No description provided for @loadingEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loadingEllipsis;

  /// No description provided for @noMessagesTypeDoubt.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Type your doubt below!'**
  String get noMessagesTypeDoubt;

  /// No description provided for @typeDoubtHint.
  ///
  /// In en, this message translates to:
  /// **'Type your doubt here...'**
  String get typeDoubtHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send message'**
  String get sendMessage;

  /// No description provided for @failedToSend.
  ///
  /// In en, this message translates to:
  /// **'Message could not be sent. Please try again.'**
  String get failedToSend;

  /// No description provided for @couldNotLoadMessages.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages.'**
  String get couldNotLoadMessages;

  /// No description provided for @timetableTitle.
  ///
  /// In en, this message translates to:
  /// **'My class timetable'**
  String get timetableTitle;

  /// No description provided for @noClassesToday.
  ///
  /// In en, this message translates to:
  /// **'No classes on this day.'**
  String get noClassesToday;

  /// No description provided for @slotDetails.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}\nTeacher: {teacher} • {room}'**
  String slotDetails(String end, String room, String start, String teacher);

  /// No description provided for @slotDetailsNoRoom.
  ///
  /// In en, this message translates to:
  /// **'{start} - {end}\nTeacher: {teacher}'**
  String slotDetailsNoRoom(String end, String start, String teacher);

  /// No description provided for @couldNotLoadTimetable.
  ///
  /// In en, this message translates to:
  /// **'Could not load the timetable.'**
  String get couldNotLoadTimetable;

  /// No description provided for @tbd.
  ///
  /// In en, this message translates to:
  /// **'To be announced'**
  String get tbd;

  /// No description provided for @dayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get dayMonday;

  /// No description provided for @dayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get dayTuesday;

  /// No description provided for @dayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get dayWednesday;

  /// No description provided for @dayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get dayThursday;

  /// No description provided for @dayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get dayFriday;

  /// No description provided for @daySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get daySaturday;

  /// No description provided for @daySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get daySunday;

  /// No description provided for @identifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Mobile number or email'**
  String get identifierLabel;

  /// No description provided for @enterIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Enter your mobile number or email'**
  String get enterIdentifier;

  /// No description provided for @invalidIdentifier.
  ///
  /// In en, this message translates to:
  /// **'Enter a 10-digit mobile number or a valid email'**
  String get invalidIdentifier;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @useEmailCodeInstead.
  ///
  /// In en, this message translates to:
  /// **'Email me a code instead'**
  String get useEmailCodeInstead;

  /// No description provided for @usePasswordInstead.
  ///
  /// In en, this message translates to:
  /// **'Log in with a password instead'**
  String get usePasswordInstead;

  /// No description provided for @emailCodeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address. We will send you a 6-digit code.'**
  String get emailCodeSubtitle;

  /// No description provided for @emailCodeNotice.
  ///
  /// In en, this message translates to:
  /// **'Mobile-only accounts cannot use a code. Ask the institute to reset your password.'**
  String get emailCodeNotice;

  /// No description provided for @sendCodeFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the code. Check the email address and try again.'**
  String get sendCodeFailed;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create your account'**
  String get createAccountTitle;

  /// No description provided for @createAccountSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Use a mobile number or an email, and choose a password.'**
  String get createAccountSubtitle;

  /// No description provided for @createAccountButton.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get createAccountButton;

  /// No description provided for @tabMobile.
  ///
  /// In en, this message translates to:
  /// **'Mobile number'**
  String get tabMobile;

  /// No description provided for @tabEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get tabEmail;

  /// No description provided for @passwordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get passwordHelper;

  /// No description provided for @accountAlreadyExists.
  ///
  /// In en, this message translates to:
  /// **'An account with this mobile number or email already exists. Please log in.'**
  String get accountAlreadyExists;

  /// No description provided for @accountCreatedConfirm.
  ///
  /// In en, this message translates to:
  /// **'Account created. Please confirm it using the message we sent, then log in.'**
  String get accountCreatedConfirm;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get alreadyHaveAccount;

  /// No description provided for @newPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get newPasswordTitle;

  /// No description provided for @newPasswordBody.
  ///
  /// In en, this message translates to:
  /// **'Choose a password you will remember. You can use it to log in next time.'**
  String get newPasswordBody;

  /// No description provided for @skipForNow.
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// No description provided for @savePassword.
  ///
  /// In en, this message translates to:
  /// **'Save password'**
  String get savePassword;

  /// No description provided for @passwordSaved.
  ///
  /// In en, this message translates to:
  /// **'Password saved.'**
  String get passwordSaved;

  /// No description provided for @passwordSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save the password. Please try again.'**
  String get passwordSaveFailed;

  /// No description provided for @contactEmailNote.
  ///
  /// In en, this message translates to:
  /// **'We will use this email only to contact you about your account.'**
  String get contactEmailNote;

  /// No description provided for @passwordOrCode.
  ///
  /// In en, this message translates to:
  /// **'Access code or password'**
  String get passwordOrCode;

  /// No description provided for @noLoginHint.
  ///
  /// In en, this message translates to:
  /// **'Do not have a login yet? Ask the institute. They will give you a mobile number or email and an access code.'**
  String get noLoginHint;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'hi', 'mr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'hi':
      return AppLocalizationsHi();
    case 'mr':
      return AppLocalizationsMr();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
