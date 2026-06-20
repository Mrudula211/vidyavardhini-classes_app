class Routes {
  Routes._();

  // Auth
  static const String splash = '/';
  static const String roleSelect = '/role-select';
  static const String phone = '/auth/phone';
  static const String otp = '/auth/otp';
  static const String adminLogin = '/auth/admin-login';
  static const String teacherLogin = '/auth/teacher-login';
  static const String studentRegister = '/auth/student-register';
  static const String studentSetPassword = '/auth/student-set-password';
  static const String pendingApproval = '/auth/pending';

  // Admin shell
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStudents = '/admin/students';
  static const String adminStudentsPending = '/admin/students/pending';
  static const String adminStudentDetail = '/admin/students/:id';
  static const String adminStudentApprove = '/admin/students/:id/approve';
  static const String adminTeachers = '/admin/teachers';
  static const String adminTeacherAdd = '/admin/teachers/add';
  static const String adminTeacherDetail = '/admin/teachers/:id';
  static const String adminFees = '/admin/fees';
  static const String adminStudentFees = '/admin/fees/:studentId';
  static const String adminRevenue = '/admin/revenue';
  static const String adminAnnouncements = '/admin/announcements';
  static const String adminAnnouncementCreate = '/admin/announcements/create';
  static const String adminAnnouncementDetail = '/admin/announcements/:id';
  static const String adminAttendance = '/admin/attendance';
  static const String adminSettings = '/admin/settings';
  static const String adminGeofence = '/admin/settings/geofence';
  static const String adminAcademicYear = '/admin/settings/academic-year';
  static const String adminAuditLogs = '/admin/settings/audit-logs';
  static const String adminBackup = '/admin/settings/backup';

  // Teacher shell
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherHomework = '/teacher/homework';
  static const String teacherHomeworkCreate = '/teacher/homework/create';
  static const String teacherClasswork = '/teacher/classwork';
  static const String teacherClassworkCreate = '/teacher/classwork/create';
  static const String teacherChat = '/teacher/chat';
  static const String teacherChatRoom = '/teacher/chat/:roomId';
  static const String teacherTimetable = '/teacher/timetable';
  static const String teacherSalary = '/teacher/salary';
  static const String teacherProfile = '/teacher/profile';

  // Student shell
  static const String studentDashboard = '/student/dashboard';
  static const String studentHomework = '/student/homework';
  static const String studentHomeworkDetail = '/student/homework/:id';
  static const String studentClasswork = '/student/classwork';
  static const String studentClassworkDetail = '/student/classwork/:id';
  static const String studentAttendance = '/student/attendance';
  static const String studentFees = '/student/fees';
  static const String studentChat = '/student/chat';
  static const String studentChatRoom = '/student/chat/:roomId';
  static const String studentAnnouncements = '/student/announcements';
  static const String studentAnnouncementDetail = '/student/announcements/:id';
  static const String studentProfile = '/student/profile';

  // Shared
  static const String notifications = '/notifications';
  static const String pdfViewer = '/pdf-viewer';
  static const String imageViewer = '/image-viewer';
}
