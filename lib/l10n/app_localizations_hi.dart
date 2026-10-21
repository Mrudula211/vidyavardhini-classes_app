// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get refresh => 'रिफ्रेश करें';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get goBack => 'वापस जाएँ';

  @override
  String get language => 'भाषा';

  @override
  String get announcements => 'सूचनाएँ';

  @override
  String get userSessionMissing =>
      'आपका सत्र समाप्त हो गया है। कृपया फिर से लॉगिन करें।';

  @override
  String errorWithDetails(String details) {
    return 'कुछ गलत हो गया।\n$details';
  }

  @override
  String get offlineBanner =>
      'आप ऑफ़लाइन हैं। जहाँ उपलब्ध है, सहेजा हुआ डेटा दिखाया जा रहा है। इंटरनेट आने तक बदलाव बंद हैं।';

  @override
  String get offlineSnack =>
      'आप ऑफ़लाइन हैं। बदलाव करने के लिए इंटरनेट से जुड़ें।';

  @override
  String get welcomeTagline => 'मन का पोषण, भविष्य का निर्माण';

  @override
  String get welcomeLogin => 'लॉगिन करें';

  @override
  String get welcomeRegister => 'नए विद्यार्थी? यहाँ पंजीकरण करें';

  @override
  String get welcomeHint =>
      'विद्यार्थी, अभिभावक और शिक्षक अपने पंजीकृत मोबाइल नंबर से लॉगिन करें।';

  @override
  String get loginTitle => 'फिर से स्वागत है';

  @override
  String get registerTitle => 'नए विद्यार्थी का पंजीकरण';

  @override
  String get loginSubtitle =>
      'अपना मोबाइल नंबर डालें। हम आपको 6 अंकों का कोड भेजेंगे।';

  @override
  String get registerSubtitle =>
      'शुरू करने के लिए मोबाइल नंबर डालें। हम आपको 6 अंकों का कोड भेजेंगे।';

  @override
  String get emailLoginSubtitle => 'अपने ईमेल और पासवर्ड से लॉगिन करें।';

  @override
  String get mobileNumber => 'मोबाइल नंबर';

  @override
  String get sendCode => 'कोड भेजें';

  @override
  String get useEmailInstead => 'इसके बजाय ईमेल और पासवर्ड से लॉगिन करें';

  @override
  String get usePhoneInstead => 'इसके बजाय मोबाइल नंबर से लॉगिन करें';

  @override
  String get emailAddress => 'ईमेल पता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get enterEmail => 'अपना ईमेल पता डालें';

  @override
  String get enterPassword => 'अपना पासवर्ड डालें';

  @override
  String get enterMobile => 'अपना मोबाइल नंबर डालें';

  @override
  String get invalidMobile => '10 अंकों का सही मोबाइल नंबर डालें';

  @override
  String get loginFailedCredentials =>
      'ईमेल या पासवर्ड गलत है। कृपया फिर कोशिश करें।';

  @override
  String get loginFailedGeneric =>
      'लॉगिन नहीं हो सका। कृपया जानकारी जाँचकर फिर कोशिश करें।';

  @override
  String get sendCodeFailed =>
      'कोड नहीं भेजा जा सका। नंबर जाँचकर फिर कोशिश करें।';

  @override
  String get showPassword => 'पासवर्ड दिखाएँ';

  @override
  String get hidePassword => 'पासवर्ड छिपाएँ';

  @override
  String get otpTitle => 'कोड सत्यापित करें';

  @override
  String otpSubtitle(String phone) {
    return '$phone पर भेजा गया 6 अंकों का कोड डालें';
  }

  @override
  String get otpVerify => 'सत्यापित करें';

  @override
  String get otpInvalid => 'यह कोड सही नहीं है। कृपया फिर कोशिश करें।';

  @override
  String otpResendIn(String seconds) {
    return '$seconds सेकंड में कोड फिर भेजें';
  }

  @override
  String get otpResend => 'कोड फिर भेजें';

  @override
  String get otpResent => 'नया कोड भेज दिया गया है।';

  @override
  String get teacherLoginTitle => 'शिक्षक सत्यापन';

  @override
  String get teacherLoginSubtitle => 'एडमिन द्वारा दिया गया एक्सेस कोड डालें।';

  @override
  String get accessCode => 'एक्सेस कोड';

  @override
  String get accessCodeHint => '6 अंकों का कोड';

  @override
  String get enterAccessCode => '6 अंकों का एक्सेस कोड डालें';

  @override
  String get invalidAccessCode => 'एक्सेस कोड गलत है। कृपया एडमिन से पूछें।';

  @override
  String get tooManyAttempts =>
      'बहुत ज़्यादा गलत प्रयास। कृपया कुछ मिनट बाद फिर कोशिश करें।';

  @override
  String get adminLoginTitle => 'एडमिन सत्यापन';

  @override
  String get adminLoginSubtitle =>
      'अपना पासवर्ड और 6 अंकों का एक्सेस कोड डालें।';

  @override
  String get adminLoginSubtitleFull =>
      'अपने ईमेल, पासवर्ड और 6 अंकों के एक्सेस कोड से लॉगिन करें।';

  @override
  String get adminEmail => 'एडमिन ईमेल';

  @override
  String get enterAdminEmail => 'अपना एडमिन ईमेल डालें';

  @override
  String get invalidAdminCredentials => 'एडमिन की जानकारी गलत है।';

  @override
  String get useDifferentAccount => 'दूसरे खाते से लॉगिन करें';

  @override
  String get registrationSubmitted => 'पंजीकरण जमा हो गया';

  @override
  String get awaitingApproval =>
      'आपका पंजीकरण एडमिन की मंज़ूरी का इंतज़ार कर रहा है।';

  @override
  String get notifyOnApproval =>
      'खाता मंज़ूर होते ही आपको सूचना मिलेगी। कृपया बाद में फिर देखें।';

  @override
  String get statusPending => 'स्थिति: प्रतीक्षा में';

  @override
  String get checkStatus => 'स्थिति जाँचें';

  @override
  String get stillPending => 'अभी भी मंज़ूरी का इंतज़ार है।';

  @override
  String get setPasswordTitle => 'अपना पासवर्ड बनाएँ';

  @override
  String get setPasswordBody =>
      'आपका पंजीकरण मंज़ूर हो गया है। एक पासवर्ड बनाएँ ताकि अगली बार आप ईमेल और पासवर्ड से भी लॉगिन कर सकें।';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड दोबारा डालें';

  @override
  String get passwordTooShort => 'पासवर्ड कम से कम 6 अक्षर का होना चाहिए';

  @override
  String get passwordsDontMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get setPasswordContinue => 'पासवर्ड बनाकर आगे बढ़ें';

  @override
  String get sessionExpired => 'सत्र समाप्त हो गया। कृपया फिर से लॉगिन करें।';

  @override
  String get couldNotSetPassword =>
      'पासवर्ड सेट नहीं हो सका। कृपया फिर कोशिश करें।';

  @override
  String get studentRegistration => 'विद्यार्थी पंजीकरण';

  @override
  String get addPhotoOptional => 'फ़ोटो जोड़ें (वैकल्पिक)';

  @override
  String get addPhotoHint => 'गैलरी से फ़ोटो चुनने के लिए टैप करें';

  @override
  String get sectionPersonal => 'विद्यार्थी की जानकारी';

  @override
  String get sectionParent => 'अभिभावक';

  @override
  String get sectionContact => 'संपर्क और स्कूल';

  @override
  String get fullName => 'पूरा नाम';

  @override
  String get gender => 'लिंग';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'महिला';

  @override
  String get other => 'अन्य';

  @override
  String get dateOfBirth => 'जन्म तिथि';

  @override
  String get selectDate => 'तिथि चुनें';

  @override
  String get parentName => 'अभिभावक का नाम';

  @override
  String get parentMobile => 'अभिभावक का मोबाइल नंबर';

  @override
  String get whatsappNumber => 'व्हाट्सएप नंबर';

  @override
  String get schoolName => 'स्कूल का नाम';

  @override
  String get board => 'बोर्ड';

  @override
  String get standardClass => 'कक्षा';

  @override
  String get submitRegistration => 'पंजीकरण जमा करें';

  @override
  String get registrationReviewNote => 'एडमिन आपके पंजीकरण की जाँच करेंगे।';

  @override
  String get pleaseSelectGender => 'कृपया लिंग चुनें';

  @override
  String get pleaseSelectDob => 'कृपया जन्म तिथि चुनें';

  @override
  String get pleaseSelectBoard => 'कृपया बोर्ड चुनें';

  @override
  String get pleaseSelectStandard => 'कृपया कक्षा चुनें';

  @override
  String pleaseEnterField(String field) {
    return 'कृपया $field डालें';
  }

  @override
  String get registrationFailed =>
      'पंजीकरण जमा नहीं हो सका। कृपया फिर कोशिश करें।';

  @override
  String get studentDashboardTitle => 'विद्यार्थी डैशबोर्ड';

  @override
  String get welcomeStudent => 'स्वागत है';

  @override
  String get myStudentHub => 'मेरा विद्यार्थी केंद्र';

  @override
  String get tileAttendance => 'मेरी उपस्थिति';

  @override
  String get tileAttendanceSub => 'इतिहास और आँकड़े';

  @override
  String get tileHomework => 'गृहकार्य';

  @override
  String get tileHomeworkSub => 'बाकी काम और फ़ाइलें';

  @override
  String get tileClasswork => 'कक्षा कार्य';

  @override
  String get tileClassworkSub => 'नोट्स और फ़ाइलें';

  @override
  String get tileFees => 'मेरी फ़ीस की स्थिति';

  @override
  String get tileFeesSub => 'भुगतान का रिकॉर्ड';

  @override
  String get tileChat => 'संदेह पूछें';

  @override
  String get tileChatSub => 'शिक्षक से बात करें';

  @override
  String get tileTimetable => 'समय सारणी';

  @override
  String get tileTimetableSub => 'कक्षा का समय';

  @override
  String get tileAnnouncements => 'सूचनाएँ';

  @override
  String get tileAnnouncementsSub => 'नोटिस और अलर्ट';

  @override
  String navigateTo(String title) {
    return '$title खोलें';
  }

  @override
  String get attendanceTitle => 'मेरी उपस्थिति';

  @override
  String get selectMonth => 'महीना चुनें';

  @override
  String get pickMonth => 'महीना चुनें';

  @override
  String get attendancePercent => 'उपस्थिति';

  @override
  String get presentDays => 'उपस्थित दिन';

  @override
  String get absentDays => 'अनुपस्थित दिन';

  @override
  String get noAttendanceRecords => 'अभी तक कोई उपस्थिति रिकॉर्ड नहीं है।';

  @override
  String get statusPresent => 'उपस्थित';

  @override
  String get statusAbsent => 'अनुपस्थित';

  @override
  String reasonLabel(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get couldNotLoadAttendance => 'उपस्थिति नहीं दिख सकी।';

  @override
  String get feesTitle => 'मेरी फ़ीस की स्थिति';

  @override
  String get noFeeRecords => 'अभी तक कोई फ़ीस रिकॉर्ड नहीं है।';

  @override
  String get expectedFee => 'फ़ीस';

  @override
  String get paidAmount => 'चुकाई गई';

  @override
  String get remainingAmount => 'बाकी';

  @override
  String get feeHistory => 'फ़ीस भुगतान का इतिहास';

  @override
  String feeExpectedPaid(String expected, String paid) {
    return 'फ़ीस: ₹$expected • चुकाई: ₹$paid';
  }

  @override
  String feeRemainingShort(String amount) {
    return 'बाकी\n₹$amount';
  }

  @override
  String get couldNotLoadFees => 'फ़ीस की जानकारी नहीं दिख सकी।';

  @override
  String get feeStatusPaid => 'चुकता';

  @override
  String get feeStatusPartial => 'आंशिक चुकाई';

  @override
  String get feeStatusPending => 'बाकी';

  @override
  String get homeworkTitle => 'मेरा गृहकार्य';

  @override
  String get noActiveHomework => 'अभी आपकी कक्षा के लिए कोई गृहकार्य नहीं है।';

  @override
  String get couldNotLoadHomework => 'गृहकार्य नहीं दिख सका।';

  @override
  String dueDate(String date) {
    return 'अंतिम तिथि: $date';
  }

  @override
  String teacherName(String name) {
    return 'शिक्षक: $name';
  }

  @override
  String get classworkTitle => 'कक्षा कार्य और अध्ययन नोट्स';

  @override
  String get noClasswork => 'अभी तक कोई कक्षा कार्य नोट्स नहीं हैं।';

  @override
  String get couldNotLoadClasswork => 'कक्षा कार्य नहीं दिख सका।';

  @override
  String publishedBy(String name) {
    return 'भेजने वाले: $name';
  }

  @override
  String attachmentsCount(String count) {
    return 'फ़ाइलें ($count)';
  }

  @override
  String get announcementsFeed => 'सूचनाएँ';

  @override
  String get noAnnouncements => 'अभी तक कोई सूचना नहीं है।';

  @override
  String get couldNotLoadAnnouncements => 'सूचनाएँ नहीं दिख सकीं।';

  @override
  String get newAnnouncement => 'नई सूचना';

  @override
  String get notificationsTitle => 'सूचनाएँ (नोटिफ़िकेशन)';

  @override
  String get noNotifications => 'अभी तक कोई नोटिफ़िकेशन नहीं है।';

  @override
  String get couldNotLoadNotifications => 'नोटिफ़िकेशन नहीं दिख सके।';

  @override
  String notificationsUnread(String count) {
    return 'नोटिफ़िकेशन ($count अपठित)';
  }

  @override
  String get chatTitle => 'संदेह समाधान चैट';

  @override
  String get couldNotLoadChats => 'चैट नहीं दिख सकी।';

  @override
  String get noChatsStudent =>
      'अभी कोई बातचीत नहीं है।\nशिक्षक से बात करने के लिए \"संदेह पूछें\" दबाएँ।';

  @override
  String get noChatsTeacher => 'अभी कोई संदेह नहीं आया है।';

  @override
  String get teacherFallback => 'शिक्षक';

  @override
  String get studentFallback => 'विद्यार्थी';

  @override
  String get noMessagesYet => 'अभी कोई संदेश नहीं';

  @override
  String get askDoubt => 'संदेह पूछें';

  @override
  String get selectTeacherToAsk => 'शिक्षक चुनें';

  @override
  String get noActiveTeachers => 'कोई शिक्षक उपलब्ध नहीं है।';

  @override
  String subjectsLabel(String subjects) {
    return 'विषय: $subjects';
  }

  @override
  String get chatRoomTitle => 'चैट';

  @override
  String get loadingEllipsis => 'लोड हो रहा है...';

  @override
  String get noMessagesTypeDoubt =>
      'अभी कोई संदेश नहीं। नीचे अपना संदेह लिखें!';

  @override
  String get typeDoubtHint => 'यहाँ अपना संदेह लिखें...';

  @override
  String get sendMessage => 'संदेश भेजें';

  @override
  String get failedToSend => 'संदेश नहीं भेजा जा सका। कृपया फिर कोशिश करें।';

  @override
  String get couldNotLoadMessages => 'संदेश नहीं दिख सके।';

  @override
  String get timetableTitle => 'मेरी कक्षा की समय सारणी';

  @override
  String get noClassesToday => 'इस दिन कोई कक्षा नहीं है।';

  @override
  String slotDetails(String end, String room, String start, String teacher) {
    return '$start - $end\nशिक्षक: $teacher • $room';
  }

  @override
  String slotDetailsNoRoom(String end, String start, String teacher) {
    return '$start - $end\nशिक्षक: $teacher';
  }

  @override
  String get couldNotLoadTimetable => 'समय सारणी नहीं दिख सकी।';

  @override
  String get tbd => 'बाद में बताया जाएगा';

  @override
  String get dayMonday => 'सोमवार';

  @override
  String get dayTuesday => 'मंगलवार';

  @override
  String get dayWednesday => 'बुधवार';

  @override
  String get dayThursday => 'गुरुवार';

  @override
  String get dayFriday => 'शुक्रवार';

  @override
  String get daySaturday => 'शनिवार';

  @override
  String get daySunday => 'रविवार';
}
