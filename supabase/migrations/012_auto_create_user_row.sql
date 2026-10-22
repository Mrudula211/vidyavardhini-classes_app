-- ============================================================
-- 012_auto_create_user_row.sql
--
-- Problem: a brand-new phone-OTP login creates a row in auth.users, and the
-- app then tried to INSERT the matching public.users row from the phone.
-- That insert was not landing (the account existed in auth.users with no
-- public.users row), so the role lookup came back empty and the person was
-- sent back to the Welcome screen.
--
-- Fix: create the public.users row inside the database, in the same
-- transaction as the auth account, so it can never be missing or late.
--   * self-registering (OTP) accounts become role 'student';
--   * accounts created by the admin (teachers, seeded admin) are flagged
--     with raw_user_meta_data.created_by_admin = true and are skipped, so
--     their own code keeps control of the role;
--   * existing orphaned accounts are repaired.
--
-- Safe to re-run. Requires 008 (schema `private`) and 011 (normalize_phone).
-- ============================================================

CREATE OR REPLACE FUNCTION private.handle_new_auth_user() RETURNS TRIGGER AS $$
BEGIN
  -- Admin-created accounts set their own role.
  IF COALESCE(NEW.raw_user_meta_data ->> 'created_by_admin', '') = 'true' THEN
    RETURN NEW;
  END IF;
  -- Only phone accounts self-register; email-only accounts are not ours.
  IF NEW.phone IS NULL OR NEW.phone = '' THEN
    RETURN NEW;
  END IF;

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (NEW.id, '+' || private.normalize_phone(NEW.phone), 'student', true)
  ON CONFLICT DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.handle_new_auth_user() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION private.handle_new_auth_user();

-- Repair accounts that were created before this trigger existed.
INSERT INTO public.users (id, phone, role, is_active)
SELECT a.id, '+' || private.normalize_phone(a.phone), 'student', true
FROM auth.users a
LEFT JOIN public.users u ON u.id = a.id
WHERE u.id IS NULL
  AND a.phone IS NOT NULL AND a.phone <> ''
  AND COALESCE(a.raw_user_meta_data ->> 'created_by_admin', '') <> 'true'
ON CONFLICT DO NOTHING;

-- Teacher creation: flag the account so the trigger above leaves it alone.
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
    jsonb_build_object('full_name', p_full_name, 'created_by_admin', true), NOW(), NOW(),
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
