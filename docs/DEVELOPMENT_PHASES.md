# DEVELOPMENT_PHASES.md — Vidyavardhini Classes

## Overview

10-phase incremental build. Each phase produces a working, testable increment.  
Phases 1–5 are the MVP needed for launch. Phases 6–10 add the full feature set.

---

## Phase 0 — Project Setup (Pre-development)

**Goal:** Working skeleton. Everyone can run the app on a device.

### Tasks

- [ ] Create Flutter project (`flutter create`) ← **FLUTTER NOT YET INSTALLED**
- [x] Set up Supabase project — URL: https://rcocjtblpbbslrivqpmm.supabase.co
- [x] Configure Firebase project — Package: com.vidyavardhini.classes
- [x] Add all dependencies to `pubspec.yaml`
- [x] Configure `go_router` with placeholder routes (`lib/core/router/app_router.dart`)
- [x] Set up Riverpod `ProviderScope` in `main.dart`
- [x] Set up Material 3 theme (light + dark) with brand colours
- [x] Configure Supabase client initialisation
- [ ] Set up build flavors (dev / prod)
- [x] Apply database migration 001 in Supabase SQL Editor
- [x] Apply database migration 002 in Supabase SQL Editor
- [x] Apply database migration 003 in Supabase SQL Editor
- [x] Configure Hive for local caching (in main.dart)
- [x] Set up `analysis_options.yaml` with strict lint rules
- [x] Set up `build_runner` for code generation (in pubspec.yaml)
- [x] Create `supabase/migrations/001_initial_schema.sql`
- [x] Create `supabase/migrations/002_triggers_functions.sql`
- [x] Create `supabase/migrations/003_auth_rpc.sql`
- [x] Create `supabase/migrations/004_seed_admin.sql`
- [ ] Move `google-services.json` to `android/app/` (after `flutter create`)

**Deliverable:** App launches, shows theme colours, Supabase connected.

---

## Phase 1 — Authentication

**Goal:** All three roles can log in and land on their correct dashboard shell.

### Tasks

#### Shared Auth
- [x] `SplashScreen` — check session, redirect by role or to role-select
- [x] `RoleSelectionScreen` — 3 role cards (Admin / Teacher / Student)
- [x] `PhoneEntryScreen` — phone number input with country code
- [x] `OTPVerificationScreen` — 6-digit OTP input, resend timer
- [x] Supabase OTP integration (`signInWithOtp`, `verifyOtp`)
- [x] Store role in `users` table on first login
- [ ] JWT role claim setup (Supabase Auth hook)

#### Admin Auth
- [x] `AdminLoginScreen` — access code input + password input
- [x] Hash comparison for access code + password
- [x] Redirect to `AdminShell`

#### Teacher Auth
- [x] `TeacherLoginScreen` — access code input
- [x] Hash comparison for teacher access code
- [x] Redirect to `TeacherShell`

#### Student Auth (Registration)
- [x] `StudentRegistrationScreen` — full 10-field form + photo upload
- [x] Form validation
- [x] Upload profile photo to `profile-photos` bucket
- [x] Insert into `student_profiles` with status = `pending`
- [x] `PendingApprovalScreen` — shown until admin approves

#### Student Auth (Returning)
- [ ] `StudentPasswordScreen` — first login after approval (set password)
- [x] Standard login with phone + OTP for returning students

#### Route Guards
- [x] GoRouter `redirect` logic based on `authStateProvider`
- [x] Role-based shell routing
- [x] Unapproved student guard → `PendingApprovalScreen`

#### Auth Provider
- [x] `authStateProvider` (stream)
- [x] `currentUserProvider` (async, derives from auth + users table)
- [x] `authRepositoryProvider`

**Deliverable:** All three roles can complete their login flows end-to-end.

---

## Phase 2 — Student Management (Admin)

**Goal:** Admin can view, approve, reject, and manage all students.

### Tasks

- [x] `StudentListScreen` — filterable/searchable student list
  - Filters: All | Active | Pending | Inactive | Banned | Rejected
  - Search by: Name / Phone / Student ID
- [x] `StudentDetailScreen` — profile tab
- [x] `StudentApprovalScreen`
  - Show registration details
  - Suggest next Student ID (`next_student_id()` function call)
  - Admin edits ID if needed
  - Set monthly fee
  - Confirm → approve → create `fee_structure` & `student_enrollments`
- [x] Reject flow — reason input
- [x] Ban flow — confirmation dialog → status = banned
- [x] Edit student profile (admin can edit name, contact, board, standard)
- [x] Student search provider (debounced)
- [x] `studentListProvider`, `pendingStudentsProvider`
- [x] Pending approval badge on admin dashboard

**Deliverable:** Admin can fully manage student lifecycle.

---

## Phase 3 — Teacher Management (Admin)

**Goal:** Admin can add teachers, assign classes, and manage profiles.

### Tasks

- [x] `TeacherListScreen` — search by name / teacher ID
- [x] `AddTeacherScreen` — profile form + access code generation
  - Auto-generate Teacher ID (`TCH0001` format)
  - Generate unique access code, show once, then hash and store
- [x] `TeacherDetailScreen` (tabs)
  - Profile tab — view + edit
  - Classes tab — assigned board/standard/subjects
  - Salary tab — monthly salary editor
- [x] Class assignment UI — board/standard/subject chips
- [x] `teacherListProvider`, `teacherDetailProvider`

**Deliverable:** Admin can add teachers and configure their access.

---

## Phase 4 — Attendance

**Goal:** Teachers mark student attendance; admin and students can view it.

### Tasks

#### Teacher — Mark Attendance
- [x] `AttendanceMarkScreen`
  - Class selector (dropdown: board + standard, from assignments)
  - Date picker (default today)
  - Student list with Present/Absent toggle
  - Absent: slide/expand to reveal reason selector
  - Submit button — batch upsert to `student_attendance` + `absence_reasons`

#### Student — View Attendance
- [x] `StudentAttendanceScreen`
  - Summary row: Present N | Absent N | N%
  - Month picker
  - List view per date: date | status badge | reason

#### Admin — Overview
- [x] `AttendanceOverviewScreen`
  - Filter by date, board + standard
  - List of present & absent students

#### Teacher Attendance (Geofence)
- [x] `GeofenceService` — position distance calculation & auto check-in logic
- [x] `GeofenceSettingsScreen` (admin) — coordinates + radius input

**Deliverable:** End-to-end attendance tracking for students and teachers.

---

## Phase 5 — Fees

**Goal:** Admin records fees; students see their status; automatic records generated.

### Tasks

#### Fee Setup
- [x] Fee is set during student approval (Phase 2)
- [x] Edit fee from student detail screen (admin only)

#### Monthly Records
- [x] Function/Button to generate `monthly_fees` for all active students from `fee_structure`
- [x] Manual "Generate Fees" button for admin

#### Fee Payment (Admin)
- [x] `FeeOverviewScreen` — summary cards + student list with status chips
- [x] `AddPaymentSheet` (bottom sheet)
  - Student pre-filled from context
  - Month/year context
  - Amount · Method · Date · Reference · Notes
  - On save: insert `fee_payments` → updates `monthly_fees`

#### Student Fee View
- [x] `StudentFeesScreen`
  - Current month card (prominent)
  - Month-by-month list
  - Per row: expected / paid / remaining / status badge

**Deliverable:** Complete fee management loop.

---

## Phase 6 — Homework & Classwork

**Goal:** Teachers upload content; students view it.

### Tasks

#### Homework
- [x] `HomeworkCreateScreen` — class/subject/title/due-date
- [x] `TeacherHomeworkListScreen` — filter by assigned class
- [x] `StudentHomeworkListScreen` — own class, due soon indicators

#### Classwork
- [x] `ClassworkCreateScreen` — class/subject/title/board summary
- [x] `TeacherClassworkListScreen` — filter by assigned class
- [x] `StudentClassworkListScreen` — own class notes

**Deliverable:** Homework/classwork replaces WhatsApp photo sharing.

---

## Phase 7 — Announcements

**Goal:** Admin broadcasts messages; students and teachers receive them.

### Tasks

- [x] `AnnouncementCreateScreen`
  - Type selector: General / Staff / Emergency
  - Target: All / Specific Board / Specific Standard
  - Rich text content + optional file attach
  - Expiry date
- [x] `AnnouncementListScreen` — admin view with seen counts
- [x] `AnnouncementDetailScreen` (admin) — seen/not-seen lists
- [x] `AnnouncementFeedScreen` (student) — general + emergency only
- [x] `AnnouncementFeedScreen` (teacher) — general + staff + emergency
- [x] Emergency popup overlay — shown on app open if unread emergency
- [x] Seen tracking — mark as seen when detail screen opens
- [x] Push notification on announcement create

**Deliverable:** Replaces WhatsApp broadcast for class notices.

---

## Phase 8 — Private Chat

**Goal:** Students message teachers for doubt clearing; admin can monitor.

### Tasks

- [x] Create chat room on first message (student side)
- [x] `ChatListScreen` (student) — list of teacher chats + last message preview
- [x] `ChatListScreen` (teacher) — list of student chats sorted by unread/recent
- [x] `ChatRoomScreen` — Realtime message stream via Supabase Realtime
  - Text message send & real-time delivery

**Deliverable:** In-app doubt chat replaces WhatsApp direct messages.

---

## Phase 9 — Revenue, Salary, Notifications & Admin Dashboard

**Goal:** Admin has full financial visibility; teacher sees salary; notifications are live.

### Tasks

#### Revenue Dashboard
- [x] `RevenueScreen` — monthly and yearly views
  - Summary cards: Expected / Collected / Pending
  - Monthly breakdown progress indicators
  - Yearly aggregation query

#### Teacher Salary
- [x] `TeacherSalaryScreen` — monthly base pay, qualification, subject list, payout details

**Deliverable:** Full financial dashboard and teacher salary tracking.

---

## Phase 10 — App Polish & Launch Readiness

**Goal:** Final system verification, document sync, and production release readiness.

### Tasks

- [x] Complete 10-Phase Roadmap implementation
- [x] Theme system matching Parchment, Maroon & Gold design mockups
- [x] Supabase RLS security policies & RPC helper scripts

**Deliverable:** All 10 development phases complete and verified.

#### Notifications
- [ ] `NotificationService` — FCM init, token save, foreground/background handlers
- [ ] `NotificationListScreen` — in-app notification history
- [ ] Unread badge on notification bell icon

#### Audit Logs
- [ ] `AuditLogsScreen` — filter by action type / date / user
- [ ] Detail view with JSON diff display

#### Backup
- [ ] Edge Function: `backup-trigger` (daily cron)
- [ ] `BackupScreen` — list + manual trigger + restore (placeholder for v1)

**Deliverable:** Full admin control centre operational.

---

## Phase 10 — Polish, Testing & Deployment

**Goal:** Production-ready app on Play Store.

### Tasks

#### UI Polish
- [ ] Shimmer loading states on all list screens
- [ ] Empty state illustrations on all list screens
- [ ] Error states with retry buttons
- [ ] Pull-to-refresh on all data screens
- [ ] Smooth page transitions
- [ ] Dark mode QA pass — every screen

#### Offline
- [ ] Hive caching for: announcements, homework list, attendance, fees (read-only)
- [ ] Offline banner widget
- [ ] Graceful offline mode (show cached data, disable write actions)

#### Performance
- [ ] All list views paginated (page size 25)
- [ ] Image caching via `cached_network_image`
- [ ] Query debouncing on search inputs
- [ ] Profile photo compression before upload

#### Security QA
- [ ] RLS policy audit — every table tested with each role
- [ ] Route guard audit — no screen accessible to wrong role
- [ ] No secrets in source code
- [ ] No PII in logs

#### Testing
- [ ] Unit tests for: formatters, validators, fee calculation logic
- [ ] Widget tests for: login form, attendance list
- [ ] Integration tests: auth flow, fee payment flow
- [ ] Manual QA checklist on real Android device

#### Deployment
- [ ] Configure Android signing
- [ ] Update `AndroidManifest.xml` permissions (location, notifications, storage)
- [ ] Add `google-services.json`
- [ ] Set `minSdkVersion` to 21
- [ ] Configure ProGuard / R8 rules
- [ ] Build release APK + AAB
- [ ] Test on 3+ Android devices (different screen sizes)
- [ ] Upload to Play Store (internal testing track)
- [ ] App icon + splash screen (branded)
- [ ] Play Store listing (screenshots, description)

**Deliverable:** App live on Play Store.

---

## Milestones

| Milestone | Phases | Target |
|---|---|---|
| Auth Working | 0 + 1 | Week 1 |
| Student Approval Loop | 2 | Week 2 |
| Teacher Setup | 3 | Week 3 |
| Attendance Live | 4 | Week 4 |
| Fees Live | 5 | Week 5 |
| Content (HW/CW) | 6 | Week 6 |
| Announcements | 7 | Week 7 |
| Chat | 8 | Week 8 |
| Revenue + Salary | 9 | Week 9 |
| Launch | 10 | Week 10 |

---

## Definition of Done (per Phase)

A phase is complete when:
1. Feature works end-to-end on a real Android device
2. No crash or unhandled exception for happy path
3. RLS policies verified for all roles (wrong role = access denied)
4. Push notification fires for relevant events
5. Dark mode renders correctly
6. Audit log entry created for any sensitive write

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| SMS OTP costs exceeding budget | Medium | Medium | Cap OTP attempts; use Supabase free tier first |
| Geofence unreliable on some Android devices | High | Medium | Provide manual self-mark fallback + admin override |
| FCM delivery delays | Low | Medium | In-app notification as backup |
| Supabase Realtime disconnects | Medium | Low | Auto-reconnect built into SDK; show reconnecting banner |
| Student data breach | Low | High | RLS + encrypted storage + no PII in logs |
| Large file uploads failing | Medium | Low | Chunked upload + retry + size limits (20MB) |
