import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../constants/routes.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/welcome_screen.dart';
import '../../features/auth/screens/phone_entry_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/teacher_login_screen.dart';
import '../../features/auth/screens/student_registration_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/auth/screens/student_password_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/admin/students/screens/student_list_screen.dart';
import '../../features/admin/students/screens/student_approval_screen.dart';
import '../../features/admin/students/screens/student_detail_screen.dart';
import '../../features/admin/teachers/screens/teacher_list_screen.dart';
import '../../features/admin/teachers/screens/add_teacher_screen.dart';
import '../../features/admin/teachers/screens/teacher_detail_screen.dart';
import '../../features/admin/attendance/screens/admin_attendance_screen.dart';
import '../../features/admin/fees/screens/fee_overview_screen.dart';
import '../../features/admin/revenue/screens/revenue_screen.dart';
import '../../features/admin/settings/geofence_settings_screen.dart';
import '../../features/admin/audit_logs/screens/audit_logs_screen.dart';
import '../../features/admin/backup/screens/backup_screen.dart';
import '../../features/admin/promotion/screens/promotion_screen.dart';
import '../../features/teacher/attendance/screens/teacher_checkin_screen.dart';
import '../../features/admin/announcements/screens/announcement_create_screen.dart';
import '../../features/admin/timetable/screens/admin_timetable_screen.dart';
import '../../features/announcements/screens/announcement_list_screen.dart';
import '../../features/timetable/screens/user_timetable_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/notifications/screens/notification_list_screen.dart';
import '../../features/chat/screens/chat_room_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/teacher/attendance/screens/attendance_mark_screen.dart';
import '../../features/teacher/homework/screens/homework_create_screen.dart';
import '../../features/teacher/homework/screens/teacher_homework_list_screen.dart';
import '../../features/teacher/classwork/screens/classwork_create_screen.dart';
import '../../features/teacher/classwork/screens/teacher_classwork_list_screen.dart';
import '../../features/teacher/salary/screens/teacher_salary_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';
import '../../features/student/attendance/screens/student_attendance_screen.dart';
import '../../features/student/fees/screens/student_fees_screen.dart';
import '../../features/student/homework/screens/student_homework_list_screen.dart';
import '../../features/student/classwork/screens/student_classwork_list_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(currentUserRoleProvider);
  final isAdminLoggedIn = ref.watch(adminAuthenticatedProvider);
  final isTeacherLoggedIn = ref.watch(teacherAuthenticatedProvider);
  final studentStatus = ref.watch(currentStudentStatusProvider);

  // The access-code step is only valid for the session it was passed in.
  // Clear it on logout or when a different account signs in.
  ref.listen<String?>(currentUserIdProvider, (previous, next) {
    if (next == null || (previous != null && previous != next)) {
      ref.read(adminAuthenticatedProvider.notifier).state = false;
      ref.read(teacherAuthenticatedProvider.notifier).state = false;
    }
  });

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) async {
      final uri = state.uri.toString();
      final isAuthRoute = uri.startsWith('/auth') ||
          uri == Routes.roleSelect ||
          uri == Routes.splash;

      if (authState.isLoading) {
        return Routes.splash;
      }

      // Everything beyond the auth screens needs a real Supabase session:
      // all data access is enforced against it by row-level security.
      final session = authState.value;
      if (session == null) {
        return isAuthRoute ? null : Routes.roleSelect;
      }

      if (userRole.isLoading) {
        return Routes.splash; // Wait for role
      }

      final role = userRole.value;
      if (role == null) {
        return isAuthRoute ? null : Routes.roleSelect;
      }

      // A student's account must be 'active' to use the app. Pending
      // students are parked on the pending-approval screen; rejected/banned
      // students are signed out immediately, even if they still hold a
      // valid Supabase session token.
      if (role == 'student') {
        if (studentStatus.isLoading) {
          return Routes.splash;
        }
        final status = studentStatus.value;
        if (status == 'rejected' || status == 'banned') {
          await Supabase.instance.client.auth.signOut();
          return Routes.roleSelect;
        }
        if (status == null || status == 'pending') {
          // New students finish registration; submitted ones wait.
          if (uri == Routes.studentRegister) return null;
          if (uri != Routes.pendingApproval) {
            return status == null
                ? Routes.studentRegister
                : Routes.pendingApproval;
          }
          return null;
        }

        // Active students without an email/password must set one before
        // reaching student routes (splash already does this once; enforce
        // here too so deep links cannot skip the step).
        final email = session.user.email;
        final needsPassword = email == null || email.trim().isEmpty;
        if (needsPassword && uri != Routes.studentSetPassword) {
          return Routes.studentSetPassword;
        }
        if (!needsPassword && uri == Routes.studentSetPassword) {
          return Routes.studentDashboard;
        }
      }

      // Admin and teacher sign in once more with their access code. Until
      // that is done, the only place they may be is that step.
      if (role == 'admin' && !isAdminLoggedIn) {
        return uri == Routes.adminLogin ? null : Routes.adminLogin;
      }
      if (role == 'teacher' && !isTeacherLoggedIn) {
        return uri == Routes.teacherLogin ? null : Routes.teacherLogin;
      }

      // Check route against roles
      if (uri.startsWith('/admin') && role != 'admin') {
        return _getDashboardRoute(role);
      }
      if (uri.startsWith('/teacher') && role != 'teacher') {
        return _getDashboardRoute(role);
      }
      if (uri.startsWith('/student') && role != 'student') {
        return _getDashboardRoute(role);
      }

      // Signed-in people never need the login screens again.
      if (isAuthRoute &&
          uri != Routes.splash &&
          uri != Routes.pendingApproval &&
          uri != Routes.studentSetPassword) {
        return _getDashboardRoute(role);
      }

      return null;
    },
    routes: [
      // Auth
      GoRoute(
        path: Routes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: Routes.roleSelect,
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: Routes.phone,
        builder: (context, state) => const PhoneEntryScreen(),
      ),
      GoRoute(
        path: Routes.otp,
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: Routes.adminLogin,
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: Routes.teacherLogin,
        builder: (context, state) => const TeacherLoginScreen(),
      ),
      GoRoute(
        path: Routes.studentRegister,
        builder: (context, state) => const StudentRegistrationScreen(),
      ),
      GoRoute(
        path: Routes.pendingApproval,
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: Routes.studentSetPassword,
        builder: (context, state) => const StudentPasswordScreen(),
      ),

      // Role dashboards
      GoRoute(
        path: Routes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.adminStudents,
        builder: (context, state) => const StudentListScreen(),
      ),
      GoRoute(
        path: Routes.adminStudentApprove,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return StudentApprovalScreen(studentId: id);
        },
      ),
      GoRoute(
        path: Routes.adminStudentDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return StudentDetailScreen(studentId: id);
        },
      ),
      GoRoute(
        path: Routes.adminTeachers,
        builder: (context, state) => const TeacherListScreen(),
      ),
      GoRoute(
        path: Routes.adminTeacherAdd,
        builder: (context, state) => const AddTeacherScreen(),
      ),
      GoRoute(
        path: Routes.adminTeacherDetail,
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? '';
          return TeacherDetailScreen(teacherId: id);
        },
      ),
      GoRoute(
        path: Routes.adminFees,
        builder: (context, state) => const FeeOverviewScreen(),
      ),
      GoRoute(
        path: Routes.adminRevenue,
        builder: (context, state) => const RevenueScreen(),
      ),
      GoRoute(
        path: Routes.adminAttendance,
        builder: (context, state) => const AdminAttendanceScreen(),
      ),
      GoRoute(
        path: Routes.adminGeofence,
        builder: (context, state) => const GeofenceSettingsScreen(),
      ),
      GoRoute(
        path: Routes.adminAuditLogs,
        builder: (context, state) => const AuditLogsScreen(),
      ),
      GoRoute(
        path: Routes.adminAcademicYear,
        builder: (context, state) => const PromotionScreen(),
      ),
      GoRoute(
        path: Routes.adminBackup,
        builder: (context, state) => const BackupScreen(),
      ),
      GoRoute(
        path: Routes.adminAnnouncementCreate,
        builder: (context, state) => const AnnouncementCreateScreen(),
      ),
      GoRoute(
        path: Routes.adminTimetable,
        builder: (context, state) => const AdminTimetableScreen(),
      ),
      GoRoute(
        path: Routes.announcementList,
        builder: (context, state) => const AnnouncementListScreen(),
      ),
      GoRoute(
        path: Routes.notifications,
        builder: (context, state) => const NotificationListScreen(),
      ),
      GoRoute(
        path: Routes.userTimetable,
        builder: (context, state) => const UserTimetableScreen(),
      ),
      GoRoute(
        path: Routes.chatList,
        builder: (context, state) => const ChatListScreen(),
      ),
      GoRoute(
        path: Routes.chatRoom,
        builder: (context, state) {
          final roomId = state.pathParameters['roomId'] ?? '';
          return ChatRoomScreen(roomId: roomId);
        },
      ),
      GoRoute(
        path: Routes.teacherDashboard,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: Routes.teacherCheckIn,
        builder: (context, state) => const TeacherCheckInScreen(),
      ),
      GoRoute(
        path: Routes.teacherAttendance,
        builder: (context, state) => const AttendanceMarkScreen(),
      ),
      GoRoute(
        path: Routes.teacherHomework,
        builder: (context, state) => const TeacherHomeworkListScreen(),
      ),
      GoRoute(
        path: Routes.teacherHomeworkCreate,
        builder: (context, state) => const HomeworkCreateScreen(),
      ),
      GoRoute(
        path: Routes.teacherClasswork,
        builder: (context, state) => const TeacherClassworkListScreen(),
      ),
      GoRoute(
        path: Routes.teacherClassworkCreate,
        builder: (context, state) => const ClassworkCreateScreen(),
      ),
      GoRoute(
        path: Routes.teacherSalary,
        builder: (context, state) => const TeacherSalaryScreen(),
      ),
      GoRoute(
        path: Routes.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
      GoRoute(
        path: Routes.studentAttendance,
        builder: (context, state) => const StudentAttendanceScreen(),
      ),
      GoRoute(
        path: Routes.studentFees,
        builder: (context, state) => const StudentFeesScreen(),
      ),
      GoRoute(
        path: Routes.studentHomework,
        builder: (context, state) => const StudentHomeworkListScreen(),
      ),
      GoRoute(
        path: Routes.studentClasswork,
        builder: (context, state) => const StudentClassworkListScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

String _getDashboardRoute(String role) {
  switch (role) {
    case 'admin':
      return Routes.adminDashboard;
    case 'teacher':
      return Routes.teacherDashboard;
    case 'student':
      return Routes.studentDashboard;
    default:
      return Routes.roleSelect;
  }
}
