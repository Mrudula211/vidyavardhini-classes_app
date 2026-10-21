# ARCHITECTURE.md — Vidyavardhini Classes

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                        Flutter App                              │
│  ┌──────────┐  ┌──────────────┐  ┌──────────────────────────┐  │
│  │  Admin   │  │   Teacher    │  │        Student           │  │
│  │  Shell   │  │    Shell     │  │         Shell            │  │
│  └────┬─────┘  └──────┬───────┘  └───────────┬──────────────┘  │
│       │               │                       │                 │
│  ┌────▼───────────────▼───────────────────────▼──────────────┐  │
│  │              Riverpod State Layer                          │  │
│  │   Providers → AsyncNotifiers → Repositories              │  │
│  └────────────────────────┬──────────────────────────────────┘  │
│                           │                                     │
│  ┌────────────────────────▼──────────────────────────────────┐  │
│  │                   Service Layer                            │  │
│  │  SupabaseService  StorageService  NotificationService     │  │
│  │  GeofenceService  BackupService   CacheService (Hive)     │  │
│  └────────────────────────┬──────────────────────────────────┘  │
└───────────────────────────┼─────────────────────────────────────┘
                            │ HTTPS / WSS
          ┌─────────────────┼──────────────────────────┐
          │                 │      Supabase Backend     │
          │  ┌──────────────▼──────────┐               │
          │  │   PostgreSQL Database   │               │
          │  │   + Row Level Security  │               │
          │  └──────────────┬──────────┘               │
          │                 │                           │
          │  ┌──────────────▼──────────┐               │
          │  │    Supabase Auth        │               │
          │  │    (Phone OTP via SMS)  │               │
          │  └─────────────────────────┘               │
          │                                            │
          │  ┌──────────────────────────┐              │
          │  │    Supabase Storage      │              │
          │  │    Buckets:              │              │
          │  │    - profile-photos      │              │
          │  │    - homework-files      │              │
          │  │    - classwork-files     │              │
          │  │    - chat-files          │              │
          │  └──────────────────────────┘              │
          │                                            │
          │  ┌──────────────────────────┐              │
          │  │    Supabase Realtime     │              │
          │  │    - messages table      │              │
          │  │    - notifications table │              │
          │  └──────────────────────────┘              │
          │                                            │
          │  ┌──────────────────────────┐              │
          │  │    Edge Functions        │              │
          │  │    - monthly-fee-gen     │              │
          │  │    - fee-reminder        │              │
          │  │    - backup-trigger      │              │
          │  │    - fcm-push-send       │              │
          │  └──────────────────────────┘              │
          └────────────────────────────────────────────┘
                            │
          ┌─────────────────▼──────────────────────────┐
          │           Firebase (FCM)                    │
          │   Push notifications → Android / iOS       │
          └─────────────────────────────────────────────┘
```

---

## 2. Flutter App Architecture

### 2.1 Layer Responsibilities

```
Screen (Widget)
  ↓ watches/reads
Provider (Riverpod AsyncNotifier)
  ↓ calls
Repository (interface + Supabase implementation)
  ↓ calls
Service (SupabaseService, StorageService, etc.)
  ↓ calls
Supabase SDK / Platform APIs
```

### 2.2 Feature Module Structure

Each feature folder follows this pattern:

```
features/admin/students/
├── screens/
│   ├── student_list_screen.dart
│   ├── student_detail_screen.dart
│   └── student_approval_screen.dart
├── widgets/
│   ├── student_card.dart
│   └── approval_dialog.dart
├── providers/
│   ├── student_list_provider.dart        # @riverpod AsyncNotifier
│   └── student_approval_provider.dart
└── repository/
    ├── i_student_repository.dart         # Abstract interface
    └── supabase_student_repository.dart  # Concrete implementation
```

### 2.3 Navigation (go_router)

```
/                           → SplashScreen
/role-select                → WelcomeScreen (landing; replaced the role-card screen)
/auth/phone                 → PhoneEntryScreen
/auth/otp                   → OTPScreen
/auth/admin-code            → AdminCodeScreen
/auth/teacher-code          → TeacherCodeScreen
/auth/student-register      → StudentRegistrationScreen
/auth/pending               → PendingApprovalScreen

/admin/**                   → AdminShell (BottomNav)
/teacher/**                 → TeacherShell (BottomNav)
/student/**                 → StudentShell (BottomNav)
```

Shell widgets wrap feature screens with role-appropriate navigation bars.

---

## 3. Authentication Flow

```
          ┌──────────────────────────────────────────────────────────┐
          │                    Supabase Auth                         │
          │                                                          │
          │  verifyOtp(phone, otp)                                   │
          │  → returns Session { access_token, user.id }             │
          │  → JWT contains custom claim: role = 'admin|teacher|...' │
          └──────────────────────────────────────────────────────────┘
                              ↑
          Phone → OTP → Supabase OTP verification
                              ↓
          [Admin]  → check access_code hash → check password hash
          [Teacher]→ check access_code hash
          [Student]→ check pending/active status
                              ↓
          Store Session in Hive (encrypted) for auto-login
                              ↓
          GoRouter redirect logic reads authStateProvider
          → routes to correct shell
          → student: also gates on status (pending / rejected / banned)
            and forces StudentPasswordScreen when email is unset
```

Role is stored in the `users` table and embedded in JWT via a Supabase Auth hook (PostgreSQL function).

### 3.1 Unified login (as built)

There is no role picker. `WelcomeScreen` -> `PhoneEntryScreen` (mobile OTP, or email + password) -> `OtpScreen`; after sign-in the app reads `users.role` (`fetchUserRole`) and `roleDestination()` decides the next step. Unknown phone numbers become `student` users (the only role self-registration can create — enforced by RLS) and continue to registration. Admin/teacher accounts are created by the admin, so they simply exist and are recognised.

`appRouterProvider.redirect` is the single gate: no session -> auth screens only; session without a known role -> auth screens; student status gates (pending / rejected / banned / set-password); **admin and teacher must pass their access-code step** (`adminAuthenticatedProvider` / `teacherAuthenticatedProvider`, cleared on logout or account switch) before reaching any other screen; role-prefixed routes are role-checked. `currentUserIdProvider` makes the user/role/status providers react to login and logout (previously they were evaluated once and went stale).

### 3.2 Localization

Flutter `gen-l10n`: `lib/l10n/app_{en,hi,mr}.arb` -> generated `AppLocalizations`; use `context.l10n.<key>` (`lib/l10n/l10n_context.dart`). The chosen language is stored in Hive box `settings` (`localeProvider`); `LanguageSwitcher` is on the welcome, login and registration screens. Parent/student-facing screens are translated; admin and teacher working screens remain English (staff sign-in verification screens are translated). Dates and month names use the active locale. Add a string by adding it to the ARB files (`test/l10n/arb_completeness_test.dart` fails if hi/mr drift from en).

`NotificationService` registers FCM, saves `users.fcm_token` (including on auth state change), and exposes foreground/background handlers. Dashboards use `NotificationBellButton` with an unread badge backed by `unreadNotificationCountProvider`.

### Offline & cache

- `CacheService` (Hive box `app_cache`) stores JSON list payloads with TTL.
- Read repositories for announcements, homework, student attendance (month), and student fees use `fetchWithCacheFallback` so a failed network call returns last-good cache when available.
- `connectivityStatusProvider` / `isOnlineProvider` drive a global `OfflineBanner`; write screens call `guardOnline()` before mutating.

---

## 4. Database Architecture

### 4.1 Schema Groups

| Group | Tables |
|---|---|
| Auth & Users | `users`, `admin_profiles`, `teacher_profiles`, `student_profiles` |
| Academic | `academic_years`, `student_enrollments`, `teacher_assignments` |
| Attendance | `student_attendance`, `absence_reasons`, `teacher_attendance` |
| Content | `homework`, `homework_attachments`, `classwork`, `classwork_attachments` |
| Communication | `chat_rooms`, `messages`, `announcements`, `announcement_attachments`, `announcement_seen` |
| Finance | `fee_structure`, `monthly_fees`, `fee_payments`, `teacher_salary` |
| System | `notifications`, `audit_logs`, `geofence_settings`, `backup_logs`, `promotion_history` |
| Schedule | `teacher_timetable` |

### 4.2 Key Relationships

```
users (1) ──────────── (1) admin_profiles
users (1) ──────────── (1) teacher_profiles
users (1) ──────────── (1) student_profiles

student_profiles (M) ── (1) academic_years  [via student_enrollments]
teacher_profiles (M) ── (1) academic_years  [via teacher_assignments]

student_profiles (1) ── (M) student_attendance
student_profiles (1) ── (M) monthly_fees
student_profiles (1) ── (M) fee_payments [via monthly_fees]

teacher_profiles (1) ── (M) teacher_attendance
teacher_profiles (1) ── (M) teacher_salary

teacher_profiles (1) ── (M) homework
teacher_profiles (1) ── (M) classwork

student_profiles (M) ── (M) teacher_profiles  [via chat_rooms]
chat_rooms (1) ────────── (M) messages
```

### 4.3 RLS Policy Strategy

**users table:**
- Anyone can insert their own record (registration)
- Users can read their own record
- Admin can read/update all records

**student_profiles:**
- Student can read own row only (`auth.uid() = id`)
- Teacher can read students in assigned classes
- Admin can read/write all rows

**monthly_fees:**
- Student can read own rows only
- Admin can read/write all
- Teacher: no access

**messages:**
- Sender or receiver can read
- Anyone authenticated can insert (to rooms they're a member of)
- Admin can read all rooms

**audit_logs:**
- Insert only (no update, no delete)
- Admin can read all
- No other role can read

---

## 5. State Management Detail

### 5.1 Auth State

```dart
// Global auth state — watched by GoRouter redirect
@riverpod
Stream<AuthState> authState(AuthStateRef ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
}

// Current user profile (derived from auth state)
@riverpod
Future<AppUser?> currentUser(CurrentUserRef ref) async { ... }
```

### 5.2 Data Fetching Pattern

```dart
@riverpod
class StudentList extends _$StudentList {
  @override
  Future<List<StudentProfile>> build() async {
    return ref.read(studentRepositoryProvider).getStudents();
  }

  Future<void> approveStudent(String studentId, String assignedId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(studentRepositoryProvider).approve(studentId, assignedId);
      return ref.read(studentRepositoryProvider).getStudents();
    });
  }
}
```

### 5.3 Realtime Chat

```dart
// Subscribes to Supabase Realtime channel for a chat room
@riverpod
Stream<List<Message>> chatMessages(ChatMessagesRef ref, String roomId) {
  final client = Supabase.instance.client;
  return client
    .from('messages')
    .stream(primaryKey: ['id'])
    .eq('room_id', roomId)
    .order('created_at')
    .map((data) => data.map(Message.fromJson).toList());
}
```

---

## 6. Storage Architecture

### 6.1 Bucket Structure

```
profile-photos/          (private)
  {user_id}/avatar.jpg

homework-attachments/    (private — accessible to enrolled students)
  {homework_id}/{filename}

classwork-attachments/   (private — accessible to enrolled students)
  {classwork_id}/{filename}

chat-files/              (private — accessible to room members only)
  {room_id}/{message_id}/{filename}
```

### 6.1b Attachment storage (implemented)

Private buckets `homework-attachments` and `classwork-attachments` (20 MB limit). Object path `<teacher_uid>/<timestamp>_<filename>`; `*_attachments.file_url` stores that path (not a URL). Teachers may upload only into their own folder; reads are allowed when the caller can read the matching attachment row (teacher owner, admin, students of the class). The app views files through 1-hour signed URLs (`StorageService.signedUrl`).

### 6.2 Upload Flow

```
User selects file (file_picker)
  → validate size (max 20MB) and type
  → upload to Supabase Storage (streaming)
  → get signed URL or public URL
  → save URL to DB record (homework_attachments, etc.)
```

---

## 7. Push Notification Architecture

```
Event occurs (e.g., homework uploaded)
  → Supabase DB trigger fires
  → calls Edge Function: fcm-push-send
  → Edge Function fetches target users' FCM tokens from users table
  → sends FCM batch request to Firebase
  → Firebase delivers to devices
  → Flutter app: firebase_messaging.onMessage handler
  → creates in-app notification record
  → shows snackbar or local notification
```

### 7.1 Automatic Monthly Fee Reminder

Supabase pg_cron job (scheduled via Edge Function or Supabase cron):

```sql
-- Runs at 9:00 AM on the 10th of every month
SELECT cron.schedule(
  'monthly-fee-reminder',
  '0 9 10 * *',
  $$SELECT net.http_post(url := 'https://.../fee-reminder')$$
);
```

---

## 8. Geofencing Architecture

**As built:** the phone only supplies a GPS position. `mark_teacher_present(lat, lng)` (SECURITY DEFINER) computes the haversine distance to `geofence_settings` and records `teacher_attendance` itself, never overwriting leave/holiday/manual corrections. Triggers: the check-in screen (button + auto on open) and a silent once-per-session attempt when the teacher dashboard opens. Background (app closed) auto-marking is not implemented. The original sketch follows.


```
Teacher opens app or app is in background
  → GeofenceService.startMonitoring()
  → geolocator.getPositionStream()
  → calculate distance from centre point
  → if distance ≤ radius AND not already marked today:
      → call attendanceRepository.markTeacherPresent(lat, lng, timestamp)
      → stop monitoring for today
```

Settings stored in `geofence_settings` table (admin configures via settings screen).

---

## 9. Offline Strategy

| Data Type | Cached? | Cache Duration |
|---|---|---|
| Student profile (own) | Yes (Hive) | Until app restart |
| Announcements list | Yes (Hive) | 1 hour |
| Homework list | Yes (Hive) | 30 minutes |
| Attendance history | Yes (Hive) | 1 hour |
| Fee records (own) | Yes (Hive) | 30 minutes |
| Chat messages | No | — |
| Revenue data | No | — |
| Admin lists | No | — |

Write operations require an internet connection. Display a banner when offline.

---

## 10. Security Architecture

### 10.1 Layers

1. **Transport:** HTTPS for all API calls, WSS for Realtime
2. **Auth:** Supabase JWT (RS256), refreshed automatically
3. **DB:** RLS policies enforce role-based access per row
4. **App:** Role-based route guards in go_router
5. **UI:** Role-based widget visibility (teachers never see fee edit buttons)

### 10.2 Sensitive Data

| Data | Storage Location | Notes |
|---|---|---|
| Auth tokens | Supabase Flutter SDK (secure storage) | Auto-managed |
| Access codes | Supabase DB (bcrypt hashed) | Never sent in plaintext |
| Phone numbers | Supabase Auth + profiles | Encrypted at rest |
| Profile photos | Private Supabase Storage bucket | Signed URLs with expiry |
| FCM tokens | `users.fcm_token` column | Refreshed by app |

### 10.3 Audit Trail

Every write to sensitive tables (fees, salary, attendance corrections, student status changes) calls `insert_audit_log(action, entity_type, entity_id, old_val, new_val)` — either via DB trigger or application code.

---

## 11. Academic Year Isolation

All major tables include `academic_year_id`. Queries always filter by the current academic year (stored in `academic_years.is_current = true`).

```dart
// academicYearProvider — fetched once at app start
@riverpod
Future<AcademicYear> currentAcademicYear(Ref ref) async {
  return supabase.from('academic_years').select().eq('is_current', true).single();
}
```

Historical data queries (admin only) accept an `academicYearId` parameter. Student and teacher data providers always inject `currentAcademicYear.id`.

---

## 12. Edge Functions

| Function | Trigger | Purpose |
|---|---|---|
| `send-push` | `notifications` INSERT trigger → pg_net | Send FCM (HTTP v1) push; stamps `sent_at`; clears dead `fcm_token`s |
| `backup-trigger` | `backup_logs` INSERT (pending) trigger → pg_net | Dump all tables to JSON in private `backups` bucket; 30-day retention |

Implemented in `supabase/functions/` and wired by `supabase/migrations/008_automation.sql`.
Edge Functions are deployed with `--no-verify-jwt` and authenticate callers with the
`x-automation-secret` header (Vault secret `automation_secret` ↔ function secret `AUTOMATION_SECRET`).

Pure-SQL pg_cron jobs (UTC; IST = UTC+5:30):

| Job | Schedule | Action |
|---|---|---|
| `monthly-fee-generate` | `1 0 1 * *` | `generate_monthly_fees_for_month(month, year)` |
| `monthly-fee-reminder` | `30 3 10 * *` (09:00 IST) | `queue_fee_reminders()` inserts notifications → push trigger |
| `daily-backup` | `30 20 * * *` (02:00 IST) | inserts pending `backup_logs` row → backup trigger |

---

## 13. Scalability Notes

- 140 students × 12 months × 10 years = 16,800 monthly_fee rows — trivial for PostgreSQL
- Attendance: 140 students × 300 days × 10 years = 420,000 rows — well within range
- Messages: partitioned by `room_id`; archive old rooms after academic year end
- All list queries paginated (page size: 25–50)
- Indexes on: `student_id`, `academic_year_id`, `date`, `status`, `board+standard`
