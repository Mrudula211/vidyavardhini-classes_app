# 22 Implementation Backlog

## Purpose
A prioritized, actionable backlog of engineering tasks derived from the Development Roadmap and Bug Reports.

## Backlog Items

### 1. Security Hotfixes & Foundation
-   **Priority:** Critical
-   **Complexity:** Medium
-   **Dependencies:** None
-   **Affected Modules:** `Auth`, `Router`
-   **Task:** Refactor `verifyAdminCredentials` and `verifyTeacherAccessCode` to use Supabase RPC. Implement global `redirect` in `go_router`. Fix missing font assets in `pubspec.yaml`.
-   **Success Criteria:** Hashes never sent to client. User cannot access unauthorized routes via direct URL changes.
-   **Links:** [14_BUG_REPORT.md](../05_quality/14_BUG_REPORT.md), [15_SECURITY.md](../05_quality/15_SECURITY.md)

### 2. Core Navigation Shells
-   **Priority:** High
-   **Complexity:** Small
-   **Dependencies:** Task 1
-   **Affected Modules:** `Router`, `Admin`, `Teacher`, `Student`
-   **Task:** Implement `StatefulShellRoute` in GoRouter for the three main role dashboards, providing bottom navigation bars.
-   **Success Criteria:** Navigating between tabs preserves state.
-   **Links:** [08_NAVIGATION.md](../03_frontend/08_NAVIGATION.md)

### 3. Data Models Generation
-   **Priority:** High
-   **Complexity:** Medium
-   **Dependencies:** None
-   **Affected Modules:** `Core`
-   **Task:** Create Dart `freezed` classes for all tables defined in `DATABASE_SCHEMA.md`.
-   **Success Criteria:** Run `build_runner` successfully, generating JSON serialization and copyWith methods for all models.
-   **Links:** [04_DATABASE_ANALYSIS.md](../02_backend/04_DATABASE_ANALYSIS.md)

### 4. Admin Workflow: User Management
-   **Priority:** High
-   **Complexity:** Large
-   **Dependencies:** Tasks 2 & 3
-   **Affected Modules:** `Admin`
-   **Task:** Build UI and Repositories for Admin to view pending students, approve them (assigning ID/Fees), and add/manage Teachers.
-   **Success Criteria:** Admin can successfully activate a student and create a teacher record in the database.
-   **Links:** [12_MISSING_FEATURES.md](../04_features/12_MISSING_FEATURES.md)

### 5. Attendance Module
-   **Priority:** Medium
-   **Complexity:** Large
-   **Dependencies:** Task 4
-   **Affected Modules:** `Teacher`, `Student`, `Admin`
-   **Task:** Implement Teacher UI to mark class attendance. Student UI to view attendance. Include Geofence service for Teacher location verification.
-   **Success Criteria:** Attendance records are successfully written to DB and visible to users. Geofence prevents marking if outside radius.
-   **Links:** [12_MISSING_FEATURES.md](../04_features/12_MISSING_FEATURES.md)

### 6. Financials: Fee Management
-   **Priority:** Medium
-   **Complexity:** Large
-   **Dependencies:** Task 4
-   **Affected Modules:** `Admin`, `Student`, `Supabase (Edge Functions)`
-   **Task:** Write Deno Edge function for monthly fee generation. Build Admin UI to record payments. Build Student UI to view status.
-   **Success Criteria:** Edge function successfully runs via pg_cron. Payments update `paid_amount` correctly via DB triggers.
-   **Links:** [05_SUPABASE_ANALYSIS.md](../02_backend/05_SUPABASE_ANALYSIS.md)

## Recommended Implementation Order
Tasks 1 -> 2 -> 3 -> 4 -> 5 -> 6. (Follow sequentially).
