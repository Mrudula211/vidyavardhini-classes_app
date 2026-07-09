# 11 Partially Implemented Features

## Purpose
Catalogs features that have some code present but are incomplete or non-functional.

## Current State
Authentication flows have UI but lack secure backend verification or complete integration.

## Detailed Explanation
### 🟡 Partially Implemented
1.  **Authentication UI:**
    *   `RoleSelectionScreen`, `PhoneEntryScreen`, `OtpScreen`, `AdminLoginScreen`, `TeacherLoginScreen`, `StudentRegistrationScreen` exist visually.
    *   OTP sending logic is wired up to Supabase.
2.  **Authentication Logic (`SupabaseAuthRepository`):**
    *   Admin and Teacher login logic exists but implements insecure client-side hash verification.
3.  **Dashboards:**
    *   `AdminDashboardScreen`, `TeacherDashboardScreen`, and `StudentDashboardScreen` exist as blank placeholders.
4.  **State Management (Providers):**
    *   `authStateProvider` and basic user providers exist, but comprehensive data fetching providers are missing.

## Observations
-   The UI for Auth was built out ahead of the secure backend RPC logic.

## Problems
-   Insecure hash verification in Dart code must be fixed before proceeding to production.

## Recommendations
-   Refactor Auth logic to use secure Supabase RPC calls.
-   Build out the ShellRoutes for the dashboard placeholders.

## Cross-References
- [06_AUTHENTICATION.md](../02_backend/06_AUTHENTICATION.md)
