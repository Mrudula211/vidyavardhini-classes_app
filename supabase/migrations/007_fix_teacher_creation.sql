-- ============================================================
-- Vidyavardhini Classes — Fix Teacher Creation
-- Migration: 007
-- ============================================================
--
-- create_teacher_profile (migration 005) inserted a random UUID into
-- public.users.id without a matching auth.users row. Since
-- public.users.id REFERENCES auth.users(id), every call failed with
-- a foreign key violation (23503), which the Flutter client silently
-- swallowed and fell back to an even more broken manual insert that
-- never set `id` at all (23502 not-null violation).
--
-- This mirrors the pattern already used to seed the admin account in
-- migration 004: insert a bare auth.users row for the teacher's phone
-- number before inserting into public.users/teacher_profiles. This
-- also means teachers can sign in via phone + OTP (already supported
-- by SupabaseAuthRepository.verifyOtp for any role) with a real
-- Supabase Auth session, which the access-code-only login path never
-- established — so RLS policies scoped to auth.uid() for teacher-owned
-- data (e.g. "teacher_salary: own read") can actually work once a
-- teacher logs in that way.

CREATE OR REPLACE FUNCTION create_teacher_profile(
  p_phone TEXT,
  p_full_name TEXT,
  p_gender TEXT DEFAULT NULL,
  p_dob DATE DEFAULT NULL,
  p_email TEXT DEFAULT NULL,
  p_joining_date DATE DEFAULT NULL,
  p_monthly_salary NUMERIC DEFAULT 0,
  p_access_code TEXT DEFAULT '123456'
) RETURNS JSONB AS $$
DECLARE
  v_user_id UUID := gen_random_uuid();
  v_teacher_id VARCHAR;
  v_hash VARCHAR;
BEGIN
  v_teacher_id := next_teacher_id();
  v_hash := crypt(p_access_code, gen_salt('bf'));

  -- Insert a bare auth.users row so public.users.id's foreign key is
  -- satisfiable, and so the teacher can later sign in via phone OTP.
  INSERT INTO auth.users (
    id,
    instance_id,
    aud,
    role,
    phone,
    phone_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  ) VALUES (
    v_user_id,
    '00000000-0000-0000-0000-000000000000',
    'authenticated',
    'authenticated',
    p_phone,
    NOW(),
    '{"provider":"phone","providers":["phone"]}',
    jsonb_build_object('full_name', p_full_name),
    NOW(),
    NOW()
  );

  -- Insert into public.users
  INSERT INTO public.users (id, phone, role, is_active)
  VALUES (v_user_id, p_phone, 'teacher', true);

  -- Insert into public.teacher_profiles
  INSERT INTO public.teacher_profiles (
    id, teacher_id, full_name, gender, dob, email, joining_date, monthly_salary, access_code_hash, is_active
  ) VALUES (
    v_user_id, v_teacher_id, p_full_name, NULLIF(p_gender, '')::gender_type, p_dob, p_email, p_joining_date, p_monthly_salary, v_hash, true
  );

  RETURN jsonb_build_object('id', v_user_id, 'teacher_id', v_teacher_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
