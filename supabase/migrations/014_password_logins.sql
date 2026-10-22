-- ============================================================
-- 014_password_logins.sql
--
-- Move from SMS-OTP login to password logins (no SMS provider needed):
--   * mobile number + password
--   * email + password
--   * email one-time code (fallback; handled by Supabase Auth itself)
--
-- Database changes:
--   1. public.users.phone becomes optional (email-only accounts have none).
--   2. The auth.users trigger creates the public.users row for BOTH phone and
--      email self-registrations (role 'student'); admin-created accounts
--      (flag created_by_admin) are skipped.
--   3. create_teacher_profile now takes a password and a phone and/or email,
--      so teachers can log in with a password like everyone else.
--   4. admin_reset_user_password(): lets the admin set a new password for a
--      person who forgot it (phone-only accounts cannot use email reset).
--
-- Safe to re-run. Requires 011 (normalize_phone) and 012.
-- ============================================================

-- ── 1. phone optional ─────────────────────────────────────
ALTER TABLE public.users ALTER COLUMN phone DROP NOT NULL;

-- ── 2. trigger: phone OR email accounts ───────────────────
CREATE OR REPLACE FUNCTION private.handle_new_auth_user() RETURNS TRIGGER AS $$
DECLARE
  v_phone TEXT;
BEGIN
  -- Admin-created accounts set their own role.
  IF COALESCE(NEW.raw_user_meta_data ->> 'created_by_admin', '') = 'true' THEN
    RETURN NEW;
  END IF;
  IF COALESCE(NEW.phone, '') = '' AND COALESCE(NEW.email, '') = '' THEN
    RETURN NEW;
  END IF;

  v_phone := CASE WHEN COALESCE(NEW.phone, '') = '' THEN NULL
                  ELSE '+' || private.normalize_phone(NEW.phone) END;

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (NEW.id, v_phone, 'student', true)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

-- Repair accounts without a public.users row (phone or email).
INSERT INTO public.users (id, phone, role, is_active)
SELECT a.id,
       CASE WHEN COALESCE(a.phone, '') = '' THEN NULL ELSE '+' || private.normalize_phone(a.phone) END,
       'student', true
FROM auth.users a
LEFT JOIN public.users u ON u.id = a.id
WHERE u.id IS NULL
  AND (COALESCE(a.phone, '') <> '' OR COALESCE(a.email, '') <> '')
  AND COALESCE(a.raw_user_meta_data ->> 'created_by_admin', '') <> 'true'
ON CONFLICT DO NOTHING;

-- ── 3. teacher creation with a password ───────────────────
DROP FUNCTION IF EXISTS create_teacher_profile(TEXT, TEXT, TEXT, DATE, TEXT, DATE, NUMERIC, TEXT);

CREATE OR REPLACE FUNCTION create_teacher_profile(
  p_full_name      TEXT,
  p_password       TEXT,
  p_access_code    TEXT,
  p_phone          TEXT DEFAULT NULL,
  p_email          TEXT DEFAULT NULL,
  p_gender         TEXT DEFAULT NULL,
  p_dob            DATE DEFAULT NULL,
  p_joining_date   DATE DEFAULT NULL,
  p_monthly_salary NUMERIC DEFAULT 0
) RETURNS JSONB AS $$
DECLARE
  v_user_id    UUID := gen_random_uuid();
  v_teacher_id VARCHAR;
  v_hash       VARCHAR;
  v_phone      TEXT := NULLIF(private.normalize_phone(p_phone), '');
  v_email      TEXT := NULLIF(lower(trim(coalesce(p_email, ''))), '');
  v_meta       JSONB;
  v_providers  JSONB;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can create teachers';
  END IF;
  IF v_phone IS NULL AND v_email IS NULL THEN
    RAISE EXCEPTION 'Enter a mobile number or an email address';
  END IF;
  IF v_phone IS NOT NULL AND length(v_phone) < 11 THEN
    RAISE EXCEPTION 'Enter a valid mobile number';
  END IF;
  IF p_password IS NULL OR length(p_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;
  IF p_access_code IS NULL OR length(trim(p_access_code)) <> 6 THEN
    RAISE EXCEPTION 'Access code must be 6 digits';
  END IF;
  IF v_phone IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE phone = v_phone) THEN
    RAISE EXCEPTION 'A user with this mobile number already exists';
  END IF;
  IF v_email IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_email) THEN
    RAISE EXCEPTION 'A user with this email already exists';
  END IF;

  v_teacher_id := next_teacher_id();
  v_hash := crypt(p_access_code, gen_salt('bf'));
  v_meta := jsonb_build_object('full_name', p_full_name, 'created_by_admin', true);
  v_providers := CASE WHEN v_email IS NOT NULL THEN '["email"]'::jsonb ELSE '["phone"]'::jsonb END;

  INSERT INTO auth.users (
    id, instance_id, aud, role, email, phone, encrypted_password,
    email_confirmed_at, phone_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) VALUES (
    v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    v_email, v_phone, crypt(p_password, gen_salt('bf')),
    CASE WHEN v_email IS NOT NULL THEN NOW() END,
    CASE WHEN v_phone IS NOT NULL THEN NOW() END,
    jsonb_build_object('provider', CASE WHEN v_email IS NOT NULL THEN 'email' ELSE 'phone' END,
                       'providers', v_providers),
    v_meta, NOW(), NOW(),
    '', '', '', ''
  );

  -- Newer Supabase versions also keep a row per login method in
  -- auth.identities. Try to add one; ignore if the layout differs.
  BEGIN
    IF v_email IS NOT NULL THEN
      INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      VALUES (gen_random_uuid(), v_user_id, v_email,
              jsonb_build_object('sub', v_user_id::text, 'email', v_email, 'email_verified', true),
              'email', NOW(), NOW(), NOW());
    END IF;
    IF v_phone IS NOT NULL THEN
      INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      VALUES (gen_random_uuid(), v_user_id, v_phone,
              jsonb_build_object('sub', v_user_id::text, 'phone', v_phone, 'phone_verified', true),
              'phone', NOW(), NOW(), NOW());
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'auth.identities row not added: %', SQLERRM;
  END;

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (v_user_id, CASE WHEN v_phone IS NULL THEN NULL ELSE '+' || v_phone END, 'teacher', true);

  INSERT INTO public.teacher_profiles (
    id, teacher_id, full_name, gender, dob, email, joining_date, monthly_salary, access_code_hash, is_active
  ) VALUES (
    v_user_id, v_teacher_id, p_full_name, NULLIF(p_gender, '')::gender_type, p_dob, v_email,
    p_joining_date, p_monthly_salary, v_hash, true
  );

  RETURN jsonb_build_object('id', v_user_id, 'teacher_id', v_teacher_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, DATE, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, DATE, NUMERIC) TO authenticated;

-- ── 4. admin password reset ───────────────────────────────
CREATE OR REPLACE FUNCTION admin_reset_user_password(p_user_id UUID, p_new_password TEXT)
RETURNS VOID AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can reset passwords';
  END IF;
  IF p_new_password IS NULL OR length(p_new_password) < 6 THEN
    RAISE EXCEPTION 'Password must be at least 6 characters';
  END IF;
  IF p_user_id = auth.uid() THEN
    RAISE EXCEPTION 'Change your own password from the account settings';
  END IF;

  UPDATE auth.users
  SET encrypted_password = crypt(p_new_password, gen_salt('bf')), updated_at = now()
  WHERE id = p_user_id;

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (auth.uid(), 'password_reset', 'users', p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION admin_reset_user_password(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION admin_reset_user_password(UUID, TEXT) TO authenticated;
