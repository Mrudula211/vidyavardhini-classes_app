# 24 RPC and API Documentation

## Purpose
Documents the planned and existing Remote Procedure Calls (RPCs) implemented via Supabase PostgreSQL functions, and how they interact with the Flutter frontend.

## Current State
Most auth-critical logic now runs server-side via RPCs (migration `003_auth_rpc.sql`). Student promotion is still pending.

## Implemented RPCs

### 1. `verify_admin_credentials(p_access_code TEXT, p_password TEXT)`
- **Purpose:** Securely validates admin credentials on the server.
- **Input:** Plain text access code and password.
- **Logic:** Fetches hashes from `admin_profiles`, uses `crypt()` (pgcrypto extension) to verify.
- **Output:** Boolean indicating success.
- **Caller:** `AdminLoginScreen` via `SupabaseAuthRepository`.
- **Defined in:** `supabase/migrations/003_auth_rpc.sql`

### 2. `verify_teacher_access_code(p_access_code TEXT)`
- **Purpose:** Securely validates teacher access codes on the server.
- **Input:** Plain text access code.
- **Logic:** Queries `teacher_profiles`, verifies `access_code_hash` against all teachers.
- **Output:** Boolean indicating whether the code matches any teacher.
- **Caller:** `TeacherLoginScreen` via `SupabaseAuthRepository`.
- **Defined in:** `supabase/migrations/003_auth_rpc.sql`

## Required RPCs (To Be Implemented)

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
