# 17 Technical Debt

## Purpose
Identifies areas of the code that require refactoring or improvement to ensure long-term maintainability.

## Current State
Low technical debt due to the project being in early stages, but some immediate refactoring is required in Auth.

## Detailed Explanation
1.  **Auth Logic (`supabase_auth_repository.dart`):** The client-side hash verification is immediate technical debt that must be paid off via Server-Side RPC calls.
2.  **Missing Riverpod Code Generation:** The project uses `riverpod_annotation`, but currently, providers like `authStateProvider` are manually written using the old syntax (`Provider<T>`).

## Observations
-   Mixing old Riverpod syntax (`Provider`) with new annotation syntax (`@riverpod`) causes inconsistency.

## Problems
-   Inconsistent state management syntax.
-   Security flaw in auth.

## Recommendations
-   Standardize on `@riverpod` annotations for all providers and run `build_runner`.
-   Refactor the Auth logic immediately.

## Cross-References
- [14_BUG_REPORT.md](14_BUG_REPORT.md)
