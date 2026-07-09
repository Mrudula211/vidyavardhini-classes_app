# 01 Project Overview

## Purpose
This document provides a high-level summary of the Vidyavardhini Classes App, an ERP system designed for coaching class management. It serves as the entry point for understanding the project's goals, scope, and target audience.

## Current State
The project is in its early stages of development (Phase 1). A foundational Flutter skeleton exists with routing, theming, and some authentication screens. The majority of the application features outlined in the PRD (Product Requirements Document) are yet to be implemented.

## Detailed Explanation
Vidyavardhini Classes is a coaching institute managed by Mrs. Siddhi Gharat. The app is designed to replace manual processes and WhatsApp-based communication. It targets a scale of 1 Admin, ~5 Teachers, and 140+ Students across SSC and CBSE boards (1st-10th standard).

The application is built on:
- **Frontend:** Flutter 3 with Material 3 design and Riverpod for state management.
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions).
- **Notifications:** Firebase Cloud Messaging (FCM).

The core modules planned include:
1. Role-based Authentication (Admin, Teacher, Student)
2. User Management (Student approval, Teacher assignment)
3. Attendance Tracking (including Geofencing for teachers)
4. Fee Management (Invoicing, tracking, reminders)
5. Content Distribution (Homework, Classwork)
6. Communication (Announcements, Private doubt-clearing chat)
7. Financial Dashboard (Revenue, Salary)

## Observations
- The documentation in the `docs/` folder is extensive and well-thought-out, providing a clear roadmap (`DEVELOPMENT_PHASES.md`), schema (`DATABASE_SCHEMA.md`), and PRD (`APP_PRD.md`).
- The actual codebase (`lib/`) is currently very sparse, containing only the initial UI for authentication and empty dashboard placeholders.
- The UI designs (`docs/UI/`) provide a clear visual direction.

## Problems
- Massive gap between documented requirements and implemented code.
- No CI/CD setup is documented or present.

## Recommendations
- Treat the `docs/` directory as the definitive source of truth for intended features.
- Follow the defined `DEVELOPMENT_PHASES.md` (or the updated roadmap in this reference) strictly to avoid scope creep.
- Ensure all new features adhere to the established architecture (Riverpod + Supabase).

## Cross-References
- [02_FOLDER_STRUCTURE.md](02_FOLDER_STRUCTURE.md)
- [03_ARCHITECTURE.md](03_ARCHITECTURE.md)
- [19_DEVELOPMENT_ROADMAP.md](../06_planning/19_DEVELOPMENT_ROADMAP.md)
