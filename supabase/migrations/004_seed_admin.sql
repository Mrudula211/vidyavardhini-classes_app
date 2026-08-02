-- ============================================================
-- Vidyavardhini Classes — Seed Initial Academic Year & Admin
-- Migration: 004
-- ============================================================

-- 1. Insert current academic year
INSERT INTO academic_years (year_label, start_date, end_date, is_current)
VALUES ('2026-2027', '2026-04-01', '2027-03-31', true)
ON CONFLICT (year_label) DO NOTHING;

-- 2. Seed Admin User directly into Auth and Public tables
DO $$
DECLARE
  v_admin_id UUID := gen_random_uuid();
  v_phone VARCHAR := '+918888602496';
  v_email VARCHAR := 'siddhigharat81@gmail.com';
  v_password VARCHAR := 'Vidyavardhini-classes81';
  v_access_code VARCHAR := '123456';
BEGIN
  -- If admin profile exists, update credentials; otherwise insert
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE role = 'admin') THEN
    
    -- Insert into Supabase auth.users
    INSERT INTO auth.users (
      id,
      instance_id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      phone,
      phone_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at
    ) VALUES (
      v_admin_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      v_email,
      crypt(v_password, gen_salt('bf')),
      NOW(),
      v_phone,
      NOW(),
      '{"provider":"email","providers":["email"]}',
      '{"full_name":"Siddhi Gharat"}',
      NOW(),
      NOW()
    );

    -- Insert into public.users
    INSERT INTO public.users (id, phone, role, is_active)
    VALUES (v_admin_id, v_phone, 'admin', true);

    -- Insert into public.admin_profiles
    INSERT INTO public.admin_profiles (id, full_name, email, access_code_hash, password_hash)
    VALUES (
      v_admin_id,
      'Siddhi Gharat',
      v_email,
      crypt(v_access_code, gen_salt('bf')),
      crypt(v_password, gen_salt('bf'))
    );

    RAISE NOTICE 'Admin user seeded successfully with ID: %', v_admin_id;
  ELSE
    -- Update existing admin profile with new credentials
    SELECT id INTO v_admin_id FROM public.users WHERE role = 'admin' LIMIT 1;

    UPDATE auth.users
    SET email = v_email,
        phone = v_phone,
        encrypted_password = crypt(v_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_admin_id;

    UPDATE public.users
    SET phone = v_phone
    WHERE id = v_admin_id;

    UPDATE public.admin_profiles
    SET full_name = 'Siddhi Gharat',
        email = v_email,
        access_code_hash = crypt(v_access_code, gen_salt('bf')),
        password_hash = crypt(v_password, gen_salt('bf')),
        updated_at = NOW()
    WHERE id = v_admin_id;

    RAISE NOTICE 'Admin user updated successfully for ID: %', v_admin_id;
  END IF;
END $$;
