# 03 Architecture

## Purpose
This document describes the high-level architecture of the application, including the frontend framework, backend services, state management, and data flow.

## Current State
The architectural foundation is laid out in code and heavily documented in `docs/ARCHITECTURE.md`. The implementation currently handles routing, theming, and initial auth state.

## Detailed Explanation
The application utilizes a modern Flutter stack:

**Frontend Stack:**
- **Framework:** Flutter 3
- **State Management:** Riverpod (using `riverpod_annotation` and code generation)
- **Routing:** GoRouter (declarative routing)
- **Local Storage:** Hive (planned for caching, initialized in `main.dart`)

**Backend Stack:**
- **BaaS:** Supabase
- **Database:** PostgreSQL (with Row Level Security - RLS)
- **Authentication:** Supabase Auth (OTP for students/teachers, Password for admin)
- **Storage:** Supabase Storage (for attachments/photos)
- **Edge Functions:** Deno-based functions for scheduled tasks (cron jobs).
- **Notifications:** Firebase Cloud Messaging (FCM)

**Data Flow:**
1. UI components watch Riverpod providers.
2. Providers interact with Repositories.
3. Repositories interface with Supabase SDK or local Hive cache.
4. GoRouter reacts to authentication state changes (via `authStateProvider`) to redirect users to appropriate role-based shells.

## Observations
- The architecture is well-suited for a real-time, offline-capable ERP.
- Riverpod code generation is set up, which reduces boilerplate.
- The reliance on Supabase RLS is a strong security pattern.

## Problems
- The offline strategy mentioned in `docs/ARCHITECTURE.md` (using Hive) is not yet implemented in any repository.
- Real-time chat architecture is documented but not implemented.

## Recommendations
- Implement a generic repository pattern for data fetching that handles local caching (Hive) and remote syncing (Supabase) transparently.
- Set up a dedicated network connectivity provider to manage online/offline states gracefully.

## Cross-References
- [04_DATABASE_ANALYSIS.md](../02_backend/04_DATABASE_ANALYSIS.md)
- [05_SUPABASE_ANALYSIS.md](../02_backend/05_SUPABASE_ANALYSIS.md)
- [06_AUTHENTICATION.md](../02_backend/06_AUTHENTICATION.md)
- [08_NAVIGATION.md](../03_frontend/08_NAVIGATION.md)
