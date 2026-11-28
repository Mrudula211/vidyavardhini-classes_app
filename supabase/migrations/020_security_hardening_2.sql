-- 020: second security pass (from the 2026-11-24 audit). Safe to re-run.

-- 1. Nobody but the database itself may burn student/teacher ID numbers. The
--    create_* functions are SECURITY DEFINER, so they keep working.
REVOKE EXECUTE ON FUNCTION public.next_student_id() FROM authenticated, anon;
REVOKE EXECUTE ON FUNCTION public.next_teacher_id() FROM authenticated, anon;

-- 2. audit_logs is append-only for every API role (RLS had no update/delete
--    policy; this makes it explicit at the privilege level too).
REVOKE UPDATE, DELETE, TRUNCATE ON public.audit_logs FROM anon, authenticated;

-- 3. Resetting a password (or a teacher's access code) must also end the
--    person's existing sessions, otherwise an old login keeps working.
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

  UPDATE public.student_access_codes
  SET access_code = p_new_password, updated_at = now()
  WHERE student_id = p_user_id;

  -- End every existing login of that person.
  BEGIN
    DELETE FROM auth.refresh_tokens WHERE user_id = p_user_id::text;
    DELETE FROM auth.sessions WHERE user_id = p_user_id;
  EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'sessions not revoked: %', SQLERRM;
  END;

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (auth.uid(), 'password_reset', 'users', p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION admin_reset_user_password(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION admin_reset_user_password(UUID, TEXT) TO authenticated;

-- 4. Old credential-check functions (replaced by caller-bound versions) are
--    not used by the app any more.
DROP FUNCTION IF EXISTS public.verify_admin_credentials(TEXT, TEXT);
DROP FUNCTION IF EXISTS public.verify_teacher_access_code(TEXT);
