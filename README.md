# Vidyavardhini Classes App

Coaching-class management app for **Vidyavardhini Classes** (client: Mrs. Siddhi Gharat).
Android-first Flutter app on a Supabase backend.

**Stack:** Flutter 3 · Riverpod · go_router · Supabase (Postgres, Auth, Storage, Realtime, Edge Functions) · Firebase Cloud Messaging · Hive · gen-l10n
**Scale:** 1 admin · up to ~10 teachers · 140+ students · SSC + CBSE, standards 1st–10th
**Languages:** English, हिन्दी, मराठी (student and login screens)

## How people log in

There is **no SMS and no self-registration**.

- **Admin** adds every student in the app (Student Desk → add person). The app creates the login and a generated **access code**, which is the student's password. The parent logs in with their mobile number or email and the access code.
- **Teachers** are added by the admin with a mobile number and/or email, a password and an access code.
- Admin and teachers enter their access code once more after logging in.
- A lost student code is replaced by the admin on the student's page.

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) §3 for the details and trade-offs.

## Documentation

| Doc | What it is |
|---|---|
| [docs/OWNER_TODO.md](docs/OWNER_TODO.md) | **Start here.** What is left for the owner to do, in order |
| [docs/APP_PRD.md](docs/APP_PRD.md) | Product requirements |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, auth, storage, security |
| [docs/SITEMAP.md](docs/SITEMAP.md) | Screens and navigation |
| [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | Tables, RLS policies, functions |
| [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) | Build roadmap and task checklist |
| [CLAUDE.md](CLAUDE.md) / [AGENTS.md](AGENTS.md) | Conventions for AI coding assistants |

## Setup

Prerequisites: Flutter (stable), Android SDK, a Supabase project and a Firebase project.

1. `flutter pub get`
2. Copy `lib/core/constants/supabase_keys.example.dart` to `lib/core/constants/supabase_keys.dart` and fill in your Supabase URL and publishable key (git-ignored).
3. Put your Firebase config in place (all git-ignored): `android/app/google-services.json` and `lib/firebase_options.dart` (`flutterfire configure`).
4. Create the database: run the files in [supabase/migrations/](supabase/migrations/) in numeric order in the Supabase SQL Editor (each is safe to re-run). `004_seed_admin.sql` needs its `CHANGE_ME` values filled in first.
5. In Supabase **Authentication** turn **off** "Allow new users to sign up" and keep the Email and Phone providers enabled with confirmations off (see [docs/OWNER_TODO.md](docs/OWNER_TODO.md)).
6. `flutter run` (or `flutter run --release`).

On Windows enable Developer Mode first so Flutter can create plugin symlinks.

## Everyday commands

```bash
flutter analyze            # static analysis (must stay clean)
flutter test               # unit and widget tests
flutter gen-l10n           # regenerate translations after editing lib/l10n/*.arb
flutter build apk --release
```

Translations live in `lib/l10n/app_en.arb`, `app_hi.arb` and `app_mr.arb`; a test fails if Hindi/Marathi drift from English.

## Backend automation

`supabase/functions/send-push` (FCM push) and `supabase/functions/backup-trigger` (nightly JSON backup) are deployed with `--no-verify-jwt` and called by the database; monthly fee generation and fee reminders run as `pg_cron` jobs (migration 008). Setup steps: [docs/OWNER_TODO.md](docs/OWNER_TODO.md) §4.

## Project layout

```
lib/
  core/        constants, router (decideRedirect), theme, services, utils
  features/    auth, admin, teacher, student, chat, attendance, fees, content, ...
  shared/      models and reusable widgets
  l10n/        ARB files and generated localizations
supabase/
  migrations/  numbered SQL (schema, RLS, functions, jobs)
  functions/   Edge Functions (Deno)
test/          unit and widget tests
docs/          requirements, architecture, schema, checklists
```

## Status

All planned features are implemented and covered by tests; the app is in on-device testing and pre-release hardening. The authoritative checklist is [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md); what the owner still has to do is in [docs/OWNER_TODO.md](docs/OWNER_TODO.md).
