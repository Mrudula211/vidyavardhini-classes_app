-- ============================================================
-- 013_fix_users_policy_recursion.sql
--
-- Bug (present since 001): the policy "users: admin read all" ON users
-- contained  EXISTS (SELECT 1 FROM users WHERE ...). Evaluating a policy on
-- `users` therefore required querying `users`, which evaluates the policy
-- again ... Postgres aborts with
--     42P17 infinite recursion detected in policy for relation "users"
-- so EVERY API query on `users` failed for logged-in people. The app could
-- not read its own role (people were sent back to the Welcome screen) and
-- could not save the FCM token. The same error also broke every other
-- table's admin policy, because those look the role up in `users` too.
--
-- Fix: do the "is this person an admin?" check in a SECURITY DEFINER helper
-- that reads `users` without row-level security, and use it in the one
-- policy that sits on `users` itself. All other policies keep working: their
-- lookup of the caller's own row is allowed by "users: own read".
--
-- Safe to re-run.
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_admin() RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin'
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

DROP POLICY IF EXISTS "users: admin read all" ON public.users;
CREATE POLICY "users: admin read all" ON public.users FOR SELECT
  USING (public.is_admin());
