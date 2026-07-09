# 23 Database Dictionary

## Purpose
Provides a detailed dictionary of all tables, columns, and their purposes as defined in the Supabase PostgreSQL schema. This serves as a quick reference for developers and AI agents building models or writing queries.

## Table Definitions

### 1. `users`
**Purpose:** The central identity table, linking Supabase Auth (`auth.users`) to application roles.
- `id` (UUID, PK): Matches `auth.users.id`.
- `phone` (VARCHAR): User's phone number (unique).
- `role` (role_type enum): 'admin', 'teacher', or 'student'.
- `fcm_token` (VARCHAR): For Firebase push notifications.
- `created_at` / `updated_at` (TIMESTAMPTZ).

### 2. `student_profiles`
**Purpose:** Stores student-specific metadata.
- `id` (UUID, PK): References `users.id`.
- `student_id` (VARCHAR): System generated ID (e.g., STU0001).
- `first_name`, `last_name` (VARCHAR).
- `board` (board_type enum): 'CBSE', 'SSC'.
- `standard` (standard_type enum): '1st' through '10th'.
- `school_name` (VARCHAR).
- `parent_phone` (VARCHAR).
- `status` (status_type enum): 'pending', 'active', 'inactive', 'banned'.

### 3. `teacher_profiles`
**Purpose:** Stores teacher-specific metadata.
- `id` (UUID, PK): References `users.id`.
- `teacher_id` (VARCHAR): System generated ID (e.g., TCH0001).
- `first_name`, `last_name`, `gender` (VARCHAR).
- `dob`, `joining_date` (DATE).
- `base_salary` (NUMERIC).
- `access_code_hash` (VARCHAR): bcrypt hash for login.

### 4. `academic_years`
**Purpose:** Isolates data (attendance, fees) by academic year.
- `id` (UUID, PK).
- `name` (VARCHAR): e.g., '2023-2024'.
- `start_date`, `end_date` (DATE).
- `is_current` (BOOLEAN).

### 5. `monthly_fees` & `fee_payments`
**Purpose:** Tracks expected vs. paid fees per student per month.
- `monthly_fees.id` (UUID, PK).
- `monthly_fees.student_id` (UUID, FK).
- `monthly_fees.month`, `year` (SMALLINT).
- `monthly_fees.expected_amount`, `paid_amount` (NUMERIC).
- `monthly_fees.status` (fee_status enum).
- `fee_payments.monthly_fee_id` (UUID, FK).
- `fee_payments.amount` (NUMERIC).
- `fee_payments.payment_method` (payment_method enum).

### 6. `student_attendance`
**Purpose:** Daily attendance records.
- `student_id` (UUID, FK).
- `date` (DATE).
- `status` (attendance_status enum): 'present', 'absent'.
- `reason` (TEXT): If absent.

*(Note: See [DATABASE_SCHEMA.md](../../DATABASE_SCHEMA.md) for the exhaustive SQL definitions).*

## Cross-References
- [04_DATABASE_ANALYSIS.md](04_DATABASE_ANALYSIS.md)
