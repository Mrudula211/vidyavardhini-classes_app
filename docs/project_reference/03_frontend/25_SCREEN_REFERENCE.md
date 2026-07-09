# 25 Screen Reference

## Purpose
Provides a master list of all screens in the application, their routes, required state, and intended functionality.

## Auth Flow Screens
- **SplashScreen (`/`)**: Initializes services, checks auth, redirects.
- **RoleSelectionScreen (`/role-select`)**: User picks Admin, Teacher, or Student.
- **PhoneEntryScreen (`/auth/phone`)**: Input phone number -> triggers OTP.
- **OtpScreen (`/auth/otp`)**: Validates OTP.
- **StudentRegistrationScreen (`/auth/student-register`)**: Form for new students (Name, Board, Standard).
- **PendingApprovalScreen (`/auth/pending`)**: Static screen for students waiting for admin approval.
- **AdminLoginScreen (`/auth/admin-login`)**: Access code + Password entry.
- **TeacherLoginScreen (`/auth/teacher-login`)**: Access code entry.

## Admin Screens (ShellRoute: `/admin`)
- **AdminDashboardScreen (`/admin/dashboard`)**: Summary cards (Stats, Revenue, Pending approvals).
- **StudentListScreen (`/admin/students`)**: Searchable list of students.
- **StudentDetailScreen (`/admin/students/:id`)**: View/Edit profile, fees, attendance history.
- **TeacherListScreen (`/admin/teachers`)**: List of staff.
- **FeeOverviewScreen (`/admin/fees`)**: Summary of expected vs collected fees.
- **AddPaymentSheet (Bottom Sheet)**: Form to record fee collection.
- **SettingsScreen (`/admin/settings`)**: Geofence config, Academic year promotion, Audit logs.

## Teacher Screens (ShellRoute: `/teacher`)
- **TeacherDashboardScreen (`/teacher/dashboard`)**: Today's classes, pending tasks.
- **MarkAttendanceScreen (`/teacher/attendance`)**: Class selector, date picker, present/absent toggles.
- **HomeworkListScreen (`/teacher/homework`)**: List of assigned homework.
- **CreateHomeworkScreen (`/teacher/homework/create`)**: Form + multi-file picker.
- **TeacherSalaryScreen (`/teacher/salary`)**: Read-only view of monthly earnings.

## Student Screens (ShellRoute: `/student`)
- **StudentDashboardScreen (`/student/dashboard`)**: Announcements carousel, recent homework.
- **StudentHomeworkScreen (`/student/homework`)**: Filterable list of homework.
- **StudentAttendanceScreen (`/student/attendance`)**: Calendar heatmap of attendance.
- **StudentFeesScreen (`/student/fees`)**: Month-by-month fee status (Paid, Pending).

## Shared Screens
- **ChatListScreen (`/.../chat`)**: List of active doubt-clearing conversations.
- **ChatRoomScreen (`/.../chat/:id`)**: Real-time messaging UI.
- **ImageViewer / PDFViewer**: Full-screen media viewing for attachments.

## Cross-References
- [08_NAVIGATION.md](08_NAVIGATION.md)
- [07_UI_ANALYSIS.md](07_UI_ANALYSIS.md)
