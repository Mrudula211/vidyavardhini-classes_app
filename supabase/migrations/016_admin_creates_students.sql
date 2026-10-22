-- ============================================================
-- 016_admin_creates_students.sql
--
-- New student onboarding: the ADMIN creates the student and the login.
-- There is no self-registration any more.
--
--   * create_student_account(): admin only. In one transaction it creates the
--     login (mobile number and/or email), the users row (role 'student'), the
--     active student_profiles row with the next STU id, the enrolment for the
--     current academic year and the monthly fee. The login password is a
--     generated 8-character ACCESS CODE (letters + digits, no lookalikes).
--   * student_access_codes: the code is kept readable so the admin can show it
--     on the student's page and share it with the parent. Admin-read-only.
--   * regenerate_student_access_code(): new code if it is lost.
--   * Self-registration is switched off at the database too: the client may
--     no longer insert its own users / student_profiles rows, and the
--     auth.users trigger that created student rows is removed.
--
-- Also turn OFF "Allow new users to sign up" in Supabase (Authentication).
--
-- Safe to re-run. Requires 011 (normalize_phone), 013 (is_admin).
-- ============================================================

-- ── readable access codes (admin only) ────────────────────
CREATE TABLE IF NOT EXISTS public.student_access_codes (
  student_id  UUID PRIMARY KEY REFERENCES public.student_profiles(id) ON DELETE CASCADE,
  access_code TEXT NOT NULL,
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
ALTER TABLE public.student_access_codes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "student_access_codes: admin read" ON public.student_access_codes;
CREATE POLICY "student_access_codes: admin read" ON public.student_access_codes
  FOR SELECT USING (public.is_admin());
-- No insert/update/delete policies: only the functions below write to it.

-- ── code generator ────────────────────────────────────────
CREATE OR REPLACE FUNCTION private.generate_access_code(p_length INTEGER DEFAULT 8)
RETURNS TEXT AS $$
DECLARE
  -- 31 symbols (23 letters + digits 2-9); no 0/O, 1/I/L to avoid reading mistakes.
  v_alphabet CONSTANT TEXT := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';
  v_bytes    BYTEA := gen_random_bytes(p_length);
  v_code     TEXT := '';
  i          INTEGER;
BEGIN
  FOR i IN 0 .. p_length - 1 LOOP
    v_code := v_code || substr(v_alphabet, (get_byte(v_bytes, i) % length(v_alphabet)) + 1, 1);
  END LOOP;
  RETURN v_code;
END;
$$ LANGUAGE plpgsql VOLATILE SET search_path = public, extensions;

REVOKE ALL ON FUNCTION private.generate_access_code(INTEGER) FROM PUBLIC, anon, authenticated;

-- ── create a student (admin only) ─────────────────────────
CREATE OR REPLACE FUNCTION create_student_account(
  p_full_name       TEXT,
  p_gender          TEXT,
  p_dob             DATE,
  p_parent_name     TEXT,
  p_parent_phone    TEXT,
  p_school_name     TEXT,
  p_board           TEXT,
  p_standard        TEXT,
  p_monthly_fee     NUMERIC,
  p_login_phone     TEXT DEFAULT NULL,
  p_login_email     TEXT DEFAULT NULL,
  p_whatsapp_number TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_uid         UUID := auth.uid();
  v_user_id     UUID := gen_random_uuid();
  v_student_id  VARCHAR;
  v_code        TEXT;
  v_login_phone TEXT := NULLIF(private.normalize_phone(p_login_phone), '');
  v_login_email TEXT := NULLIF(lower(trim(coalesce(p_login_email, ''))), '');
  v_parent      TEXT := '+' || private.normalize_phone(p_parent_phone);
  v_whatsapp    TEXT := '+' || private.normalize_phone(coalesce(NULLIF(p_whatsapp_number, ''), p_parent_phone));
  v_year_id     UUID;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the admin can add students';
  END IF;
  IF coalesce(trim(p_full_name), '') = '' THEN
    RAISE EXCEPTION 'Enter the student''s name';
  END IF;
  IF v_login_phone IS NULL AND v_login_email IS NULL THEN
    RAISE EXCEPTION 'Enter a mobile number or an email for the login';
  END IF;
  IF v_login_phone IS NOT NULL AND length(v_login_phone) <> 12 THEN
    RAISE EXCEPTION 'Enter a valid 10-digit mobile number';
  END IF;
  IF length(v_parent) <> 13 THEN
    RAISE EXCEPTION 'Enter a valid 10-digit parent mobile number';
  END IF;
  IF p_monthly_fee IS NULL OR p_monthly_fee < 0 THEN
    RAISE EXCEPTION 'Enter the monthly fee';
  END IF;
  IF v_login_phone IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE phone = v_login_phone) THEN
    RAISE EXCEPTION 'A login with this mobile number already exists';
  END IF;
  IF v_login_email IS NOT NULL AND EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = v_login_email) THEN
    RAISE EXCEPTION 'A login with this email already exists';
  END IF;

  SELECT id INTO v_year_id FROM public.academic_years WHERE is_current LIMIT 1;
  IF v_year_id IS NULL THEN
    RAISE EXCEPTION 'No current academic year is set up';
  END IF;

  v_student_id := next_student_id();
  v_code := private.generate_access_code(8);

  INSERT INTO auth.users (
    id, instance_id, aud, role, email, phone, encrypted_password,
    email_confirmed_at, phone_confirmed_at,
    raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) VALUES (
    v_user_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    v_login_email, v_login_phone, crypt(v_code, gen_salt('bf')),
    CASE WHEN v_login_email IS NOT NULL THEN NOW() END,
    CASE WHEN v_login_phone IS NOT NULL THEN NOW() END,
    jsonb_build_object('provider', CASE WHEN v_login_email IS NOT NULL THEN 'email' ELSE 'phone' END,
                       'providers', CASE WHEN v_login_email IS NOT NULL THEN '["email"]'::jsonb ELSE '["phone"]'::jsonb END),
    jsonb_build_object('full_name', p_full_name, 'created_by_admin', true), NOW(), NOW(),
    '', '', '', ''
  );

  -- Newer Supabase versions keep a row per login method; add it if possible.
  BEGIN
    IF v_login_email IS NOT NULL THEN
      INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      VALUES (gen_random_uuid(), v_user_id, v_login_email,
              jsonb_build_object('sub', v_user_id::text, 'email', v_login_email, 'email_verified', true),
              'email', NOW(), NOW(), NOW());
    END IF;
    IF v_login_phone IS NOT NULL THEN
      INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
      VALUES (gen_random_uuid(), v_user_id, v_login_phone,
              jsonb_build_object('sub', v_user_id::text, 'phone', v_login_phone, 'phone_verified', true),
              'phone', NOW(), NOW(), NOW());
    END IF;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'auth.identities row not added: %', SQLERRM;
  END;

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (v_user_id, CASE WHEN v_login_phone IS NULL THEN NULL ELSE '+' || v_login_phone END, 'student', true);

  INSERT INTO public.student_profiles (
    id, student_id, full_name, gender, dob, parent_name, parent_phone, whatsapp_number,
    email, school_name, board, standard, status, approved_by, approved_at
  ) VALUES (
    v_user_id, v_student_id, trim(p_full_name), p_gender::gender_type, p_dob, trim(p_parent_name),
    v_parent, v_whatsapp, v_login_email, trim(p_school_name), p_board::board_type,
    p_standard::standard_type, 'active', v_uid, now()
  );

  INSERT INTO public.student_enrollments (student_id, academic_year_id, board, standard)
  VALUES (v_user_id, v_year_id, p_board::board_type, p_standard::standard_type);

  INSERT INTO public.fee_structure (student_id, academic_year_id, monthly_fee)
  VALUES (v_user_id, v_year_id, p_monthly_fee);

  INSERT INTO public.student_access_codes (student_id, access_code) VALUES (v_user_id, v_code);

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id, new_value)
  VALUES (v_uid, 'student_created', 'student_profiles', v_user_id,
          jsonb_build_object('student_id', v_student_id, 'name', p_full_name));

  RETURN jsonb_build_object(
    'id', v_user_id,
    'student_id', v_student_id,
    'access_code', v_code,
    'login', coalesce(v_login_email, '+' || v_login_phone)
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION create_student_account(TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_student_account(TEXT, TEXT, DATE, TEXT, TEXT, TEXT, TEXT, TEXT, NUMERIC, TEXT, TEXT, TEXT) TO authenticated;

-- ── regenerate a lost code (admin only) ───────────────────
CREATE OR REPLACE FUNCTION regenerate_student_access_code(p_student_id UUID)
RETURNS TEXT AS $$
DECLARE
  v_code TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the admin can regenerate access codes';
  END IF;
  IF NOT EXISTS (SELECT 1 FROM public.student_profiles WHERE id = p_student_id) THEN
    RAISE EXCEPTION 'Student not found';
  END IF;

  v_code := private.generate_access_code(8);

  UPDATE auth.users
  SET encrypted_password = crypt(v_code, gen_salt('bf')), updated_at = now()
  WHERE id = p_student_id;

  INSERT INTO public.student_access_codes (student_id, access_code)
  VALUES (p_student_id, v_code)
  ON CONFLICT (student_id) DO UPDATE SET access_code = EXCLUDED.access_code, updated_at = now();

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (auth.uid(), 'student_access_code_regenerated', 'student_profiles', p_student_id);

  RETURN v_code;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION regenerate_student_access_code(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION regenerate_student_access_code(UUID) TO authenticated;

-- ── self-registration is closed ───────────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP POLICY IF EXISTS "users: insert own" ON public.users;
DROP POLICY IF EXISTS "student_profiles: own insert" ON public.student_profiles;
