# 19 Development Roadmap

## Purpose
A revised and prioritized roadmap based on the current state of the architecture, focusing on dependencies, risk, and logical feature progression.

## Detailed Explanation
*(Note: This adapts the original `DEVELOPMENT_PHASES.md` into a more actionable, technically prioritized roadmap).*

### Phase 1: Security & Foundation (Immediate)
**Focus:** Securing the app and finalizing the architecture.
-   Refactor Auth to use Supabase RPC for hash verification.
-   Implement `GoRouter` redirect guards.
-   Setup Hive database and generic repository patterns for offline caching.
-   Fix missing font assets.

### Phase 2: Core Data Models & Shells
**Focus:** Establishing the main UI structure.
-   Implement `StatefulShellRoute` for Admin, Teacher, and Student bottom navigation.
-   Create Dart models (`freezed`) matching the `DATABASE_SCHEMA.md` exactly.

### Phase 3: User Management (Admin Workflow)
**Focus:** Getting users into the system securely.
-   Admin UI for pending student approvals.
-   Admin UI for Teacher creation/assignment.
-   Student Profile UI.

### Phase 4: Core Operations (Attendance)
**Focus:** The highest-frequency daily action.
-   Teacher Attendance Marking UI.
-   Student Attendance Viewing UI.
-   Geofence Service integration for Teacher self-marking.

### Phase 5: Financials (Fees)
**Focus:** Revenue tracking.
-   Supabase Edge Function: `monthly-fee-generate`.
-   Admin Fee Collection UI.
-   Student Fee Status UI.

### Phase 6: Content Distribution
**Focus:** Homework & Classwork.
-   Supabase Storage integration (`StorageService`).
-   Teacher upload UI (multi-file).
-   Student view UI (PDF/Image viewers).

### Phase 7: Communication (Chat & Announcements)
**Focus:** Replacing WhatsApp.
-   Announcements broadcast UI.
-   Supabase Realtime integration for Doubt Chat.

### Phase 8: Automation & Polish
**Focus:** Notifications and final dashboards.
-   Firebase FCM integration for push notifications (Dart + Edge Functions).
-   Admin Revenue Dashboard (Charts).
-   Teacher Salary calculation.

## Justification
Security must come first (Phase 1). Navigation shells and data models (Phase 2) block all other UI work. User Management (Phase 3) is required before any data (Attendance/Fees) can be assigned to users. Attendance (Phase 4) is simpler and higher frequency than Fees (Phase 5). Communication (Phase 7) relies heavily on realtime, making it higher risk, so it's placed later.

## Cross-References
- [22_IMPLEMENTATION_BACKLOG.md](22_IMPLEMENTATION_BACKLOG.md)
