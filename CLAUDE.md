# CLAUDE.md — Vidyavardhini Classes App

---

## Mandatory Rules

### Document Sync Rule (No Exceptions)

**After every task, change, or phase transition — update all affected planning documents before reporting the task as done.**

Documents to keep in sync:

| Document | Update when… |
|---|---|
| [docs/APP_PRD.md](docs/APP_PRD.md) | A feature is added, changed, removed, or descoped |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | A new service, table, pattern, or data flow is introduced |
| [docs/SITEMAP.md](docs/SITEMAP.md) | A new screen is added, renamed, removed, or re-routed |
| [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | A table, column, index, trigger, or RLS policy changes |
| [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) | A phase task is completed, added, or re-scoped |

**When in doubt:** If a change is small and scoped to one file, update only that file. If a change touches multiple concerns (e.g. adding a new screen affects the sitemap, PRD checklist, and possibly architecture), update all affected files. Never skip an update because it feels minor — stale docs cause mistakes in future sessions.

---

### User Task Instructions Rule (No Exceptions)

**Whenever the user needs to do something manually — run a command, install a tool, set up an account, provide a file, or make a decision — give it as clear numbered steps. Never assume they know what to do next.**

Format all manual steps like this:

```
You need to do the following manually:

1. Open X and go to Y
2. Click / run / enter: `exact command or value`
3. Copy the result and paste it here
```

Never say "set up your Supabase project" without listing exactly how. Never say "add your Firebase config" without specifying which file and where.

---

## Project Identity

**App:** Vidyavardhini Classes  
**Client:** Mrs. Siddhi Gharat  
**Type:** Coaching Class ERP (Flutter + Supabase)  
**Platform:** Android-first, iOS-compatible  
**Version:** 1.0  

---

## Tech Stack

| Layer | Technology |
|---|---|
| UI Framework | Flutter 3.x |
| State Management | Riverpod (flutter_riverpod + riverpod_annotation) |
| Backend | Supabase (PostgreSQL + Auth + Storage + Realtime) |
| Push Notifications | Firebase Cloud Messaging (FCM) |
| Maps / Geofence | geolocator + google_maps_flutter |
| Charts | fl_chart |
| File Picker | file_picker |
| PDF Viewer | syncfusion_flutter_pdfviewer |
| Local Cache | Hive |
| Routing | go_router |
| UI Design | Material Design 3, dark mode |
| Font | Poppins (body), Cinzel (headings), Mukta (Hindi/Marathi) |

---

## User Roles

- **admin** — Single owner, full system access
- **teacher** — Assigned classes only, no financial/approval access
- **student** — Own data only, read-mostly

---

## Critical Business Rules

1. **Student IDs** (STU0001…) are permanent and never reused — enforce at DB level with a sequence and a trigger.
2. **Admin is unique** — only one admin account exists in the system.
3. **Students need admin approval** before any access. Status flow: `pending → active | rejected | banned`.
4. **Fees are admin-only write** — teachers and students are read-only.
5. **Audit logs are immutable** — no UPDATE or DELETE on `audit_logs`.
6. **Academic year data is isolated** — students/teachers see current year only; only admin can access historical years.
7. **Teacher attendance via GPS geofence** — admin sets lat/lng/radius; entering the geofence auto-marks present.
8. **Automatic monthly fees** — a database trigger/cron generates `monthly_fees` records on the 1st of every month for all active students.
9. **Fee reminder push** — sent on the 10th of every month to students with pending/partial fees.
10. **Promotion requires OTP + CONFIRM text + admin password** — triple confirmation guard.

---

## Folder Structure

```
lib/
├── main.dart                    # Entry point, providers scope
├── app.dart                     # MaterialApp, GoRouter, theme
├── core/
│   ├── constants/
│   │   ├── app_constants.dart   # Student ID prefix, fee due day, etc.
│   │   ├── supabase_keys.dart   # URL/anon key (from .env)
│   │   └── routes.dart          # All route path strings
│   ├── theme/
│   │   ├── app_theme.dart       # Light + dark ThemeData
│   │   ├── app_colors.dart      # Brand color constants
│   │   └── app_typography.dart  # TextTheme
│   ├── utils/
│   │   ├── formatters.dart      # Currency, date, phone formatters
│   │   ├── validators.dart      # Form field validators
│   │   └── extensions.dart      # Dart extension methods
│   └── services/
│       ├── supabase_service.dart
│       ├── notification_service.dart
│       ├── storage_service.dart
│       ├── geofence_service.dart
│       └── backup_service.dart
├── shared/
│   ├── models/                  # Pure data classes (freezed)
│   ├── widgets/                 # Reusable UI components
│   │   ├── app_bar_widget.dart
│   │   ├── loading_overlay.dart
│   │   ├── error_widget.dart
│   │   ├── avatar_widget.dart
│   │   └── stat_card_widget.dart
│   └── providers/
│       ├── auth_provider.dart   # Current user + role
│       └── academic_year_provider.dart
└── features/
    ├── auth/
    │   ├── screens/
    │   │   ├── splash_screen.dart
    │   │   ├── role_selection_screen.dart
    │   │   ├── phone_entry_screen.dart
    │   │   ├── otp_screen.dart
    │   │   ├── admin_login_screen.dart
    │   │   ├── teacher_login_screen.dart
    │   │   └── student_registration_screen.dart
    │   ├── providers/
    │   └── repositories/
    ├── admin/
    │   ├── dashboard/
    │   ├── students/
    │   ├── teachers/
    │   ├── fees/
    │   ├── revenue/
    │   ├── announcements/
    │   ├── audit_logs/
    │   └── settings/
    ├── teacher/
    │   ├── dashboard/
    │   ├── attendance/
    │   ├── homework/
    │   ├── classwork/
    │   ├── chat/
    │   ├── salary/
    │   └── timetable/
    └── student/
        ├── dashboard/
        ├── attendance/
        ├── homework/
        ├── classwork/
        ├── fees/
        ├── chat/
        └── announcements/
```

---

## State Management Conventions

- Use **Riverpod** with code generation (`@riverpod` annotation).
- Every feature has its own `providers/` subfolder.
- Use `AsyncNotifier` for server-fetched data; `Notifier` for local state.
- Never access `SupabaseClient` directly in screens — always go through a repository class.
- Repositories return `Either<Failure, T>` style (use `dartz` or plain `Result` wrapper).

---

## Supabase Conventions

- All tables have Row Level Security (RLS) **enabled**.
- Use Supabase **service role** only in Edge Functions (never in Flutter).
- Auth is OTP (phone) — Supabase Auth handles OTP via SMS.
- Additional access codes (admin code, teacher code) are stored **hashed** in the DB.
- Use Supabase Realtime for chat (`messages` table).
- Storage buckets: `profile-photos`, `homework-attachments`, `classwork-attachments`, `chat-files`.

---

## Naming Conventions

| Entity | Convention | Example |
|---|---|---|
| Dart files | snake_case | `student_profile.dart` |
| Classes | PascalCase | `StudentProfile` |
| Variables | camelCase | `studentId` |
| DB tables | snake_case | `student_profiles` |
| DB columns | snake_case | `monthly_fee` |
| Routes | kebab-case | `/admin/students/pending` |
| Providers | camelCase + `Provider` | `studentListProvider` |

---

## Environment & Secrets

- Supabase URL and anon key → `lib/core/constants/supabase_keys.dart` (gitignored)
- Firebase `google-services.json` → `android/app/` (gitignored)
- Use `flutter_dotenv` or build-time `--dart-define` for secrets.
- Never hardcode secrets. Never commit `.env` files.

---

## Commands

```bash
# Flutter
flutter pub get
flutter gen-l10n
flutter run --dart-define-from-file=.env

# Code generation (Riverpod + Freezed)
dart run build_runner build --delete-conflicting-outputs

# Supabase local
supabase start
supabase db push
supabase functions serve

# Tests
flutter test
flutter test integration_test/
```

---

## Key Third-Party Packages

```yaml
dependencies:
  flutter_riverpod: ^2.x
  riverpod_annotation: ^2.x
  supabase_flutter: ^2.x
  go_router: ^13.x
  freezed_annotation: ^2.x
  json_annotation: ^4.x
  hive_flutter: ^1.x
  fl_chart: ^0.x
  file_picker: ^8.x
  geolocator: ^11.x
  google_maps_flutter: ^2.x
  firebase_core: ^3.x
  firebase_messaging: ^15.x
  syncfusion_flutter_pdfviewer: ^26.x
  image_picker: ^1.x
  intl: ^0.19.x
  cached_network_image: ^3.x
  shimmer: ^3.x

dev_dependencies:
  riverpod_generator: ^2.x
  build_runner: ^2.x
  freezed: ^2.x
  json_serializable: ^6.x
```

---

## Security Rules

- All Supabase RLS policies must be checked before writing any data access code.
- Admin functions protected by `role = 'admin'` check in RLS.
- Teacher functions protected by teacher assignment join in RLS.
- Student data access scoped to `student_id = auth.uid()` in RLS.
- Never expose `service_role` key in Flutter code.
- Audit every fee change, attendance correction, and student approval.

---

## What NOT To Do

- Do not use `setState` for anything beyond local widget state.
- Do not call Supabase directly in widgets — always through providers → repositories.
- Do not delete audit log records for any reason.
- Do not allow teachers to write fee or revenue data — enforce at DB + UI level.
- Do not skip OTP verification in any auth flow.
- Do not reuse Student IDs.
- Do not allow students to access data from other academic years.
- Do not use `flutter_bloc` — this project uses Riverpod exclusively.

---

## Brand Identity

**Logo:** `images/logo.png`  
**Central motif:** Goddess Saraswati playing veena (knowledge/learning)  
**Sanskrit tagline:** सा विद्या या विमुक्तये *(Knowledge is that which liberates)*  
**English tagline:** *Nurturing Minds, Shaping Futures*  
**Owner credit:** Mrs. Siddhi Gharat  

All UI must feel consistent with this traditional, scholarly aesthetic — warm, dignified, not flashy.

## Color Palette

```dart
const parchment  = Color(0xFFF5EFE0);
const gold       = Color(0xFFC68A2D);
const maroon     = Color(0xFF7B2D26);
const brown      = Color(0xFF4A2C1A);
const darkBg     = Color(0xFF1A1208);   // dark mode background
const darkSurface = Color(0xFF2C1F10);  // dark mode surface
```

---

## Related Docs

- [docs/APP_PRD.md](docs/APP_PRD.md) — Full product requirements
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — System design
- [docs/SITEMAP.md](docs/SITEMAP.md) — All screens and navigation
- [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) — SQL schema with RLS
- [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) — Build roadmap
