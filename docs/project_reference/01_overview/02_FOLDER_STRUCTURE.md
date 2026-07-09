# 02 Folder Structure

## Purpose
This document outlines the directory structure of the repository, explaining the purpose of each major folder and file to aid navigation and onboarding.

## Current State
The project follows a standard Flutter feature-first folder structure combined with a separate `docs/` and `supabase/` folder for non-Flutter assets.

## Detailed Explanation
The repository is organized as follows:

```
.
├── android/                 # Android specific build files
├── docs/                    # Official documentation and UI designs (Product Requirements)
│   ├── UI/                  # Mockups/Screenshots of intended design
│   └── project_reference/   # This documentation repository
├── images/                  # Static assets (logo)
├── ios/                     # iOS specific build files
├── lib/                     # Flutter source code
│   ├── core/                # Core application setup
│   │   ├── constants/       # App-wide constants (routes, keys)
│   │   ├── router/          # GoRouter configuration
│   │   └── theme/           # App colors, typography, and Material theme
│   ├── features/            # Feature-based modules
│   │   ├── admin/           # Admin screens
│   │   ├── auth/            # Authentication logic and UI
│   │   ├── student/         # Student screens
│   │   └── teacher/         # Teacher screens
│   ├── shared/              # Shared widgets (buttons, headers)
│   ├── app.dart             # MaterialApp configuration
│   └── main.dart            # Application entry point
├── supabase/                # Supabase configuration and database schemas
│   └── migrations/          # SQL files for schema definitions, triggers, and functions
├── test/                    # Unit and widget tests (currently empty/default)
├── web/                     # Web specific build files
├── CLAUDE.md                # AI assistant context
├── pubspec.yaml             # Flutter dependencies
├── README.md                # Project README
└── setup.ps1                # Setup script for Windows
```

## Observations
- The feature-first architecture (`lib/features/`) is a scalable choice for an application of this size.
- `docs/UI/` contains PNG files representing the design system.
- `supabase/migrations/` contains the source of truth for the database schema (`001_initial_schema.sql`, `002_triggers_functions.sql`).

## Problems
- There is no `assets/` folder explicitly declared for fonts, although `pubspec.yaml` references `fonts/Cinzel-Regular.ttf`. The fonts are missing from the repo, or at least not in a standard location.

## Recommendations
- Ensure the missing font files are added to an `assets/fonts/` directory.
- Maintain the strict feature-first separation as new modules (e.g., `fees`, `attendance`) are added.

## Cross-References
- [03_ARCHITECTURE.md](03_ARCHITECTURE.md)
- [13_MODULES.md](../04_features/13_MODULES.md)
