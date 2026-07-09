# 05 Supabase Analysis

## Purpose
Evaluates the integration and usage of Supabase services (Auth, Database, Storage, Edge Functions).

## Current State
Supabase initialization is implemented in `main.dart`. The Auth repository utilizes Supabase Auth. The DB schema includes Row Level Security (RLS). Storage and Edge functions are documented but not yet integrated into the flutter code.

## Detailed Explanation
**1. Authentication:**
-   Integrated via `supabase_flutter`.
-   Uses OTP for login (handled in `SupabaseAuthRepository`).
-   Role assignment is done via a custom hook or trigger (documented, relies on `users` table).

**2. Database (PostgREST):**
-   RLS policies are defined in the SQL migrations, ensuring users can only access their own data, while admins have full access.
-   Flutter app uses `Supabase.instance.client.from(...)` for queries (seen in Auth logic).

**3. Storage:**
-   Buckets defined in architecture: `profile-photos`, `homework-attachments`, `classwork-attachments`, `chat-files`.
-   Currently missing implementation in Flutter.

**4. Edge Functions / pg_cron:**
-   Planned for automatic fee generation (`monthly-fee-generate`) and push notifications (`fee-reminder-push`, `send-push`).
-   Currently not implemented in the repository (missing `supabase/functions/` directory).

## Observations
-   The security model heavily relies on Supabase RLS, which is a best practice.
-   The project makes excellent use of Supabase's realtime capabilities (planned for chat).

## Problems
-   Edge functions are documented but missing from the repository structure. They need to be written in TypeScript/Deno and deployed to Supabase.

## Recommendations
-   Create a `supabase/functions/` directory and begin implementing the necessary webhook handlers (e.g., for FCM).
-   Create a dedicated `StorageService` in Flutter to handle file uploads/downloads with error handling and progress tracking.

## Cross-References
- [04_DATABASE_ANALYSIS.md](04_DATABASE_ANALYSIS.md)
- [06_AUTHENTICATION.md](06_AUTHENTICATION.md)
- [15_SECURITY.md](../05_quality/15_SECURITY.md)
