-- ============================================================
-- 011_security_hardening_and_auth_fixes.sql
--
-- Found during a full RLS audit (2026-10-22):
--   1. Anyone with a phone-OTP session could INSERT/UPDATE their own `users`
--      row with role = 'admin' (policies only checked auth.uid() = id).
--   2. A registering student could INSERT their own profile as status =
--      'active' with a student ID, skipping admin approval.
--   3. Teachers could INSERT their own attendance directly, bypassing the
--      server-side geofence in mark_teacher_present().
--   4. verify_admin_credentials() / verify_teacher_access_code() were callable
--      without logging in (brute-forceable) and checked a code against ALL
--      teachers rather than the caller.
--   5. audit_logs accepted client-forged rows.
-- Auth fixes:
--   6. Phone numbers were stored inconsistently, so OTP sign-in could not
--      find teacher/admin accounts (Supabase Auth stores digits only).
--   7. Rows seeded straight into auth.users had NULL token columns, which
--      makes password sign-in fail with "Database error querying schema".
--
-- Safe to re-run. Requires 008 (schema `private`).
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

-- ── 1. users: no self-promotion ───────────────────────────
DROP POLICY IF EXISTS "users: insert own" ON users;
CREATE POLICY "users: insert own" ON users FOR INSERT
  WITH CHECK (auth.uid() = id AND role = 'student');

-- Exactly one admin may exist (business rule 2). Skipped with a notice if the
-- data already violates it, so you can clean up first and re-run.
DO $$
BEGIN
  CREATE UNIQUE INDEX IF NOT EXISTS users_single_admin ON public.users ((role)) WHERE role = 'admin';
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'Could not enforce single admin (%). Resolve duplicate admin rows, then re-run.', SQLERRM;
END $$;

CREATE OR REPLACE FUNCTION private.guard_users_update() RETURNS TRIGGER AS $$
BEGIN
  -- Only API callers are restricted; SQL editor / service role are not.
  IF auth.role() = 'authenticated' THEN
    IF NEW.role IS DISTINCT FROM OLD.role THEN
      RAISE EXCEPTION 'Roles cannot be changed';
    END IF;
    IF (NEW.phone IS DISTINCT FROM OLD.phone OR NEW.is_active IS DISTINCT FROM OLD.is_active)
       AND NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
      RAISE EXCEPTION 'Only the admin can change phone or active status';
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.guard_users_update() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS users_guard_update ON users;
CREATE TRIGGER users_guard_update BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION private.guard_users_update();

-- ── 2. student self-registration must start as pending ────
DROP POLICY IF EXISTS "student_profiles: own insert" ON student_profiles;
CREATE POLICY "student_profiles: own insert" ON student_profiles FOR INSERT
  WITH CHECK (
    auth.uid() = id
    AND status = 'pending'
    AND student_id IS NULL
    AND approved_by IS NULL
    AND approved_at IS NULL
  );

-- ── 3. teacher attendance only via mark_teacher_present() ─
DROP POLICY IF EXISTS "teacher_attendance: self insert" ON teacher_attendance;

-- ── 5. audit_logs written only by DB triggers/functions ───
DROP POLICY IF EXISTS "audit_logs: insert only" ON audit_logs;

-- ── 4. access-code checks: caller-bound, rate-limited ─────
CREATE TABLE IF NOT EXISTS private.access_attempts (
  user_id      UUID PRIMARY KEY,
  failures     INTEGER NOT NULL DEFAULT 0,
  locked_until TIMESTAMPTZ
);

CREATE OR REPLACE FUNCTION private.check_attempts(p_uid UUID) RETURNS VOID AS $$
DECLARE
  v_locked TIMESTAMPTZ;
BEGIN
  SELECT locked_until INTO v_locked FROM private.access_attempts WHERE user_id = p_uid;
  IF v_locked IS NOT NULL AND v_locked > now() THEN
    RAISE EXCEPTION 'Too many failed attempts. Try again in a few minutes.';
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION private.record_attempt(p_uid UUID, p_ok BOOLEAN) RETURNS VOID AS $$
BEGIN
  IF p_ok THEN
    DELETE FROM private.access_attempts WHERE user_id = p_uid;
  ELSE
    INSERT INTO private.access_attempts (user_id, failures) VALUES (p_uid, 1)
    ON CONFLICT (user_id) DO UPDATE
      SET failures = CASE WHEN private.access_attempts.locked_until IS NOT NULL
                               AND private.access_attempts.locked_until <= now()
                          THEN 1 ELSE private.access_attempts.failures + 1 END,
          locked_until = CASE WHEN private.access_attempts.failures + 1 >= 5
                              THEN now() + interval '15 minutes' END;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.check_attempts(UUID), private.record_attempt(UUID, BOOLEAN)
  FROM PUBLIC, anon, authenticated;

CREATE OR REPLACE FUNCTION verify_my_teacher_access_code(p_access_code TEXT) RETURNS BOOLEAN AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_hash TEXT;
  v_ok   BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN RETURN FALSE; END IF;
  PERFORM private.check_attempts(v_uid);

  SELECT tp.access_code_hash INTO v_hash
  FROM teacher_profiles tp JOIN users u ON u.id = tp.id
  WHERE tp.id = v_uid AND u.role = 'teacher' AND u.is_active;

  v_ok := v_hash IS NOT NULL AND v_hash = crypt(coalesce(p_access_code, ''), v_hash);
  PERFORM private.record_attempt(v_uid, v_ok);
  RETURN v_ok;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

CREATE OR REPLACE FUNCTION verify_my_admin_credentials(p_access_code TEXT, p_password TEXT) RETURNS BOOLEAN AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_code_hash TEXT;
  v_pass_hash TEXT;
  v_ok        BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN RETURN FALSE; END IF;
  PERFORM private.check_attempts(v_uid);

  -- Password: single source of truth is Supabase Auth (so rotating it in the
  -- dashboard is enough). Access code: admin_profiles.
  SELECT ap.access_code_hash, au.encrypted_password INTO v_code_hash, v_pass_hash
  FROM admin_profiles ap
  JOIN users u ON u.id = ap.id
  JOIN auth.users au ON au.id = ap.id
  WHERE ap.id = v_uid AND u.role = 'admin';

  v_ok := v_code_hash IS NOT NULL
      AND v_code_hash = crypt(coalesce(p_access_code, ''), v_code_hash)
      AND v_pass_hash = crypt(coalesce(p_password, ''), v_pass_hash);
  PERFORM private.record_attempt(v_uid, v_ok);
  RETURN v_ok;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION verify_my_teacher_access_code(TEXT), verify_my_admin_credentials(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION verify_my_teacher_access_code(TEXT), verify_my_admin_credentials(TEXT, TEXT) TO authenticated;

-- The old unauthenticated versions are no longer callable from the API.
REVOKE ALL ON FUNCTION verify_admin_credentials(TEXT, TEXT) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION verify_teacher_access_code(TEXT) FROM PUBLIC, anon, authenticated;

-- ── 6. phone numbers: one canonical form ──────────────────
-- Supabase Auth: digits only with country code ("919876543210").
-- public.users / app: "+919876543210".
CREATE OR REPLACE FUNCTION private.normalize_phone(p TEXT) RETURNS TEXT AS $$
DECLARE
  d TEXT := regexp_replace(coalesce(p, ''), '\D', '', 'g');
BEGIN
  IF length(d) = 10 THEN d := '91' || d; END IF;
  RETURN d;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

UPDATE auth.users SET phone = private.normalize_phone(phone)
WHERE phone IS NOT NULL AND phone <> private.normalize_phone(phone);

UPDATE public.users SET phone = '+' || private.normalize_phone(phone)
WHERE phone <> '+' || private.normalize_phone(phone);

-- ── 7. seeded auth.users rows: token columns must not be NULL ──
DO $$
DECLARE
  c TEXT;
BEGIN
  FOREACH c IN ARRAY ARRAY[
    'confirmation_token', 'recovery_token', 'email_change_token_new', 'email_change',
    'email_change_token_current', 'phone_change', 'phone_change_token', 'reauthentication_token'
  ] LOOP
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'auth' AND table_name = 'users' AND column_name = c) THEN
      EXECUTE format('UPDATE auth.users SET %I = '''' WHERE %I IS NULL', c, c);
    END IF;
  END LOOP;
END $$;

-- ── teacher creation: canonical phone + sane token columns ─
CREATE OR REPLACE FUNCTION create_teacher_profile(
  p_phone TEXT,
  p_full_name TEXT,
  p_gender TEXT DEFAULT NULL,
  p_dob DATE DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_joining_date DATE DEFAULT NULL,
  p_monthly_salary NUMERIC DEFAULT 0,
  p_access_code TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_user_id    UUID := gen_random_uuid();
  v_teacher_id VARCHAR;
  v_hash       VARCHAR;
  v_auth_phone TEXT := private.normalize_phone(p_phone);
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can create teachers';
  END IF;
  IF length(v_auth_phone) < 11 THEN
    RAISE EXCEPTION 'Enter a valid phone number';
  END IF;
  IF p_access_code IS NULL OR length(trim(p_access_code)) <> 6 THEN
    RAISE EXCEPTION 'Access code must be 6 digits';
  END IF;
  IF EXISTS (SELECT 1 FROM auth.users WHERE phone = v_auth_phone) THEN
    RAISE EXCEPTION 'A user with this phone number already exists';
  END IF;

  v_teacher_id := next_teacher_id();
  v_hash := crypt(p_access_code, gen_salt('bf'));

  INSERT INTO auth.users (
    id, instance_id, aud, role, phone, phone_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) VALUES (
    v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    v_auth_phone, NOW(),
    '{"provider":"phone","providers":["phone"]}',
    jsonb_build_object('full_name', p_full_name), NOW(), NOW(),
    '', '', '', ''
  );

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (v_user_id, '+' || v_auth_phone, 'teacher', true);

  INSERT INTO public.teacher_profiles (
    id, teacher_id, full_name, gender, dob, email, joining_date, monthly_salary, access_code_hash, is_active
  ) VALUES (
    v_user_id, v_teacher_id, p_full_name, NULLIF(p_gender, '')::gender_type, p_dob, p_email,
    p_joining_date, p_monthly_salary, v_hash, true
  );

  RETURN jsonb_build_object('id', v_user_id, 'teacher_id', v_teacher_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, DATE, TEXT, DATE, NUMERIC, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, DATE, TEXT, DATE, NUMERIC, TEXT) TO authenticated;
