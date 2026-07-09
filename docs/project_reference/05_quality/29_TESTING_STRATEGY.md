# 29 Testing Strategy

## Purpose
Defines the approach for ensuring code quality and application stability across different layers of the stack.

## 1. Unit Testing (Dart / Logic)
**Scope:** Utility functions, data parsing, formatting, and complex state management logic (Riverpod Notifiers).
**Tools:** `flutter_test`, `mockito`.
**Key Areas:**
- Fee calculation logic (ensuring partial vs paid status is calculated accurately).
- Geofence distance calculation.
- Date/Time formatters (crucial for timetables and attendance).

## 2. Widget Testing (UI)
**Scope:** Shared components and critical forms.
**Tools:** `flutter_test`.
**Key Areas:**
- `PrimaryButton` loading states.
- Auth forms (verifying that validation errors appear when fields are empty or invalid).
- Ensuring Role-based UI components (e.g., Edit buttons) only render when expected.

## 3. Integration Testing (E2E)
**Scope:** Full user journeys mimicking real interactions.
**Tools:** `integration_test` (Flutter).
**Key Flows:**
- Student login -> Views pending screen.
- Admin login -> Approves student.
- Teacher login -> Marks attendance (mocking GPS).
- Admin fee payment collection flow.

## 4. Backend Testing (Supabase)
**Scope:** RLS policies and PostgreSQL triggers.
**Tools:** pgTAP (or manual verification scripts).
**Key Areas:**
- Verify a Student token cannot select from `teacher_salary`.
- Verify a `fee_payment` insert correctly updates `monthly_fees`.

## CI/CD Pipeline
- GitHub Actions must run `flutter analyze` and all Unit/Widget tests on every PR targeting `main`.
- Failing tests block the merge.

## Cross-References
- [30_CODING_STANDARDS.md](../07_handbook/30_CODING_STANDARDS.md)
- [31_DEPLOYMENT_GUIDE.md](../07_handbook/31_DEPLOYMENT_GUIDE.md)
