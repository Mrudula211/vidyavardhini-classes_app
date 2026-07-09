# 04 Database Analysis

## Purpose
Analyzes the PostgreSQL database schema defined for the application, mapping out tables, relationships, and triggers.

## Current State
The database schema is fully defined in `docs/DATABASE_SCHEMA.md` and implemented via SQL scripts in `supabase/migrations/` (`001_initial_schema.sql` and `002_triggers_functions.sql`).

## Detailed Explanation
The schema is robust and normalized, covering all aspects of the ERP:

**Key Tables & Relationships:**
1.  **Users & Profiles:**
    *   `users` (id, phone, role)
    *   `admin_profiles`, `teacher_profiles`, `student_profiles` (1-to-1 with `users`)
2.  **Academic Structure:**
    *   `academic_years` (is_current boolean)
    *   `student_enrollments` (maps student -> academic year)
    *   `teacher_assignments` (maps teacher -> academic year -> board/standard/subject)
3.  **Attendance:**
    *   `student_attendance` (student_id, date, status, reason)
    *   `teacher_attendance` (teacher_id, date, status, location)
4.  **Financials:**
    *   `fee_structure` (expected fees per board/standard)
    *   `monthly_fees` (student_id, month, expected, paid, status)
    *   `fee_payments` (transactions linked to `monthly_fees`)
    *   `teacher_salary` (monthly records)
5.  **Content & Communication:**
    *   `homework`, `classwork` (with attachment tables)
    *   `announcements` (with target audience filtering)
    *   `chat_rooms`, `messages` (for student-teacher communication)
6.  **System:**
    *   `audit_logs` (tracks sensitive operations)
    *   `notifications`
    *   `geofence_settings`

## Observations
-   Extensive use of PostgreSQL Enums (e.g., `role_type`, `board_type`, `status_type`) ensures data integrity.
-   Triggers (`002_triggers_functions.sql`) handle complex logic like auto-updating `monthly_fees.paid_amount` when a `fee_payment` is inserted.

## Problems
-   No issues found in the schema design. It aligns perfectly with the PRD.
-   Ensure that migrations are correctly applied to the Supabase instance.

## Recommendations
-   Maintain strict adherence to the existing schema when building frontend models.
-   Ensure dart classes (`freezed` models) exactly map to these DB definitions.

## Cross-References
- [05_SUPABASE_ANALYSIS.md](05_SUPABASE_ANALYSIS.md)
- [15_SECURITY.md](../05_quality/15_SECURITY.md)
