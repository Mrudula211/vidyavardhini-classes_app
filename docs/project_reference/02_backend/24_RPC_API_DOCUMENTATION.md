# 24 RPC and API Documentation

## Purpose
Documents the planned and existing Remote Procedure Calls (RPCs) implemented via Supabase PostgreSQL functions, and how they interact with the Flutter frontend.

## Current State
Currently, most logic is written directly in SQL or Flutter. Several RPCs are required to fix security vulnerabilities (Technical Debt).

## Required RPCs (To Be Implemented)

### 1. `verify_admin_login(p_access_code TEXT, p_password TEXT)`
- **Purpose:** Securely validates admin credentials on the server.
- **Input:** Plain text access code and password.
- **Logic:** Fetches hashes from `admin_profiles`, uses `crypt()` (pgcrypto extension) to verify.
- **Output:** Returns a custom JWT or a Boolean indicating success.
- **Caller:** `AdminLoginScreen` via `SupabaseAuthRepository`.

### 2. `verify_teacher_login(p_access_code TEXT)`
- **Purpose:** Securely validates teacher access codes on the server.
- **Input:** Plain text access code.
- **Logic:** Queries `teacher_profiles`, verifies `access_code_hash`.
- **Output:** Returns the `teacher_id` (UUID) or Null.
- **Caller:** `TeacherLoginScreen` via `SupabaseAuthRepository`.

### 3. `promote_students(p_from_year UUID, p_to_year UUID)`
- **Purpose:** Batch promotes active students from one academic year to the next.
- **Input:** Source and target `academic_years.id`.
- **Logic:** Inserts new records into `student_enrollments` mapping students to the new year. Logs action in `promotion_history`.
- **Output:** Integer (number of students promoted).
- **Caller:** Admin Settings Screen.

## Edge Functions (Deno / TypeScript)

### 1. `monthly-fee-generate`
- **Trigger:** pg_cron (1st of every month).
- **Logic:** Reads `fee_structure` and `student_profiles` (where status='active'). Bulk inserts rows into `monthly_fees` for the current month.

### 2. `fcm-push-send`
- **Trigger:** Database webhook (insert on `notifications` table).
- **Logic:** Reads `user_id`, fetches `fcm_token` from `users`, uses Firebase Admin SDK to dispatch a push notification to the device.

## Cross-References
- [14_BUG_REPORT.md](../05_quality/14_BUG_REPORT.md)
- [05_SUPABASE_ANALYSIS.md](05_SUPABASE_ANALYSIS.md)
