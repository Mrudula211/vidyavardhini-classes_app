import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../constants/routes.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/auth/screens/role_selection_screen.dart';
import '../../features/auth/screens/phone_entry_screen.dart';
import '../../features/auth/screens/otp_screen.dart';
import '../../features/auth/screens/admin_login_screen.dart';
import '../../features/auth/screens/teacher_login_screen.dart';
import '../../features/auth/screens/student_registration_screen.dart';
import '../../features/auth/screens/pending_approval_screen.dart';
import '../../features/admin/screens/admin_dashboard_screen.dart';
import '../../features/teacher/screens/teacher_dashboard_screen.dart';
import '../../features/student/screens/student_dashboard_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authStateProvider);
  final userRole = ref.watch(currentUserRoleProvider).valueOrNull;

  return GoRouter(
    initialLocation: Routes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuthRoute = state.uri.toString().startsWith('/auth') ||
          state.uri.toString() == Routes.roleSelect ||
          state.uri.toString() == Routes.splash;

      final session = authState.valueOrNull;

      if (session == null && !isAuthRoute) {
        return Routes.roleSelect;
      }

      if (session != null && userRole != null) {
        if (state.uri.toString().startsWith('/admin') && userRole != 'admin') {
           return Routes.roleSelect;
        }
        if (state.uri.toString().startsWith('/teacher') && userRole != 'teacher') {
           return Routes.roleSelect;
        }
        if (state.uri.toString().startsWith('/student') && userRole != 'student') {
           return Routes.roleSelect;
        }
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
        builder: (context, state) => const RoleSelectionScreen(),
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

      // Role dashboards
      GoRoute(
        path: Routes.adminDashboard,
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: Routes.teacherDashboard,
        builder: (context, state) => const TeacherDashboardScreen(),
      ),
      GoRoute(
        path: Routes.studentDashboard,
        builder: (context, state) => const StudentDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}
