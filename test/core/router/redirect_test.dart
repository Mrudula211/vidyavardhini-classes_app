import 'package:flutter_test/flutter_test.dart';
import 'package:vidyavardhini_classes/core/constants/routes.dart';
import 'package:vidyavardhini_classes/core/router/app_router.dart';

AuthRedirect _decide({
  String uri = '/',
  bool authLoading = false,
  bool hasSession = true,
  bool roleLoading = false,
  String? role,
  bool statusLoading = false,
  String? status,
  bool adminVerified = false,
  bool teacherVerified = false,
}) =>
    decideRedirect(
      uri: uri,
      authLoading: authLoading,
      hasSession: hasSession,
      roleLoading: roleLoading,
      role: role,
      statusLoading: statusLoading,
      status: status,
      adminVerified: adminVerified,
      teacherVerified: teacherVerified,
    );

void main() {
  group('no session', () {
    test('stays on login screens, bounces everything else to Welcome', () {
      expect(_decide(hasSession: false, uri: Routes.login).location, isNull);
      expect(
        _decide(hasSession: false, uri: Routes.adminDashboard).location,
        Routes.roleSelect,
      );
    });
  });

  group('never strands the user on the splash screen', () {
    test('signed in but role unknown -> Welcome, not splash', () {
      expect(
        _decide(uri: Routes.splash, role: null).location,
        Routes.roleSelect,
      );
    });

    test('waits only while things are actually loading', () {
      expect(_decide(authLoading: true).location, Routes.splash);
      expect(_decide(roleLoading: true).location, Routes.splash);
    });

    test('approved student on splash goes to the dashboard', () {
      expect(
        _decide(uri: Routes.splash, role: 'student', status: 'active').location,
        Routes.studentDashboard,
      );
    });
  });

  group('students', () {
    test('a login without a student profile gets no access', () {
      final d = _decide(uri: Routes.splash, role: 'student', status: null);
      expect(d.signOut, isTrue);
      expect(d.location, Routes.roleSelect);
    });

    test('an approved student goes straight to the dashboard', () {
      expect(
        _decide(uri: Routes.splash, role: 'student', status: 'active').location,
        Routes.studentDashboard,
      );
      expect(
        _decide(
          uri: Routes.studentDashboard,
          role: 'student',
          status: 'active',
        ).location,
        isNull,
      );
    });

    test('pending student is parked on the waiting screen', () {
      expect(
        _decide(
          uri: Routes.studentDashboard,
          role: 'student',
          status: 'pending',
        ).location,
        Routes.pendingApproval,
      );
    });

    test('rejected or banned students are signed out', () {
      final d = _decide(role: 'student', status: 'banned');
      expect(d.signOut, isTrue);
      expect(d.location, Routes.roleSelect);
    });

    test('students cannot open admin or teacher areas', () {
      expect(
        _decide(uri: Routes.adminDashboard, role: 'student', status: 'active')
            .location,
        Routes.studentDashboard,
      );
    });
  });

  group('admin and teacher second step', () {
    test('held on their access-code screen until verified', () {
      expect(
        _decide(uri: Routes.adminDashboard, role: 'admin').location,
        Routes.adminLogin,
      );
      expect(
        _decide(uri: Routes.adminLogin, role: 'admin').location,
        isNull,
      );
      expect(
        _decide(uri: Routes.teacherDashboard, role: 'teacher').location,
        Routes.teacherLogin,
      );
    });

    test('verified admin reaches the dashboard and leaves login screens', () {
      expect(
        _decide(
          uri: Routes.adminDashboard,
          role: 'admin',
          adminVerified: true,
        ).location,
        isNull,
      );
      expect(
        _decide(uri: Routes.adminLogin, role: 'admin', adminVerified: true)
            .location,
        Routes.adminDashboard,
      );
    });

    test('a teacher cannot open admin routes even when verified', () {
      expect(
        _decide(
          uri: Routes.adminFees,
          role: 'teacher',
          teacherVerified: true,
        ).location,
        Routes.teacherDashboard,
      );
    });
  });

  group('forgotten-password flow', () {
    test('the new-password screen is reachable before the access-code step',
        () {
      expect(_decide(uri: Routes.newPassword, role: 'admin').location, isNull);
      expect(
        _decide(uri: Routes.newPassword, role: 'teacher').location,
        isNull,
      );
    });

    test('the email-code screen is a login-area page', () {
      expect(_decide(hasSession: false, uri: Routes.otp).location, isNull);
    });
  });
}
