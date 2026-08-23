-- ============================================================
-- Vidyavardhini Classes — Teacher Management RPCs
-- Migration: 005
-- ============================================================

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
