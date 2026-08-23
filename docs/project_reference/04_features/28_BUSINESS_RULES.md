# 28 Business Rules

## Purpose
Documents the strict business rules that dictate application behavior and data validation.

## User Constraints
1. **Phone Numbers:** Must be exactly 10 digits and unique across the entire system.
2. **Role Permanence:** Once a user is assigned a role (Admin, Teacher, Student) in the `users` table, it cannot be changed. If a student becomes a teacher, a new account (different phone number) is required.
3. **Admin Exclusivity:** There is only one Admin account intended, though the schema supports multiple.

## Academic & Financial Rules
1. **Academic Year Strictness:** All records (attendance, fees, homework) *must* be tied to an `academic_year_id`. Cross-year querying is only available to the Admin in specific historical reports.
2. **Fee Records:** Fee records (`monthly_fees`) are immutable regarding the `month` and `year` once created. Only the `paid_amount` and `status` can change via payments.
3. **No Deletion:** Hard deletions are strictly prohibited for financial and attendance records. Use status flags (`inactive`, `banned`) for user accounts.
4. **Promotions:** When students are promoted at the end of the year, their old `student_enrollments` record remains (tied to the old year). A new record is created for the new year.

## Operational Rules
1. **Teacher Attendance:** Cannot be marked retroactively by the teacher. Only Admin can correct past attendance.
2. **Homework Deadlines:** Once a homework's `due_date` has passed, it visually turns red in the UI, but it remains visible.
3. **Audit Logging:** ANY change to financial data, attendance corrections, or student status MUST result in a record in the `audit_logs` table.

## Cross-References
- [04_DATABASE_ANALYSIS.md](../02_backend/04_DATABASE_ANALYSIS.md)
- [27_DETAILED_FEATURE_SPECS.md](27_DETAILED_FEATURE_SPECS.md)
