# 06 Authentication

## Purpose
Details the authentication flow, role management, and session handling.

## Current State
✅ Partially Implemented. The UI for login flows exists, and `SupabaseAuthRepository` implements basic OTP login and role verification.

## Detailed Explanation
**Flows:**
1.  **Splash Screen:** Checks `Supabase.instance.client.auth.currentSession`. If valid, fetches user role from `users` table and redirects to appropriate dashboard.
2.  **Role Selection (`RoleSelectionScreen`):** User selects Admin, Teacher, or Student.
3.  **Phone Entry & OTP (`PhoneEntryScreen`, `OtpScreen`):** Supabase OTP implementation.
4.  **Admin/Teacher Verification:** After OTP, Admin requires an access code and password (`AdminLoginScreen`). Teachers require an access code (`TeacherLoginScreen`). Verified via `bcrypt` against hashes stored in the DB.
5.  **Student Registration:** New students fill a form (`StudentRegistrationScreen`) and enter a pending state (`PendingApprovalScreen`) until admin approval.

**State Management:**
-   `authStateProvider` listens to `onAuthStateChange`.
-   `currentUserRoleProvider` fetches the role asynchronously.

## Observations
-   Using `bcrypt` in Flutter (`verifyAdminCredentials`, `verifyTeacherAccessCode` in `SupabaseAuthRepository`) is unusual. Typically, password verification happens on the backend (e.g., via a Supabase RPC function) rather than downloading the hash to the client.

## Problems
-   **Security Flaw:** `verifyAdminCredentials` downloads `password_hash` and `access_code_hash` to the client to verify them. This is insecure.
-   **Security Flaw:** `verifyTeacherAccessCode` downloads all teacher hashes to the client to find a match.

## Recommendations
-   Refactor `verifyAdminCredentials` and `verifyTeacherAccessCode` to use PostgreSQL functions (RPC calls) via Supabase, so hashes never leave the database.
-   Implement secure storage for the session if required beyond Supabase's default handling.

## Cross-References
- [08_NAVIGATION.md](../03_frontend/08_NAVIGATION.md)
- [15_SECURITY.md](../05_quality/15_SECURITY.md)
