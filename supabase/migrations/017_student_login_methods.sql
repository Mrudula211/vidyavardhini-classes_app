-- ============================================================
-- 017_student_login_methods.sql
--
-- The admin's "App login" card must show what a person can REALLY log in
-- with. That lives in auth.users (email and/or phone), which the app cannot
-- read directly. The profile email is only a contact address for accounts
-- created through the old self-registration, so it must not be shown as the
-- login.
--
-- Safe to re-run. Requires 013 (public.is_admin).
-- ============================================================

CREATE OR REPLACE FUNCTION get_student_login_methods(p_student_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_email TEXT;
  v_phone TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the admin can view login details';
  END IF;

  SELECT NULLIF(email, ''), NULLIF(phone, '') INTO v_email, v_phone
  FROM auth.users WHERE id = p_student_id;

  RETURN jsonb_build_object(
    'email', v_email,
    'phone', CASE WHEN v_phone IS NULL THEN NULL ELSE '+' || ltrim(v_phone, '+') END
  );
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION get_student_login_methods(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION get_student_login_methods(UUID) TO authenticated;
