# 12 Missing Features

## Purpose
Catalogs features documented in the PRD and roadmap that have absolutely no implementation in the Flutter codebase yet.

## Current State
The vast majority of the app features are missing from the `lib/` directory.

## Detailed Explanation
### ❌ Missing (Documented but not implemented)
1.  **Student Management (Phase 2):** Admin approval workflow, student list view.
2.  **Teacher Management (Phase 3):** Teacher list, adding teachers, assigning classes, timetable editing.
3.  **Attendance System (Phase 4):** Teacher marking attendance, student viewing attendance, Geofencing logic for teachers.
4.  **Fee Management (Phase 5):** Fee generation (Edge Function missing), payment recording, UI for student fee viewing.
5.  **Content Modules (Phase 6):** Homework and Classwork creation, listing, file uploading to Storage, PDF/Image viewing.
6.  **Announcements (Phase 7):** Creating broadcasts, filtering by role/class, UI feeds.
7.  **Private Chat (Phase 8):** Supabase Realtime integration, chat UI, file attachments in chat.
8.  **Dashboards & Finance (Phase 9):** Revenue charts, teacher salary calculation and display.
9.  **Notifications:** Firebase Cloud Messaging integration in Flutter, handling push payloads.
10. **Offline Caching:** Implementation of Hive caching for data.

## Observations
-   This represents about 90% of the total project scope.

## Problems
-   Significant development effort is required to implement these missing modules.

## Recommendations
-   Follow the `IMPLEMENTATION_BACKLOG` strictly to tackle these phase by phase.

## Cross-References
- [13_MODULES.md](13_MODULES.md)
- [22_IMPLEMENTATION_BACKLOG.md](../06_planning/22_IMPLEMENTATION_BACKLOG.md)
