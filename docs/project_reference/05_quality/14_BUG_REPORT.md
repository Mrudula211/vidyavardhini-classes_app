# 14 Bug Report

## Purpose
Tracks known bugs, compile issues, and inconsistencies found during codebase analysis.

## Current State
A few critical security and architectural bugs exist in the current implementation.

## Detailed Explanation
### 1. Insecure Hash Verification (Critical)
- **Location:** `lib/features/auth/repository/supabase_auth_repository.dart`
- **Issue:** `verifyAdminCredentials` and `verifyTeacherAccessCode` fetch hashed passwords/codes from the database to the client and perform `BCrypt.checkpw` on the device.
- **Impact:** An attacker could potentially extract the hashes if they intercept the database response or decompile the app.
- **Fix:** Move this logic to a Supabase PostgreSQL function (RPC) so validation happens on the server.

### 2. Unprotected Routing (High)
- **Location:** `lib/core/router/app_router.dart`
- **Issue:** `GoRouter` does not implement a top-level `redirect` block to guard routes based on `authStateProvider`. It relies on the `SplashScreen` for initial routing.
- **Impact:** Users might access unauthorized routes via deep linking or if auth state changes mid-session.
- **Fix:** Implement `redirect` in `GoRouter` to enforce access control globally.

### 3. Missing Font Asset (Low)
- **Location:** `pubspec.yaml`
- **Issue:** `pubspec.yaml` references `fonts/Cinzel-Regular.ttf` and `fonts/Cinzel-Bold.ttf`, but these files do not exist in the repository.
- **Impact:** The app will likely fall back to a default system font, breaking the intended visual design.
- **Fix:** Download and add the Cinzel font files to `assets/fonts/` and update `pubspec.yaml`.

## Observations
-   The bugs found are mostly architectural missteps typical in early-stage development.

## Recommendations
-   Address the Critical and High priority bugs immediately before implementing new features.

## Cross-References
- [06_AUTHENTICATION.md](../02_backend/06_AUTHENTICATION.md)
- [08_NAVIGATION.md](../03_frontend/08_NAVIGATION.md)
