# DEVELOPMENT_PHASES.md — Vidyavardhini Classes

## Overview

10-phase incremental build. Each phase produces a working, testable increment.  
Phases 1–5 are the MVP needed for launch. Phases 6–10 add the full feature set.

---

## Phase 0 — Project Setup (Pre-development)

**Goal:** Working skeleton. Everyone can run the app on a device.

### Tasks

- [x] Create Flutter project (`flutter create`)
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
- [x] ~~Set up `build_runner` for code generation~~ — removed; `riverpod_generator` crashed against the current Dart SDK's analyzer, so the one codegen usage (`app_router.dart`) was rewritten as a hand-written `Provider`. No codegen step is needed to build.
- [x] Create `supabase/migrations/001_initial_schema.sql`
- [x] Create `supabase/migrations/002_triggers_functions.sql`
- [x] Create `supabase/migrations/003_auth_rpc.sql`
- [x] Create `supabase/migrations/004_seed_admin.sql`
- [x] Move `google-services.json` to `android/app/` (after `flutter create`)

**Deliverable:** App launches, shows theme colours, Supabase connected. Verified on a physical Android device (Samsung SM-M146B, Android 15) — Supabase and Firebase both initialize successfully.

---

## Phase 1 — Authentication

**Goal:** All three roles can log in and land on their correct dashboard shell.

### Tasks

#### Shared Auth
- [x] `SplashScreen` — check session, redirect by role or to role-select
- [x] `WelcomeScreen` — single "Login" door + language switcher (replaced the original 3 role cards; see "Landing page, unified login & languages")
- [x] `PhoneEntryScreen` — phone number input with country code
- [x] `OTPVerificationScreen` — 6-digit OTP input, resend timer
- [x] Supabase OTP integration (`signInWithOtp`, `verifyOtp`)
- [x] Store role in `users` table on first login
- [x] JWT role claim setup (Supabase Auth hook) — `supabase/migrations/006_jwt_role_claim_hook.sql`; requires enabling the hook in Supabase Dashboard → Authentication → Hooks (see migration file for steps)

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
- [x] `StudentPasswordScreen` — first login after approval (set password)
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

**Fixed during first real-device testing:** `create_teacher_profile` (migration 005) inserted a random UUID into `public.users.id` without a matching `auth.users` row, so every call failed with a foreign-key violation (23503). The Flutter repository's `catch (_) {}` silently swallowed this and fell back to an even more broken manual insert that never set `id` (23502 not-null violation) — this produced the confusing error actually seen on-device. Fixed by `supabase/migrations/007_fix_teacher_creation.sql` (must be run manually in the Supabase SQL Editor), which creates a matching bare `auth.users` row, mirroring how the admin account is seeded in migration 004. This also means teachers can now sign in via phone + OTP with a real Supabase Auth session (previously only the access-code path existed, which never calls Supabase Auth — so `auth.uid()`-scoped RLS policies for teacher-owned data, e.g. `teacher_salary: own read`, could never actually match). The access-code-only login path itself still does not establish a session; worth revisiting if teacher-owned RLS policies need to work for that path specifically.

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
- [x] `RevenueRepository` (`fetchYearlyRevenue`, `fetchMonthlyRevenue`) + `revenue_providers.dart` — extracted from the inline `fee_providers.dart` analytics call so the screen follows the standard repository pattern

#### Teacher Salary
- [x] `TeacherSalaryScreen` — current month highlighted with a paid/pending status chip, plus month-by-month salary history, loading/empty/error states, pull-to-refresh
- [x] `TeacherSalaryRepository` (`fetchSalaryHistory`, `fetchSalaryForMonth`) + `teacher_salary_providers.dart` — reads `teacher_salary`, scoped to the signed-in teacher's own id (defense in depth alongside the `teacher_salary: own read` RLS policy)

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
- [x] `NotificationService` — FCM init, token save, foreground/background handlers; re-saves token on auth state change
- [x] `NotificationListScreen` — in-app notification history
- [x] Unread badge on notification bell icon — `NotificationBellButton` on admin/teacher/student dashboards

#### Audit Logs
- [x] `AuditLogsScreen` — filter by action type / date / user
- [x] Detail view with JSON diff display

#### Backup
- [x] Edge Function: `backup-trigger` — JSON dump of all tables to private `backups` bucket, 30-day retention; fired by `backup_logs` INSERT trigger (daily cron `daily-backup` 02:00 IST + manual button). Needs deployment — see `docs/OWNER_TODO.md`.
- [x] `BackupScreen` — list + manual trigger. Manual trigger inserts a `pending` `backup_logs` row, which the DB trigger hands to `backup-trigger`. Restore is out of scope for v1.

**Deliverable:** Full admin control centre operational.

---

## Phase 10 — Polish, Testing & Deployment

**Goal:** Production-ready app on Play Store.

### Tasks

#### UI Polish
- [x] Shimmer loading states on simple list screens (notifications, students, teachers, homework/classwork x4, chat list). Multi-section screens (fees overview, attendance overview, timetable, student fees, student attendance) intentionally kept a plain spinner instead — a fake-stat shimmer would misrepresent their card/summary layout.
- [x] Empty state icon+message on all audited list screens
- [x] Error states with retry buttons on all audited list screens (several had no Retry button at all before this pass — fee overview, admin attendance, admin timetable, chat list)
- [x] Pull-to-refresh on all audited data screens (fee overview, admin attendance, and admin timetable had none at all before this pass)
- [x] Smooth page transitions — app-wide fade+slide via `FadeSlidePageTransitionsBuilder` on light/dark themes
- [x] Dark mode QA pass — fixed unreadable text: hard-coded maroon/brown text colours replaced by theme-aware `context.headingColor` / `bodyTextColor` / `mutedTextColor` (`ThemeTone` extension in `app_colors.dart`) across 25 files; chat bubbles/input bar, homework and classwork note boxes now follow the theme; the welcome card and admin dashboard keep their intentional fixed light colours. Needs a visual check on a phone (admin screens especially).

#### Offline
- [x] Hive caching for: announcements, homework list, attendance (per month), student fees (read-only) via `CacheService` + `fetchWithCacheFallback`
- [x] Offline banner widget — global `OfflineBanner` in `MaterialApp.router` builder
- [x] Graceful offline mode — cached reads on failure; `guardOnline()` blocks attendance submit, fee payment, announcements, homework create, and chat send

#### Performance
- [x] High-risk list queries bounded (page size 25 / month scope): `student_repository.fetchStudents()` paginated with Previous/Next UI; student attendance history scoped to selected month; homework/classwork list queries limited to `AppConstants.pageSize`; chat message stream windowed to last 100 messages client-side.
- [x] Image caching via `cached_network_image` on student list avatars (extend to remaining avatar sites as they are touched)
- [x] Query debouncing on student list and fee overview search (350ms)
- [x] Profile photo compression before upload — student registration uses `image_picker` with JPEG quality 70 and a 512×512 maximum before upload.

#### Security QA
- [x] RLS policy audit — static cross-check of `audit_logs`, `student_profiles`, `monthly_fees`/`fee_payments`, `teacher_salary` RLS vs. repository code; no violations found (audit_logs immutability confirmed enforced at the DB level — no UPDATE/DELETE policy exists for any role). Live per-role testing against real Supabase still pending (DB was unreachable during this pass).
- [x] Route guard audit — found and fixed a real gap: the GoRouter `redirect` only checked role, not student `status`, so a pending/rejected/banned student with a still-valid session could reach `/student/*` routes directly (e.g. via deep link), bypassing the one-time splash-screen check. Now watches `currentStudentStatusProvider` and gates on status too (signs out rejected/banned students, routes pending ones to the pending-approval screen).
- [x] **Correction (later pass):** the claim below was wrong. Admin credentials were hardcoded in `admin_login_screen.dart` and seeded in `004_seed_admin.sql`. The login-screen fallbacks are removed; the credentials in `004` and git history must be rotated (see `docs/OWNER_TODO.md` section 0).
- [x] No secrets in source code — grepped for `service_role`, JWT-shaped literals, and hardcoded credentials; only the safe-by-design anon/publishable key was found. Fixed a related hygiene issue: `lib/core/constants/supabase_keys.dart` was tracked in git despite CLAUDE.md saying it should be gitignored — now untracked, gitignored, and replaced with a `supabase_keys.example.dart` template.
- [x] No PII in logs — all `debugPrint`/`print` call sites checked; none log phone numbers, emails, passwords, or OTPs.
- [x] Student "set password on first login" is now router-enforced (active student with empty email is redirected to `StudentPasswordScreen`; that route is excluded from the logged-in auth-route bounce).

#### Testing
- [x] Unit tests for: `formatBytes`, fee/attendance model parsing (`test/shared/models_test.dart`); fee generation covered in `fee_repository_test.dart`. (Validators are inline in screens — no shared validators file exists.)
- [x] Widget tests for: `StudentAttendanceCard` (`test/features/teacher/student_attendance_card_test.dart`)
- [x] Widget test for admin login form (`test/features/auth/screens/admin_login_screen_test.dart`)
- [ ] Integration tests: auth flow, fee payment flow
- [ ] Manual QA checklist on real Android device

#### Deployment
- [x] Configure Android signing — `build.gradle.kts` reads `android/key.properties` (template: `key.properties.example`); owner must generate the keystore
- [x] Update `AndroidManifest.xml` permissions (location and notifications); photo and document selection use Android system pickers, so broad storage permission is not required.
- [x] Add `google-services.json` (present locally in `android/app/`, gitignored)
- [x] Set `minSdkVersion` to 21
- [x] Configure ProGuard / R8 rules — minify + shrink enabled, `android/app/proguard-rules.pro`
- [ ] Build release APK + AAB
- [ ] Test on 3+ Android devices (different screen sizes)
- [ ] Upload to Play Store (internal testing track)
- [x] App icon + splash screen (branded) — `flutter_launcher_icons` / `flutter_native_splash` configured in `pubspec.yaml`, Android assets generated from `images/logo-icon.png` (parchment light / dark-brown dark splash). Owner may supply a higher-resolution source (current is ~580px).
- [ ] Play Store listing (screenshots, description)

**Deliverable:** App live on Play Store.

---

## Audit findings — features marked done but not actually present (2026-10-22)

A static audit of every button, route and dashboard found the following. Fixed items are ticked; open items are real gaps, not polish.

- [x] Teacher and student dashboards had no way to reach Chat, Timetable or Announcements — tiles added.
- [x] Teacher and student had no Logout button — added (signs out of Supabase). Admin logout previously cleared only a local flag and left the Supabase session alive — fixed.
- [x] Backup screen was unreachable (no dashboard tile) — added to admin dashboard.
- [x] Schema drift: app used `chat_messages`, `timetable_slots`, `chat_rooms.last_message(_at)`, none in migrations 001-008; `chat_rooms` had no UPDATE policy so "last message" never saved — fixed by `009_chat_timetable_rls_hardening.sql` (also enables RLS on any public table lacking it).
- [x] **Homework / classwork attachments:** `StorageService` (pick, upload to private buckets with 20 MB cap, signed URLs), `AttachmentPickerField` on both create screens, `AttachmentList` on all four list screens, in-app `AttachmentViewerScreen` (images, PDF via Syncfusion); video/text open externally. Needs migration 010 + live test.
- [x] **Teacher self-attendance by GPS geofence (business rule 7):** `GeofenceService` + `TeacherCheckInScreen` (`/teacher/check-in`) call the server-side `mark_teacher_present` RPC (distance decided in the DB); a silent once-per-session auto check-in runs when the teacher dashboard opens. Limitation: marking happens when the app is opened, not from the background (no background location service).
- [x] **Academic-year promotion (business rule 10):** `PromotionScreen` (`/admin/settings/academic-year`) -> `promote_students` RPC. The DB enforces admin role, exact `CONFIRM`, password check, and an OTP login in the last 10 minutes (JWT `amr`); it fails closed. Needs live verification (SMS provider + `amr` claim).
- [x] **Manual fee reminder:** "Send reminder" button on each unpaid fee card in Fee Overview -> `send_fee_reminder` RPC -> notification + push.
- [x] Dead route constants removed from `routes.dart` (profile, detail, pdf/image viewer, etc. had no screens; viewer is now `AttachmentViewerScreen`). Profile screens remain out of scope for v1.
- [x] RLS bug: homework/classwork student-read policies compared the enrollment row to itself (any student could read every class) — fixed in 010.
- [x] Audit logging: nothing wrote to `audit_logs`; 010 adds DB triggers for fee payments/structure/status, salary, student status, attendance corrections, homework/classwork, geofence, teachers, promotion.
- [x] **Auth sessions (critical, fixed in code + migration 011):** the teacher card skipped phone OTP and the admin access-code path never created a Supabase session, so RLS-protected data was unreachable for them. Teacher now: phone -> OTP -> access code (verified against the caller's own record via `verify_my_teacher_access_code`). Admin now: email + password (real session) + access code via `verify_my_admin_credentials`. Both RPCs are caller-bound and rate-limited (5 failures -> 15 min lock); the old anonymous RPCs are revoked.
- [x] **Privilege escalation (critical, fixed in 011):** `users` insert/update policies let any OTP user set `role = 'admin'`; a trigger now blocks role changes, inserts are limited to `student`, and a unique index enforces a single admin.
- [x] **Approval bypass (fixed in 011):** `student_profiles` self-insert must be `pending` with no student ID / approver.
- [x] Teachers could insert their own attendance (bypassing the geofence RPC) and `create_teacher_profile` was callable by anyone with a default `123456` code; both fixed (admin-only, explicit 6-digit code). `audit_logs` client inserts removed (triggers only).
- [x] Phone numbers normalised (Auth: digits only; app/`public.users`: `+<digits>`) so OTP sign-in finds seeded teacher/admin accounts; NULL token columns on SQL-seeded `auth.users` rows repaired. Seed `004` no longer contains credentials.
- [ ] Access code remains a UI-level second factor: an admin/teacher with a valid session can reach their routes without it; data safety rests on RLS + session. Server-enforced second factor is a possible future change.

---

## Landing page, unified login & languages (2026-10-22)

- [x] Researched how multi-role school apps handle sign-in: one login, backend role lookup, route by role; role pickers shown to anonymous users are a weak pattern. Fits our Supabase setup (role already in `users.role`).
- [x] `WelcomeScreen` replaces the role-card screen (logo badge, name, Sanskrit + localized tagline, language chips, Login / New student buttons).
- [x] `PhoneEntryScreen` is the single login (mobile OTP default, email + password alternative); `OtpScreen` looks up the role and routes; the Resend button now really resends.
- [x] Router second-factor gate for admin/teacher; session required for everything past the auth screens; auth providers made reactive (stale-role bug fixed); registration/pending flow fixed (new students no longer bounced to "pending"; pending students can re-check status and log out).
- [x] Hindi + Marathi (+ English) via gen-l10n, 188 keys; translated: welcome, login, OTP, registration, pending, set-password, student dashboard/attendance/fees/homework/classwork, announcements, notifications, chat, timetable, offline banner. Language persisted (Hive).
- [x] Link audit: every navigation target is a registered route; no orphan screens; dead `announcements` route alias removed; fake "Room 101" default removed from the timetable.
- [ ] Hindi/Marathi wording needs review by a native speaker (Mrs. Gharat / staff) before release.
- [ ] Admin and teacher working screens (fees, attendance marking, homework creation, etc.) are still English only.
- [ ] Admin/teacher access-code step is a client-enforced second factor (a determined user with a valid OTP session could call data APIs without it; RLS still limits them to their role).

---

## Login hang fixes (2026-10-22)

- [x] Found on a real phone: a new student verified the OTP, then was sent back to Welcome. The login account existed in `auth.users` but the client-side insert of the `public.users` row did not land, so the role was unknown. Fixed in two layers: migration `012_auto_create_user_row.sql` (database trigger creates the row, backfills orphans) and the router no longer parks on the splash screen when a role is unknown (`decideRedirect`, 12 tests).

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
