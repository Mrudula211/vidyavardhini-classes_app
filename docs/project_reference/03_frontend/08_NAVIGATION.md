# 08 Navigation

## Purpose
Explains the routing logic and access control mechanisms within the Flutter app.

## Current State
✅ Implemented using `go_router` in `lib/core/router/app_router.dart`. Shell routing (Bottom Navigation) for dashboards is planned but currently only placeholder screens exist.

## Detailed Explanation
-   **Package:** `go_router` paired with Riverpod (`appRouterProvider`).
-   **Routes:** Defined as constants in `Routes` class.
-   **Flow:**
    -   Starts at `/` (`SplashScreen`).
    -   Redirects based on `Session` and `Role` to `/admin/dashboard`, `/teacher/dashboard`, `/student/dashboard`, or `/role-select`.
    -   Auth screens (`/auth/phone`, `/auth/otp`) are top-level routes.
-   **Access Control:** The architecture dictates that route visibility is controlled by the user's role.

## Observations
-   The current `app_router.dart` does not use GoRouter's `redirect` parameter to enforce route guarding. It relies on the Splash screen to make the initial routing decision. This is a vulnerability if users try to deep-link or if state changes mid-session.

## Problems
-   **Security/Routing Flaw:** Lack of a global redirect guard in `GoRouter`.
-   Missing ShellRoutes for the bottom navigation bars required for Admin, Teacher, and Student dashboards.

## Recommendations
-   Implement `GoRouter`'s `redirect` callback, observing `authStateProvider` and `currentUserRoleProvider` to enforce strict access control (e.g., kick a student out if they navigate to `/admin`).
-   Implement `StatefulShellRoute` for the main dashboards to handle bottom navigation and preserve state across tabs.

## Cross-References
- [06_AUTHENTICATION.md](../02_backend/06_AUTHENTICATION.md)
