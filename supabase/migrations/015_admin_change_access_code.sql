-- ============================================================
-- 015_admin_change_access_code.sql
--
-- Lets the signed-in admin change their own access code from the app.
-- (The password is changed through Supabase Auth itself, auth.updateUser.)
--
-- Safeguards: admin only; the current password must be supplied and is
-- checked against Supabase Auth; failed tries are rate-limited with the same
-- lock-out as the login checks; the change is written to the audit log.
--
-- Safe to re-run. Requires 011 (private.check_attempts / record_attempt).
-- ============================================================

CREATE OR REPLACE FUNCTION change_my_admin_access_code(
  p_current_password TEXT,
  p_new_code         TEXT
) RETURNS VOID AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_pass_hash TEXT;
  v_ok        BOOLEAN;
BEGIN
  IF v_uid IS NULL OR NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_uid AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can change the access code';
  END IF;
  IF p_new_code IS NULL OR p_new_code !~ '^[0-9]{6}$' THEN
    RAISE EXCEPTION 'The access code must be exactly 6 digits';
  END IF;

  PERFORM private.check_attempts(v_uid);

  SELECT encrypted_password INTO v_pass_hash FROM auth.users WHERE id = v_uid;
  v_ok := v_pass_hash IS NOT NULL
      AND v_pass_hash = crypt(coalesce(p_current_password, ''), v_pass_hash);
  PERFORM private.record_attempt(v_uid, v_ok);
  IF NOT v_ok THEN
    RAISE EXCEPTION 'The current password is not correct';
  END IF;

  UPDATE public.admin_profiles
  SET access_code_hash = crypt(p_new_code, gen_salt('bf')), updated_at = now()
  WHERE id = v_uid;

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (v_uid, 'admin_access_code_changed', 'admin_profiles', v_uid);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION change_my_admin_access_code(TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION change_my_admin_access_code(TEXT, TEXT) TO authenticated;
