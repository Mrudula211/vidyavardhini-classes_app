// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Marathi (`mr`).
class AppLocalizationsMr extends AppLocalizations {
  AppLocalizationsMr([String locale = 'mr']) : super(locale);

  @override
  String get retry => 'पुन्हा प्रयत्न करा';

  @override
  String get refresh => 'रिफ्रेश करा';

  @override
  String get logout => 'लॉग आउट';

  @override
  String get goBack => 'मागे जा';

  @override
  String get language => 'भाषा';

  @override
  String get announcements => 'सूचना';

  @override
  String get userSessionMissing =>
      'तुमचे सत्र संपले आहे. कृपया पुन्हा लॉगिन करा.';

  @override
  String errorWithDetails(String details) {
    return 'काहीतरी चुकले.\n$details';
  }

  @override
  String get offlineBanner =>
      'तुम्ही ऑफलाइन आहात. उपलब्ध तेथे जतन केलेली माहिती दाखवली जात आहे. इंटरनेट येईपर्यंत बदल बंद आहेत.';

  @override
  String get offlineSnack =>
      'तुम्ही ऑफलाइन आहात. बदल करण्यासाठी इंटरनेटशी जोडा.';

  @override
  String get welcomeTagline => 'मनाचे पोषण, भविष्याची घडण';

  @override
  String get welcomeLogin => 'लॉगिन करा';

  @override
  String get welcomeRegister => 'नवीन विद्यार्थी? येथे नोंदणी करा';

  @override
  String get welcomeHint =>
      'विद्यार्थी, पालक आणि शिक्षक नोंदणीकृत मोबाईल नंबरने लॉगिन करा.';

  @override
  String get loginTitle => 'पुन्हा स्वागत आहे';

  @override
  String get registerTitle => 'नवीन विद्यार्थी नोंदणी';

  @override
  String get loginSubtitle =>
      'तुमचा मोबाईल नंबर टाका. आम्ही तुम्हाला ६ अंकी कोड पाठवू.';

  @override
  String get registerSubtitle =>
      'सुरू करण्यासाठी मोबाईल नंबर टाका. आम्ही तुम्हाला ६ अंकी कोड पाठवू.';

  @override
  String get emailLoginSubtitle => 'तुमचा ईमेल आणि पासवर्ड वापरून लॉगिन करा.';

  @override
  String get mobileNumber => 'मोबाईल नंबर';

  @override
  String get sendCode => 'कोड पाठवा';

  @override
  String get useEmailInstead => 'त्याऐवजी ईमेल व पासवर्डने लॉगिन करा';

  @override
  String get usePhoneInstead => 'त्याऐवजी मोबाईल नंबरने लॉगिन करा';

  @override
  String get emailAddress => 'ईमेल पत्ता';

  @override
  String get password => 'पासवर्ड';

  @override
  String get loginButton => 'लॉगिन';

  @override
  String get enterEmail => 'तुमचा ईमेल पत्ता टाका';

  @override
  String get enterPassword => 'तुमचा पासवर्ड टाका';

  @override
  String get enterMobile => 'तुमचा मोबाईल नंबर टाका';

  @override
  String get invalidMobile => '१० अंकी योग्य मोबाईल नंबर टाका';

  @override
  String get loginFailedCredentials =>
      'ईमेल किंवा पासवर्ड चुकीचा आहे. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get loginFailedGeneric =>
      'लॉगिन होऊ शकले नाही. कृपया माहिती तपासून पुन्हा प्रयत्न करा.';

  @override
  String get sendCodeFailed =>
      'कोड पाठवता आला नाही. नंबर तपासून पुन्हा प्रयत्न करा.';

  @override
  String get showPassword => 'पासवर्ड दाखवा';

  @override
  String get hidePassword => 'पासवर्ड लपवा';

  @override
  String get otpTitle => 'कोड तपासा';

  @override
  String otpSubtitle(String phone) {
    return '$phone वर पाठवलेला ६ अंकी कोड टाका';
  }

  @override
  String get otpVerify => 'तपासा';

  @override
  String get otpInvalid => 'हा कोड बरोबर नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String otpResendIn(String seconds) {
    return '$seconds सेकंदात कोड पुन्हा पाठवा';
  }

  @override
  String get otpResend => 'कोड पुन्हा पाठवा';

  @override
  String get otpResent => 'नवीन कोड पाठवला आहे.';

  @override
  String get teacherLoginTitle => 'शिक्षक पडताळणी';

  @override
  String get teacherLoginSubtitle => 'ॲडमिनने दिलेला ॲक्सेस कोड टाका.';

  @override
  String get accessCode => 'ॲक्सेस कोड';

  @override
  String get accessCodeHint => '६ अंकी कोड';

  @override
  String get enterAccessCode => '६ अंकी ॲक्सेस कोड टाका';

  @override
  String get invalidAccessCode =>
      'ॲक्सेस कोड चुकीचा आहे. कृपया ॲडमिनला विचारा.';

  @override
  String get tooManyAttempts =>
      'खूप चुकीचे प्रयत्न झाले. कृपया काही मिनिटांनी पुन्हा प्रयत्न करा.';

  @override
  String get adminLoginTitle => 'ॲडमिन पडताळणी';

  @override
  String get adminLoginSubtitle => 'तुमचा पासवर्ड आणि ६ अंकी ॲक्सेस कोड टाका.';

  @override
  String get adminLoginSubtitleFull =>
      'तुमचा ईमेल, पासवर्ड आणि ६ अंकी ॲक्सेस कोड वापरून लॉगिन करा.';

  @override
  String get adminEmail => 'ॲडमिन ईमेल';

  @override
  String get enterAdminEmail => 'तुमचा ॲडमिन ईमेल टाका';

  @override
  String get invalidAdminCredentials => 'ॲडमिनची माहिती चुकीची आहे.';

  @override
  String get useDifferentAccount => 'दुसऱ्या खात्याने लॉगिन करा';

  @override
  String get registrationSubmitted => 'नोंदणी सादर झाली';

  @override
  String get awaitingApproval =>
      'तुमची नोंदणी ॲडमिनच्या मंजुरीची वाट पाहत आहे.';

  @override
  String get notifyOnApproval =>
      'खाते मंजूर होताच तुम्हाला सूचना मिळेल. कृपया नंतर पुन्हा पहा.';

  @override
  String get statusPending => 'स्थिती: प्रतीक्षेत';

  @override
  String get checkStatus => 'स्थिती तपासा';

  @override
  String get stillPending => 'अजूनही मंजुरीची प्रतीक्षा आहे.';

  @override
  String get setPasswordTitle => 'तुमचा पासवर्ड तयार करा';

  @override
  String get setPasswordBody =>
      'तुमची नोंदणी मंजूर झाली आहे. पासवर्ड तयार करा, म्हणजे पुढच्या वेळी तुम्ही ईमेल व पासवर्डनेही लॉगिन करू शकाल.';

  @override
  String get newPassword => 'नवीन पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्डची पुष्टी करा';

  @override
  String get passwordTooShort => 'पासवर्ड किमान ६ अक्षरांचा असावा';

  @override
  String get passwordsDontMatch => 'पासवर्ड जुळत नाहीत';

  @override
  String get setPasswordContinue => 'पासवर्ड तयार करून पुढे जा';

  @override
  String get sessionExpired => 'सत्र संपले. कृपया पुन्हा लॉगिन करा.';

  @override
  String get couldNotSetPassword =>
      'पासवर्ड सेट करता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get studentRegistration => 'विद्यार्थी नोंदणी';

  @override
  String get addPhotoOptional => 'फोटो जोडा (ऐच्छिक)';

  @override
  String get addPhotoHint => 'गॅलरीतून फोटो निवडण्यासाठी टॅप करा';

  @override
  String get sectionPersonal => 'विद्यार्थ्याची माहिती';

  @override
  String get sectionParent => 'पालक';

  @override
  String get sectionContact => 'संपर्क आणि शाळा';

  @override
  String get fullName => 'पूर्ण नाव';

  @override
  String get gender => 'लिंग';

  @override
  String get male => 'पुरुष';

  @override
  String get female => 'स्त्री';

  @override
  String get other => 'इतर';

  @override
  String get dateOfBirth => 'जन्मतारीख';

  @override
  String get selectDate => 'तारीख निवडा';

  @override
  String get parentName => 'पालकाचे नाव';

  @override
  String get parentMobile => 'पालकाचा मोबाईल नंबर';

  @override
  String get whatsappNumber => 'व्हॉट्सॲप नंबर';

  @override
  String get schoolName => 'शाळेचे नाव';

  @override
  String get board => 'बोर्ड';

  @override
  String get standardClass => 'इयत्ता';

  @override
  String get submitRegistration => 'नोंदणी सादर करा';

  @override
  String get registrationReviewNote => 'ॲडमिन तुमच्या नोंदणीची तपासणी करतील.';

  @override
  String get pleaseSelectGender => 'कृपया लिंग निवडा';

  @override
  String get pleaseSelectDob => 'कृपया जन्मतारीख निवडा';

  @override
  String get pleaseSelectBoard => 'कृपया बोर्ड निवडा';

  @override
  String get pleaseSelectStandard => 'कृपया इयत्ता निवडा';

  @override
  String pleaseEnterField(String field) {
    return 'कृपया $field टाका';
  }

  @override
  String get registrationFailed =>
      'नोंदणी सादर करता आली नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get studentDashboardTitle => 'विद्यार्थी डॅशबोर्ड';

  @override
  String get welcomeStudent => 'स्वागत आहे';

  @override
  String get myStudentHub => 'माझे विद्यार्थी केंद्र';

  @override
  String get tileAttendance => 'माझी उपस्थिती';

  @override
  String get tileAttendanceSub => 'इतिहास व आकडेवारी';

  @override
  String get tileHomework => 'गृहपाठ';

  @override
  String get tileHomeworkSub => 'बाकी कामे व फाइल्स';

  @override
  String get tileClasswork => 'वर्गकार्य';

  @override
  String get tileClassworkSub => 'नोट्स व फाइल्स';

  @override
  String get tileFees => 'माझ्या फीची स्थिती';

  @override
  String get tileFeesSub => 'भरणा नोंदी';

  @override
  String get tileChat => 'शंका विचारा';

  @override
  String get tileChatSub => 'शिक्षकांशी बोला';

  @override
  String get tileTimetable => 'वेळापत्रक';

  @override
  String get tileTimetableSub => 'वर्गाचे वेळापत्रक';

  @override
  String get tileAnnouncements => 'सूचना';

  @override
  String get tileAnnouncementsSub => 'नोटीस व सूचना';

  @override
  String navigateTo(String title) {
    return '$title उघडा';
  }

  @override
  String get attendanceTitle => 'माझी उपस्थिती';

  @override
  String get selectMonth => 'महिना निवडा';

  @override
  String get pickMonth => 'महिना निवडा';

  @override
  String get attendancePercent => 'उपस्थिती';

  @override
  String get presentDays => 'उपस्थित दिवस';

  @override
  String get absentDays => 'अनुपस्थित दिवस';

  @override
  String get noAttendanceRecords => 'अजून उपस्थितीची नोंद नाही.';

  @override
  String get statusPresent => 'उपस्थित';

  @override
  String get statusAbsent => 'अनुपस्थित';

  @override
  String reasonLabel(String reason) {
    return 'कारण: $reason';
  }

  @override
  String get couldNotLoadAttendance => 'उपस्थिती लोड करता आली नाही.';

  @override
  String get feesTitle => 'माझ्या फीची स्थिती';

  @override
  String get noFeeRecords => 'अजून फीची नोंद नाही.';

  @override
  String get expectedFee => 'फी';

  @override
  String get paidAmount => 'भरलेली';

  @override
  String get remainingAmount => 'बाकी';

  @override
  String get feeHistory => 'फी भरण्याचा इतिहास';

  @override
  String feeExpectedPaid(String expected, String paid) {
    return 'फी: ₹$expected • भरलेली: ₹$paid';
  }

  @override
  String feeRemainingShort(String amount) {
    return 'बाकी\n₹$amount';
  }

  @override
  String get couldNotLoadFees => 'फीची माहिती लोड करता आली नाही.';

  @override
  String get feeStatusPaid => 'भरले';

  @override
  String get feeStatusPartial => 'अंशतः भरले';

  @override
  String get feeStatusPending => 'प्रलंबित';

  @override
  String get homeworkTitle => 'माझा गृहपाठ';

  @override
  String get noActiveHomework => 'सध्या तुमच्या वर्गासाठी गृहपाठ नाही.';

  @override
  String get couldNotLoadHomework => 'गृहपाठ लोड करता आला नाही.';

  @override
  String dueDate(String date) {
    return 'अंतिम तारीख: $date';
  }

  @override
  String teacherName(String name) {
    return 'शिक्षक: $name';
  }

  @override
  String get classworkTitle => 'वर्गकार्य व अभ्यास नोट्स';

  @override
  String get noClasswork => 'अजून वर्गकार्य नोट्स नाहीत.';

  @override
  String get couldNotLoadClasswork => 'वर्गकार्य लोड करता आले नाही.';

  @override
  String publishedBy(String name) {
    return 'प्रकाशक: $name';
  }

  @override
  String attachmentsCount(String count) {
    return 'फाइल्स ($count)';
  }

  @override
  String get announcementsFeed => 'सूचना';

  @override
  String get noAnnouncements => 'अजून सूचना नाहीत.';

  @override
  String get couldNotLoadAnnouncements => 'सूचना लोड करता आल्या नाहीत.';

  @override
  String get newAnnouncement => 'नवीन सूचना';

  @override
  String get notificationsTitle => 'सूचना (नोटिफिकेशन)';

  @override
  String get noNotifications => 'अजून नोटिफिकेशन नाही.';

  @override
  String get couldNotLoadNotifications => 'नोटिफिकेशन लोड करता आले नाहीत.';

  @override
  String notificationsUnread(String count) {
    return 'नोटिफिकेशन ($count न वाचलेले)';
  }

  @override
  String get chatTitle => 'शंका निरसन चॅट';

  @override
  String get couldNotLoadChats => 'चॅट लोड करता आल्या नाहीत.';

  @override
  String get noChatsStudent =>
      'अजून संभाषण नाही.\nशिक्षकांशी बोलण्यासाठी \"शंका विचारा\" दाबा.';

  @override
  String get noChatsTeacher => 'अजून शंका आलेल्या नाहीत.';

  @override
  String get teacherFallback => 'शिक्षक';

  @override
  String get studentFallback => 'विद्यार्थी';

  @override
  String get noMessagesYet => 'अजून संदेश नाहीत';

  @override
  String get askDoubt => 'शंका विचारा';

  @override
  String get selectTeacherToAsk => 'शिक्षक निवडा';

  @override
  String get noActiveTeachers => 'कोणतेही शिक्षक उपलब्ध नाहीत.';

  @override
  String subjectsLabel(String subjects) {
    return 'विषय: $subjects';
  }

  @override
  String get chatRoomTitle => 'चॅट';

  @override
  String get loadingEllipsis => 'लोड होत आहे...';

  @override
  String get noMessagesTypeDoubt => 'अजून संदेश नाहीत. खाली तुमची शंका लिहा!';

  @override
  String get typeDoubtHint => 'येथे तुमची शंका लिहा...';

  @override
  String get sendMessage => 'संदेश पाठवा';

  @override
  String get failedToSend => 'संदेश पाठवता आला नाही. कृपया पुन्हा प्रयत्न करा.';

  @override
  String get couldNotLoadMessages => 'संदेश लोड करता आले नाहीत.';

  @override
  String get timetableTitle => 'माझे वर्गाचे वेळापत्रक';

  @override
  String get noClassesToday => 'या दिवशी वर्ग नाही.';

  @override
  String slotDetails(String end, String room, String start, String teacher) {
    return '$start - $end\nशिक्षक: $teacher • $room';
  }

  @override
  String slotDetailsNoRoom(String end, String start, String teacher) {
    return '$start - $end\nशिक्षक: $teacher';
  }

  @override
  String get couldNotLoadTimetable => 'वेळापत्रक लोड करता आले नाही.';

  @override
  String get tbd => 'नंतर कळवले जाईल';

  @override
  String get dayMonday => 'सोमवार';

  @override
  String get dayTuesday => 'मंगळवार';

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
