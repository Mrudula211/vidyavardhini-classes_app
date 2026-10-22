class Routes {
  Routes._();

  // Auth
  static const String splash = '/';
  static const String roleSelect = '/role-select';
  static const String login = '/auth/login';
  static const String createAccount = '/auth/create-account';
  static const String newPassword = '/auth/new-password';
  static const String otp = '/auth/otp';
  static const String adminLogin = '/auth/admin-login';
  static const String teacherLogin = '/auth/teacher-login';
  static const String studentRegister = '/auth/student-register';
  static const String studentSetPassword = '/auth/student-set-password';
  static const String pendingApproval = '/auth/pending';

  // Admin shell
  static const String adminDashboard = '/admin/dashboard';
  static const String adminStudents = '/admin/students';
  static const String adminStudentDetail = '/admin/students/:id';
  static const String adminStudentApprove = '/admin/students/:id/approve';
  static const String adminTeachers = '/admin/teachers';
  static const String adminTeacherAdd = '/admin/teachers/add';
  static const String adminTeacherDetail = '/admin/teachers/:id';
  static const String adminFees = '/admin/fees';
  static const String adminRevenue = '/admin/revenue';
  static const String adminAnnouncementCreate = '/admin/announcements/create';
  static const String adminAttendance = '/admin/attendance';
  static const String adminGeofence = '/admin/settings/geofence';
  static const String adminAcademicYear = '/admin/settings/academic-year';
  static const String adminAuditLogs = '/admin/settings/audit-logs';
  static const String adminBackup = '/admin/settings/backup';

  // Teacher shell
  static const String teacherDashboard = '/teacher/dashboard';
  static const String teacherAttendance = '/teacher/attendance';
  static const String teacherCheckIn = '/teacher/check-in';
  static const String teacherHomework = '/teacher/homework';
  static const String teacherHomeworkCreate = '/teacher/homework/create';
  static const String teacherClasswork = '/teacher/classwork';
  static const String teacherClassworkCreate = '/teacher/classwork/create';
  static const String teacherSalary = '/teacher/salary';

  // Student shell
  static const String studentDashboard = '/student/dashboard';
  static const String studentHomework = '/student/homework';
  static const String studentClasswork = '/student/classwork';
  static const String studentAttendance = '/student/attendance';
  static const String studentFees = '/student/fees';

  // Shared
  static const String announcementList = '/announcements';
  static const String adminTimetable = '/admin/timetable';
  static const String userTimetable = '/timetable';
  static const String chatList = '/chat';
  static const String chatRoom = '/chat/:roomId';
  static const String notifications = '/notifications';
}
