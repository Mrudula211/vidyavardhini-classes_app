-- ============================================================
-- Vidyavardhini Classes — Seed Initial Academic Year & Admin
-- Migration: 004
-- ============================================================

-- 1. Insert current academic year
INSERT INTO academic_years (year_label, start_date, end_date, is_current)
VALUES ('2026-2027', '2026-04-01', '2027-03-31', true)
ON CONFLICT (year_label) DO NOTHING;

-- 2. Seed Admin User directly into Auth and Public tables
--
-- SECURITY: this file previously contained the real admin credentials and
-- re-running it reset the admin password to them. They have been removed.
-- Fill the four values below ONLY when seeding a brand-new project, never
-- commit them, and prefer creating the admin in Dashboard -> Authentication
-- -> Users (then insert the public.users / admin_profiles rows).
-- It never modifies an existing admin.
DO $$
DECLARE
  v_admin_id UUID := gen_random_uuid();
  v_phone VARCHAR := 'CHANGE_ME_E164_PHONE_E_G_918888888888';
  v_email VARCHAR := 'CHANGE_ME_EMAIL';
  v_password VARCHAR := 'CHANGE_ME_PASSWORD';
  v_access_code VARCHAR := 'CHANGE_ME_6_DIGITS';
BEGIN
  IF v_password LIKE 'CHANGE_ME%' OR v_email LIKE 'CHANGE_ME%' OR v_phone LIKE 'CHANGE_ME%' THEN
    RAISE EXCEPTION 'Edit the CHANGE_ME values in 004_seed_admin.sql before running it';
  END IF;

  IF EXISTS (SELECT 1 FROM public.users WHERE role = 'admin') THEN
    RAISE NOTICE 'An admin already exists; nothing changed.';
    RETURN;
  END IF;

  INSERT INTO auth.users (
    id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
    phone, phone_confirmed_at, raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
    confirmation_token, recovery_token, email_change_token_new, email_change
  ) VALUES (
    v_admin_id, '00000000-0000-0000-0000-000000000000', 'authenticated', 'authenticated',
    v_email, crypt(v_password, gen_salt('bf')), NOW(),
    regexp_replace(v_phone, '\D', '', 'g'), NOW(),
    '{"provider":"email","providers":["email"]}', '{"full_name":"Admin","created_by_admin":true}', NOW(), NOW(),
    '', '', '', ''
  );

  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (v_admin_id, '+' || regexp_replace(v_phone, '\D', '', 'g'), 'admin', true);

  INSERT INTO public.admin_profiles (id, full_name, email, access_code_hash, password_hash)
  VALUES (v_admin_id, 'Admin', v_email, crypt(v_access_code, gen_salt('bf')), crypt(v_password, gen_salt('bf')));

  RAISE NOTICE 'Admin user seeded with ID: %', v_admin_id;
END $$;
