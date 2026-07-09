# 13 Modules

## Purpose
Breaks down the application into high-level functional modules based on the PRD.

## Current State
Modules are conceptual at this stage, defined by the folder structure in `lib/features/` and the PRD.

## Detailed Explanation
1.  **Auth Module (`features/auth`):** Handles entry, OTP verification, role selection, and registration.
2.  **Admin Module (`features/admin`):**
    *   Dashboard
    *   Student & Teacher Management (CRUD)
    *   Fee Management & Revenue Tracking
    *   Settings & Configurations (Geofence, Academic Year)
3.  **Teacher Module (`features/teacher`):**
    *   Dashboard
    *   Attendance Marking
    *   Homework/Classwork Uploading
    *   Doubt Chat
4.  **Student Module (`features/student`):**
    *   Dashboard
    *   Homework/Classwork Viewing
    *   Fee Status Viewing
    *   Attendance Viewing
5.  **Shared/Core Modules:**
    *   **Communication:** Announcements & Chat
    *   **File Handling:** PDF Viewer, Image Viewer, Uploads
    *   **Notifications:** FCM handling

## Observations
-   The separation of concerns between Admin, Teacher, and Student roles is critical and should dictate the organization of code.

## Problems
-   None; the modular design is sound.

## Recommendations
-   Maintain strict boundaries between modules. Do not leak Admin logic into Student screens, for example.

## Cross-References
- [03_ARCHITECTURE.md](../01_overview/03_ARCHITECTURE.md)
