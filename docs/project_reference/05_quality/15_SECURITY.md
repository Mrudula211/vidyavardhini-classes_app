# 15 Security

## Purpose
Evaluates the application's security posture, covering data access, authentication, and transport.

## Current State
Strong foundation laid with Supabase RLS, but compromised by insecure client-side implementations in Flutter.

## Detailed Explanation
**Strengths:**
-   **Row Level Security (RLS):** The SQL migrations define strict RLS policies. For example, students can only select their own attendance and fee records. Admins have broad access.
-   **JWT & OTP:** Using OTP for standard users mitigates password reuse risks.

**Weaknesses & Flaws:**
-   **Client-Side Password Verification:** Downloading bcrypt hashes to the device (`supabase_auth_repository.dart`) is a critical flaw. It exposes the hashes.
-   **Missing Route Guards:** The Flutter app currently lacks strict route guarding, meaning the UI might not properly restrict access, even if the DB does.

## Observations
-   The database layer is secure by design. The frontend layer currently undermines it.

## Problems
-   The current implementation of Admin and Teacher login violates basic security principles.

## Recommendations
1.  **Migrate Auth Logic:** Create PostgreSQL functions (RPCs) in Supabase to handle password/access code verification on the server side. The client should only send the plain text password/code and receive a boolean or session token back.
2.  **Implement GoRouter Guards:** Secure the frontend routing.
3.  **Secure Storage:** Ensure the Hive cache (when implemented) encrypts sensitive data, as mentioned in the architecture doc.

## Cross-References
- [04_DATABASE_ANALYSIS.md](../02_backend/04_DATABASE_ANALYSIS.md)
- [14_BUG_REPORT.md](14_BUG_REPORT.md)
