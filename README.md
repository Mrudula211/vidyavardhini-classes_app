# Vidyavardhini Classes App

Coaching class management ERP for Vidyavardhini Classes.

**Client:** Mrs. Siddhi Gharat  
**Stack:** Flutter 3 · Supabase · Firebase FCM · Riverpod · Material 3  
**Scale:** 1 Admin · 5 Teachers · 140+ Students · SSC + CBSE (1st–10th)

## Documentation

| Doc | Description |
|---|---|
| [CLAUDE.md](CLAUDE.md) | AI assistant context — tech stack, conventions, rules |
| [docs/APP_PRD.md](docs/APP_PRD.md) | Full product requirements |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | System design, data flow, security |
| [docs/SITEMAP.md](docs/SITEMAP.md) | All screens and navigation flows |
| [docs/DATABASE_SCHEMA.md](docs/DATABASE_SCHEMA.md) | PostgreSQL schema with RLS policies |
| [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) | 10-phase build roadmap |

## Quick Start

```bash
flutter pub get
flutter run
```

## Setup Script

From the repository root, run:

```powershell
.\setup.ps1
```

This script installs dependencies and runs the Flutter analyzer. After setup, make sure your local Supabase and Firebase configuration files are present before launching the app.

If you are building on Windows, enable Developer Mode first so Flutter can create the plugin symlinks required by Android builds.

## Phase Status

See [docs/DEVELOPMENT_PHASES.md](docs/DEVELOPMENT_PHASES.md) for the authoritative, task-level checklist. Summary:

- [x] Phase 0 — Project Setup
- [x] Phase 1 — Authentication
- [x] Phase 2 — Student Management
- [x] Phase 3 — Teacher Management
- [x] Phase 4 — Attendance
- [x] Phase 5 — Fees
- [x] Phase 6 — Homework & Classwork
- [x] Phase 7 — Announcements
- [x] Phase 8 — Private Chat
- [x] Phase 9 — Revenue, Salary & Notifications
- [~] Phase 10 — Polish & Deployment (in progress)
