-- ============================================================
-- Vidyavardhini Classes — JWT Role Claim Auth Hook
-- Migration: 006
-- ============================================================
--
-- Adds a Supabase Auth "Custom Access Token" hook that embeds the user's
-- role (admin / teacher / student) as a `user_role` claim directly in the
-- issued JWT. This lets RLS policies and client code read the role from
-- the token without an extra round trip to the `users` table.
--
-- After running this migration, you must enable the hook in the Supabase
-- Dashboard (see the manual steps at the bottom of this file) — SQL alone
-- cannot register it.

CREATE OR REPLACE FUNCTION public.custom_access_token_hook(event jsonb)
RETURNS jsonb
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  claims jsonb;
  user_role text;
BEGIN
  SELECT role::text INTO user_role
  FROM public.users
  WHERE id = (event->>'user_id')::uuid;

  claims := event->'claims';

  IF user_role IS NOT NULL THEN
    claims := jsonb_set(claims, '{user_role}', to_jsonb(user_role));
  ELSE
    claims := jsonb_set(claims, '{user_role}', 'null');
  END IF;

  event := jsonb_set(event, '{claims}', claims);

  RETURN event;
END;
$$;

-- The auth server runs as supabase_auth_admin and needs explicit access.
GRANT USAGE ON SCHEMA public TO supabase_auth_admin;
GRANT EXECUTE ON FUNCTION public.custom_access_token_hook TO supabase_auth_admin;
REVOKE EXECUTE ON FUNCTION public.custom_access_token_hook FROM authenticated, anon, public;

GRANT SELECT ON public.users TO supabase_auth_admin;
DROP POLICY IF EXISTS "Allow auth admin to read user roles" ON public.users;
CREATE POLICY "Allow auth admin to read user roles"
  ON public.users
  AS PERMISSIVE
  FOR SELECT
  TO supabase_auth_admin
  USING (true);

-- ============================================================
-- Manual step required (cannot be done via SQL):
--
-- 1. Open the Supabase Dashboard for this project.
-- 2. Go to Authentication -> Hooks.
-- 3. Under "Custom Access Token", click "Add hook".
-- 4. Choose "Postgres function" and select `custom_access_token_hook`.
-- 5. Save. New tokens issued after this point will include the
--    `user_role` claim; existing sessions will pick it up after their
--    next token refresh (or on next sign-in).
-- ============================================================
