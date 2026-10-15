# SITEMAP.md — Vidyavardhini Classes

## Navigation Overview

```
App Launch
  └── SplashScreen
        └── Role Selection
              ├── ADMIN ──────────────────────────────────────────────┐
              ├── TEACHER ─────────────────────────────────────────┐  │
              └── STUDENT ──────────────────────────────────────┐  │  │
                                                                │  │  │
Auth Flow (shared OTP step, then diverges)                      │  │  │
  Phone Entry → OTP Verify                                      │  │  │
                  ├── Admin: Access Code → Password ────────────┼──┼──┘
                  ├── Teacher: Access Code ─────────────────────┼──┘
                  └── Student: Registration Form ──────────────┘
                               or Password Login (returning)
```

---

## Auth Screens

| Route | Screen | Notes |
|---|---|---|
| `/` | SplashScreen | Checks session, redirects |
| `/role-select` | RoleSelectionScreen | 3 role cards |
| `/auth/phone` | PhoneEntryScreen | Shared for all roles |
| `/auth/otp` | OTPVerificationScreen | Shared for all roles |
| `/auth/admin-login` | AdminLoginScreen | Access code + password |
| `/auth/teacher-login` | TeacherLoginScreen | Access code only |
| `/auth/student-register` | StudentRegistrationScreen | Full registration form |
| `/auth/student-set-password` | StudentPasswordScreen | First login after approval (set password); router-enforced for active students without email |
| `/auth/pending` | PendingApprovalScreen | Shown until admin approves |
| `/notifications` | NotificationListScreen | Bell icon on all role dashboards; unread badge via `unreadNotificationCountProvider` |

---

## Admin Section

### Bottom Navigation (Admin Shell)
1. Dashboard
2. Students
3. Teachers
4. Finance
5. More (Settings, Audit, etc.)

### Admin Screens

```
/admin
  ├── /admin/dashboard
  │     Dashboard cards:
  │     - Total Students · Total Teachers
  │     - Present Today (Students) · Absent Today
  │     - Present Today (Teachers) · Absent Today
  │     - Pending Fee Amount
  │     - Pending Approvals count
  │     - Revenue Summary (This Month)
  │     Quick Actions:
  │     - Mark Holiday · Send Announcement · Add Teacher
  │
  ├── /admin/students
  │     ├── /admin/students/list
  │     │     Filter: All | Active | Pending | Inactive | Banned | Archived
  │     │     Search: Name / Phone / Student ID
  │     │     Sort: Name | ID | Standard | Date Added
  │     │
  │     ├── /admin/students/pending
  │     │     List of pending registrations
  │     │     Per card: Name · Phone · Board · Standard · Submitted date
  │     │     Actions: Approve | Reject | View Profile
  │     │
  │     ├── /admin/students/:id
  │     │     Student Detail (Tabs):
  │     │     ├── Profile Tab
  │     │     │     - Personal info, photo, status badge
  │     │     │     - Edit button (name, contact, status)
  │     │     ├── Attendance Tab
  │     │     │     - Monthly summary
  │     │     │     - Calendar/list view with dates + reasons
  │     │     └── Fees Tab
  │     │           - Monthly fee history
  │     │           - Per-month: expected/paid/remaining/status
  │     │           - Add Payment button
  │     │
  │     └── /admin/students/:id/approve
  │           Approval form:
  │           - Student ID (auto-suggested, editable)
  │           - Monthly fee amount
  │           - Confirm / Reject buttons
  │
  ├── /admin/teachers
  │     ├── /admin/teachers/list
  │     │     Search: Name / Teacher ID
  │     │     Per card: Photo · Name · ID · Subjects · Today's Status
  │     │
  │     ├── /admin/teachers/add
  │     │     Form: Name · Gender · DOB · Phone · Email ·
  │     │     Joining Date · Salary · Photo
  │     │     Assign Classes section
  │     │
  │     └── /admin/teachers/:id
  │           Teacher Detail (Tabs):
  │           ├── Profile Tab — personal info, edit
  │           ├── Classes Tab — assigned board/standard/subjects
  │           ├── Timetable Tab — weekly schedule (edit here)
  │           ├── Attendance Tab — calendar view + correction button
  │           └── Salary Tab
  │                 Monthly salary records
  │                 Present/absent days auto-calculated
  │                 Mark as Paid button
  │
  ├── /admin/fees
  │     ├── /admin/fees/overview
  │     │     Summary cards: Expected · Collected · Pending
  │     │     Student list with monthly status
  │     │     Filter: Board | Standard | Status | Month
  │     │
  │     ├── /admin/fees/:student_id/monthly
  │     │     Full fee history for a student (all months, current year)
  │     │
  │     └── /admin/fees/add-payment
  │           Payment form:
  │           - Student (picker)
  │           - Month/Year
  │           - Amount
  │           - Method (Cash/UPI/Bank/Cheque)
  │           - Date · Reference · Notes
  │
  ├── /admin/revenue
  │     ├── Monthly view (default — current month)
  │     │     Bar chart: expected vs collected
  │     │     Breakdown by standard / board
  │     │
  │     └── Yearly view (toggle)
  │           Line/bar chart: 12-month trend
  │           Total expected vs collected
  │
  ├── /admin/announcements
  │     ├── /admin/announcements/list
  │     │     Filter: General | Staff | Emergency | Active | Expired
  │     │     Per card: Title · Type badge · Date · Seen count
  │     │
  │     ├── /admin/announcements/create
  │     │     Form:
  │     │     - Type (General / Staff / Emergency)
  │     │     - Title · Content
  │     │     - Target: All | Board | Standard
  │     │     - Expiry date (optional)
  │     │     - Attach file (optional)
  │     │
  │     └── /admin/announcements/:id
  │           Full announcement + seen/not-seen lists
  │           (expandable: Not Seen By — list of names)
  │
  ├── /admin/attendance
  │     ├── Overview (Heatmap calendar)
  │     │     Month picker → colour-coded calendar
  │     │     Tap date → list of who was present/absent
  │     │
  │     └── /admin/attendance/teacher
  │           Teacher-specific view
  │           Correction button per date
  │           Correction form: new status + reason
  │
  └── /admin/settings
        ├── /admin/settings/geofence
        │     Map with pin + radius slider
        │     Lat/Lng display + Save button
        │
        ├── /admin/settings/academic-year
        │     Current year display
        │     Create new year
        │     Promote Students flow:
        │       Warning → CONFIRM text → Password → OTP → Execute
        │
        ├── /admin/settings/audit-logs
        │     Filterable log list
        │     Filter: Action type | Date range | User
        │     Tap entry → full detail (old/new values)
        │
        ├── /admin/settings/backup
        │     Backup history list
        │     Trigger Backup button
        │     Restore button (per backup)
        │
        └── /admin/settings/profile
              Admin's own profile view + edit
```

---

## Teacher Section

### Bottom Navigation (Teacher Shell)
1. Dashboard
2. Attendance
3. Homework
4. Classwork
5. Chat

### Teacher Screens

```
/teacher
  ├── /teacher/dashboard
  │     Cards:
  │     - Today's Classes
  │     - Pending homework uploads
  │     - Unread messages count
  │     - Salary this month (earned)
  │     Today's Timetable widget
  │     Announcements feed (general + staff)
  │
  ├── /teacher/attendance
  │     Class selector (dropdown: Board + Standard)
  │     Date picker (default: today)
  │     Student list with Present/Absent toggle per student
  │     Absent reason selector (when Absent tapped)
  │     Submit button
  │
  ├── /teacher/homework
  │     ├── /teacher/homework/list
  │     │     Filter: All | Recent | By Class
  │     │     Per card: Subject · Class · Due Date · Attachment icons
  │     │
  │     └── /teacher/homework/create
  │           Form:
  │           - Class (Board + Standard — from assigned classes)
  │           - Subject
  │           - Title
  │           - Description
  │           - Due Date
  │           - Attach: Image | PDF | Text note
  │           (multiple attachments allowed)
  │
  ├── /teacher/classwork
  │     ├── /teacher/classwork/list
  │     │     Filter by class / date
  │     │
  │     └── /teacher/classwork/create
  │           Form:
  │           - Class · Subject · Title · Description
  │           - Attach: Image | PDF (board photos, notes)
  │
  ├── /teacher/chat
  │     ├── /teacher/chat/list
  │     │     Student conversation list
  │     │     Sorted by latest message
  │     │     Unread badge per chat
  │     │
  │     └── /teacher/chat/:room_id
  │           Chat screen (Realtime)
  │           Text + file attach
  │           Seen indicator
  │
  ├── /teacher/timetable
  │     Weekly grid view
  │     Day tabs (Mon–Sat)
  │     Per slot: Class · Subject · Time
  │     (Read-only)
  │
  ├── /teacher/salary
  │     Current month card:
  │     - Monthly Salary · Working Days · Present · Absent
  │     - Daily Rate · Earned Salary · Status · Payment Date
  │     Previous months list (current year only)
  │
  └── /teacher/profile
        Personal info display
        Photo
        Assigned classes list
        (Read-only, contact admin to edit)
```

---

## Student Section

### Bottom Navigation (Student Shell)
1. Home
2. Homework
3. Attendance
4. Fees
5. Chat

### Student Screens

```
/student
  ├── /student/dashboard (Home)
  │     Announcements carousel (pinned/recent)
  │     Recent Homework cards
  │     Attendance summary chip (e.g. 91%)
  │     Fee status chip (Paid / ₹500 Pending)
  │     Unread messages count
  │
  ├── /student/homework
  │     ├── /student/homework/list
  │     │     Filter: All | Due Soon | By Subject
  │     │     Per card: Subject · Due Date · Teacher · Attachment count
  │     │
  │     └── /student/homework/:id
  │           Full homework detail:
  │           - Title · Subject · Teacher · Due Date
  │           - Description
  │           - Attachments (tap to view image / open PDF)
  │
  ├── /student/classwork
  │     ├── /student/classwork/list
  │     │     Filter by subject / date
  │     │
  │     └── /student/classwork/:id
  │           Detail + attachments
  │
  ├── /student/attendance
  │     Summary bar: Present | Absent | Percentage
  │     Calendar or list view
  │     Per-day: Date | Status badge | Reason (if absent)
  │     Month picker
  │
  ├── /student/fees
  │     Current month status (prominent card)
  │     Monthly fee history (current year)
  │     Per month:
  │     - Month name
  │     - Expected · Paid · Remaining
  │     - Status badge (Pending / Partial / Paid)
  │     - Payment date + method (if paid)
  │
  ├── /student/chat
  │     ├── /student/chat/list
  │     │     Teachers available for doubt chat
  │     │     (Only assigned teachers)
  │     │
  │     └── /student/chat/:room_id
  │           Real-time chat with teacher
  │           Text + image attach
  │
  ├── /student/announcements
  │     ├── /student/announcements/list
  │     │     General announcements only (not staff)
  │     │     Emergency shown at top with banner
  │     │
  │     └── /student/announcements/:id
  │           Full announcement view
  │
  └── /student/profile
        Personal info (read-only)
        Board · Standard · Student ID
        School Name
        Contact admin to update info
```

---

## Shared / System Screens

| Screen | Shown When |
|---|---|
| NoInternetScreen | Device offline |
| MaintenanceScreen | Backend unreachable |
| ForceUpdateScreen | App version too old |
| NotificationListScreen | All roles — notification bell icon |
| ImageViewerScreen | Full-screen image view (homework/classwork) |
| PDFViewerScreen | PDF reader (all file contexts) |
| EmergencyAnnouncementPopup | On login if unread emergency exists |

---

## Navigation Flow Diagrams

### Student First-Time Flow
```
Download App
  → SplashScreen
  → RoleSelectionScreen (Student)
  → PhoneEntryScreen
  → OTPScreen
  → StudentRegistrationScreen (form fill)
  → PendingApprovalScreen ← stays here until admin approves
  [Admin approves]
  → Push notification: "Your registration is approved!"
  → App notifies student → SetPasswordScreen (first login only)
  → StudentDashboard
```

### Admin Student Approval Flow
```
AdminDashboard (pending count badge)
  → /admin/students/pending
  → tap student card
  → review profile
  → Approve: enter Student ID (pre-filled), set monthly fee
  → Confirm → student activated → push notification sent
```

### Fee Payment Flow
```
AdminDashboard
  → /admin/fees/overview
  → select student (or search)
  → /admin/fees/:id/monthly
  → tap month with Pending/Partial status
  → Add Payment sheet:
      amount · method · date · reference
  → Save → audit log created → student fee updated
```

### Student Promotion Flow
```
/admin/settings/academic-year
  → "Promote Students" button
  → Warning dialog (explains what happens)
  → Type CONFIRM in text field
  → Enter Admin Password
  → OTP sent to admin phone
  → Enter OTP
  → Confirm
  → Background job runs promotion
  → Success screen with stats: X students promoted
```
