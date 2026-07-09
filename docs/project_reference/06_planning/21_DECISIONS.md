# 21 Decisions

## Purpose
Records architectural and technical decisions made during the project's lifecycle, providing context for *why* things were done a certain way.

## Current State
Initial decisions documented based on repository analysis.

## Entries

### Decision 1: Supabase for BaaS
- **Context:** Need for a robust, real-time database with built-in auth and storage.
- **Decision:** Utilize Supabase.
- **Rationale:** PostgreSQL provides strict relational data integrity (crucial for ERPs like fees/attendance). RLS provides robust security.

### Decision 2: Riverpod for State Management
- **Context:** Need a scalable, testable state management solution in Flutter.
- **Decision:** Use Riverpod with code generation (`riverpod_annotation`).
- **Rationale:** compile-safe, reduces boilerplate, easily handles asynchronous data (FutureProviders) which is heavily used with Supabase.

### Decision 3: Move Auth Hashing to Server (Proposed/Pending)
- **Context:** Current implementation downloads password hashes to the client for verification.
- **Decision:** Must be moved to Supabase RPC functions.
- **Rationale:** Security vulnerability. Hashes must not leave the secure database boundary.

## Cross-References
- [03_ARCHITECTURE.md](../01_overview/03_ARCHITECTURE.md)
- [15_SECURITY.md](../05_quality/15_SECURITY.md)
