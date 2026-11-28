-- ============================================================
-- 018_review_fixes.sql
--
-- Fixes from the independent database/security review (2026-11-21).
-- Run this LAST (after 001-017) and re-run it after re-running any earlier
-- file: part A re-closes things that older "safe to re-run" files reopen.
--
--  A. Re-close self-registration (011/012/014 recreate policies, a trigger and
--     an old function overload that 016 removed).
--  B. is_admin() must be callable by the auth system role too.
--  C. Rate limiting really works (a failure used to be rolled back by the
--     RAISE that followed it; the lock timer was computed wrongly) and the
--     access-code change also needs the current access code.
--  D. Teachers can no longer read their own access-code hash (6 digits could
--     be cracked offline): hashes move to a private table. Admin password
--     hash column is emptied (login uses Supabase Auth). Audit rows stop
--     recording hashes (and existing ones are scrubbed).
--  E. Attachment rows must point inside the uploader's own storage folder.
--  F. Chat: rooms only with real teachers, ids frozen, messages cannot be
--     rewritten; legacy `messages` table made read-only.
--  G. Teachers are limited to their assigned classes for attendance,
--     homework and classwork writes.
--  H. Announcements are no longer readable without logging in; teachers can
--     no longer read the raw geofence coordinates.
--  I. Student ids cannot be changed once set; sequence functions closed to
--     anon; stale student access code after an admin password reset.
--  J. Missing indexes.
--
-- Safe to re-run.
-- ============================================================

-- ── A. self-registration stays closed ─────────────────────
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
DROP POLICY IF EXISTS "users: insert own" ON public.users;
DROP POLICY IF EXISTS "student_profiles: own insert" ON public.student_profiles;
DROP FUNCTION IF EXISTS public.create_teacher_profile(TEXT, TEXT, TEXT, DATE, TEXT, DATE, NUMERIC, TEXT);

-- ── B. is_admin() for the auth system role ────────────────
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'supabase_auth_admin') THEN
    GRANT EXECUTE ON FUNCTION public.is_admin() TO supabase_auth_admin;
  END IF;
END $$;

-- ── C. working rate limit + stronger code change ──────────
CREATE OR REPLACE FUNCTION private.record_attempt(p_uid UUID, p_ok BOOLEAN) RETURNS VOID AS $$
DECLARE
  v_failures INTEGER;
BEGIN
  IF p_ok THEN
    DELETE FROM private.access_attempts WHERE user_id = p_uid;
    RETURN;
  END IF;

  INSERT INTO private.access_attempts (user_id, failures) VALUES (p_uid, 1)
  ON CONFLICT (user_id) DO UPDATE
    SET failures = CASE WHEN private.access_attempts.locked_until IS NOT NULL
                             AND private.access_attempts.locked_until <= now()
                        THEN 1 ELSE private.access_attempts.failures + 1 END
  RETURNING failures INTO v_failures;

  UPDATE private.access_attempts
  SET locked_until = CASE WHEN v_failures >= 5 THEN now() + interval '15 minutes' ELSE NULL END
  WHERE user_id = p_uid;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.record_attempt(UUID, BOOLEAN) FROM PUBLIC, anon, authenticated;

DROP FUNCTION IF EXISTS public.change_my_admin_access_code(TEXT, TEXT);

-- Returns FALSE (instead of raising) on a wrong password/code, so that the
-- recorded failure is committed and the lock-out can accumulate.
CREATE OR REPLACE FUNCTION change_my_admin_access_code(
  p_current_password TEXT,
  p_current_code     TEXT,
  p_new_code         TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_pass_hash TEXT;
  v_code_hash TEXT;
  v_ok        BOOLEAN;
BEGIN
  IF v_uid IS NULL OR NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_uid AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can change the access code';
  END IF;
  IF p_new_code IS NULL OR p_new_code !~ '^[0-9]{6}$' THEN
    RAISE EXCEPTION 'The access code must be exactly 6 digits';
  END IF;

  PERFORM private.check_attempts(v_uid);

  SELECT au.encrypted_password, ap.access_code_hash INTO v_pass_hash, v_code_hash
  FROM auth.users au JOIN public.admin_profiles ap ON ap.id = au.id
  WHERE au.id = v_uid;

  v_ok := v_pass_hash IS NOT NULL AND v_code_hash IS NOT NULL
      AND v_pass_hash = crypt(coalesce(p_current_password, ''), v_pass_hash)
      AND v_code_hash = crypt(coalesce(p_current_code, ''), v_code_hash);
  PERFORM private.record_attempt(v_uid, v_ok);
  IF NOT v_ok THEN
    RETURN FALSE;
  END IF;

  UPDATE public.admin_profiles
  SET access_code_hash = crypt(p_new_code, gen_salt('bf')), updated_at = now()
  WHERE id = v_uid;

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (v_uid, 'admin_access_code_changed', 'admin_profiles', v_uid);
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION change_my_admin_access_code(TEXT, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION change_my_admin_access_code(TEXT, TEXT, TEXT) TO authenticated;

-- ── D. hashes out of reach ────────────────────────────────
CREATE TABLE IF NOT EXISTS private.teacher_access_codes (
  teacher_id UUID PRIMARY KEY,
  code_hash  TEXT NOT NULL
);
ALTER TABLE private.teacher_access_codes ENABLE ROW LEVEL SECURITY;

INSERT INTO private.teacher_access_codes (teacher_id, code_hash)
SELECT id, access_code_hash FROM public.teacher_profiles
WHERE access_code_hash IS NOT NULL AND access_code_hash <> ''
ON CONFLICT (teacher_id) DO NOTHING;

ALTER TABLE public.teacher_profiles ALTER COLUMN access_code_hash DROP NOT NULL;
UPDATE public.teacher_profiles SET access_code_hash = NULL WHERE access_code_hash IS NOT NULL;

-- The admin's login password lives in Supabase Auth only.
ALTER TABLE public.admin_profiles ALTER COLUMN password_hash DROP NOT NULL;
UPDATE public.admin_profiles SET password_hash = NULL WHERE password_hash IS NOT NULL;

CREATE OR REPLACE FUNCTION verify_my_teacher_access_code(p_access_code TEXT) RETURNS BOOLEAN AS $$
DECLARE
  v_uid  UUID := auth.uid();
  v_hash TEXT;
  v_ok   BOOLEAN;
BEGIN
  IF v_uid IS NULL THEN RETURN FALSE; END IF;
  PERFORM private.check_attempts(v_uid);

  SELECT tac.code_hash INTO v_hash
  FROM private.teacher_access_codes tac
  JOIN public.users u ON u.id = tac.teacher_id
  WHERE tac.teacher_id = v_uid AND u.role = 'teacher' AND u.is_active;

  v_ok := v_hash IS NOT NULL AND v_hash = crypt(coalesce(p_access_code, ''), v_hash);
  PERFORM private.record_attempt(v_uid, v_ok);
  RETURN v_ok;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION verify_my_teacher_access_code(TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION verify_my_teacher_access_code(TEXT) TO authenticated;

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

  -- The access-code hash is kept in the private table, not on the profile.
  INSERT INTO public.teacher_profiles (
    id, teacher_id, full_name, gender, dob, email, joining_date, monthly_salary, access_code_hash, is_active
  ) VALUES (
    v_user_id, v_teacher_id, p_full_name, NULLIF(p_gender, '')::gender_type, p_dob, v_email,
    p_joining_date, p_monthly_salary, NULL, true
  );
  INSERT INTO private.teacher_access_codes (teacher_id, code_hash) VALUES (v_user_id, v_hash);

  RETURN jsonb_build_object('id', v_user_id, 'teacher_id', v_teacher_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, DATE, NUMERIC) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION create_teacher_profile(TEXT, TEXT, TEXT, TEXT, TEXT, TEXT, DATE, DATE, NUMERIC) TO authenticated;

-- audit rows must never carry credential material
CREATE OR REPLACE FUNCTION private.audit_row() RETURNS TRIGGER AS $$
DECLARE
  v_uid UUID := auth.uid();
  v_row JSONB := to_jsonb(COALESCE(NEW, OLD));
BEGIN
  IF v_uid IS NULL OR NOT EXISTS (SELECT 1 FROM public.users WHERE id = v_uid) THEN
    RETURN NULL;
  END IF;
  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id, old_value, new_value)
  VALUES (
    v_uid,
    TG_ARGV[0] || '_' || lower(TG_OP),
    TG_TABLE_NAME,
    NULLIF(v_row ->> 'id', '')::uuid,
    CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) - 'access_code_hash' - 'password_hash' - 'fcm_token' END,
    CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) - 'access_code_hash' - 'password_hash' - 'fcm_token' END
  );
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.audit_row() FROM PUBLIC, anon, authenticated;

-- One-time scrub of credential material already written to the audit log
-- (the migration runs as the table owner; RLS does not apply).
UPDATE public.audit_logs
SET old_value = old_value - 'access_code_hash' - 'password_hash' - 'fcm_token',
    new_value = new_value - 'access_code_hash' - 'password_hash' - 'fcm_token'
WHERE (old_value ?| ARRAY['access_code_hash', 'password_hash', 'fcm_token'])
   OR (new_value ?| ARRAY['access_code_hash', 'password_hash', 'fcm_token']);

-- ── E. attachments stay inside the uploader's folder ──────
DROP POLICY IF EXISTS "homework_attachments: teacher insert" ON public.homework_attachments;
CREATE POLICY "homework_attachments: teacher insert" ON public.homework_attachments FOR INSERT
  WITH CHECK (
    file_url LIKE auth.uid()::text || '/%'
    AND EXISTS (SELECT 1 FROM public.homework h WHERE h.id = homework_id AND h.teacher_id = auth.uid())
  );

DROP POLICY IF EXISTS "classwork_attachments: teacher insert" ON public.classwork_attachments;
CREATE POLICY "classwork_attachments: teacher insert" ON public.classwork_attachments FOR INSERT
  WITH CHECK (
    file_url LIKE auth.uid()::text || '/%'
    AND EXISTS (SELECT 1 FROM public.classwork c WHERE c.id = classwork_id AND c.teacher_id = auth.uid())
  );

-- ── F. chat hardening ─────────────────────────────────────
DROP POLICY IF EXISTS "chat_rooms: student create" ON public.chat_rooms;
CREATE POLICY "chat_rooms: student create" ON public.chat_rooms FOR INSERT
  WITH CHECK (
    auth.uid() = student_id
    AND EXISTS (SELECT 1 FROM public.users t WHERE t.id = teacher_id AND t.role = 'teacher' AND t.is_active)
  );

CREATE OR REPLACE FUNCTION private.freeze_chat_room_members() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.student_id IS DISTINCT FROM OLD.student_id OR NEW.teacher_id IS DISTINCT FROM OLD.teacher_id THEN
    RAISE EXCEPTION 'A chat room''s members cannot be changed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;
REVOKE ALL ON FUNCTION private.freeze_chat_room_members() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS chat_rooms_freeze_members ON public.chat_rooms;
CREATE TRIGGER chat_rooms_freeze_members BEFORE UPDATE ON public.chat_rooms
  FOR EACH ROW EXECUTE FUNCTION private.freeze_chat_room_members();

-- Only the read flag of a message may change after it is sent.
CREATE OR REPLACE FUNCTION private.freeze_chat_message() RETURNS TRIGGER AS $$
BEGIN
  IF NEW.room_id IS DISTINCT FROM OLD.room_id
     OR NEW.sender_id IS DISTINCT FROM OLD.sender_id
     OR NEW.content IS DISTINCT FROM OLD.content
     OR NEW.message_type IS DISTINCT FROM OLD.message_type
     OR NEW.file_url IS DISTINCT FROM OLD.file_url
     OR NEW.created_at IS DISTINCT FROM OLD.created_at THEN
    RAISE EXCEPTION 'A sent message cannot be edited';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;
REVOKE ALL ON FUNCTION private.freeze_chat_message() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS chat_messages_freeze ON public.chat_messages;
CREATE TRIGGER chat_messages_freeze BEFORE UPDATE ON public.chat_messages
  FOR EACH ROW EXECUTE FUNCTION private.freeze_chat_message();

-- Legacy table (unused by the app): read-only for room members.
DROP POLICY IF EXISTS "messages: room member" ON public.messages;
DROP POLICY IF EXISTS "messages: room member read" ON public.messages;
CREATE POLICY "messages: room member read" ON public.messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM public.chat_rooms cr WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid()))
);

-- ── G. teachers limited to their assigned classes ─────────
DROP POLICY IF EXISTS "student_attendance: teacher write" ON public.student_attendance;
CREATE POLICY "student_attendance: teacher write" ON public.student_attendance FOR INSERT
  WITH CHECK (
    marked_by = auth.uid()
    AND EXISTS (
      SELECT 1
      FROM public.student_enrollments se
      JOIN public.academic_years ay ON ay.id = se.academic_year_id AND ay.is_current
      JOIN public.teacher_assignments ta
        ON ta.academic_year_id = se.academic_year_id
       AND ta.board = se.board AND ta.standard = se.standard
      WHERE se.student_id = student_attendance.student_id
        AND ta.teacher_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "student_attendance: teacher read" ON public.student_attendance;
CREATE POLICY "student_attendance: teacher read" ON public.student_attendance FOR SELECT
  USING (
    EXISTS (
      SELECT 1
      FROM public.student_enrollments se
      JOIN public.teacher_assignments ta
        ON ta.academic_year_id = se.academic_year_id
       AND ta.board = se.board AND ta.standard = se.standard
      WHERE se.student_id = student_attendance.student_id
        AND ta.teacher_id = auth.uid()
    )
  );

DROP POLICY IF EXISTS "homework: teacher own" ON public.homework;
CREATE POLICY "homework: teacher own" ON public.homework FOR ALL
  USING (auth.uid() = teacher_id)
  WITH CHECK (
    auth.uid() = teacher_id
    AND EXISTS (
      SELECT 1 FROM public.teacher_assignments ta
      WHERE ta.teacher_id = auth.uid()
        AND ta.academic_year_id = homework.academic_year_id
        AND ta.board = homework.board AND ta.standard = homework.standard
    )
  );

DROP POLICY IF EXISTS "classwork: teacher own" ON public.classwork;
CREATE POLICY "classwork: teacher own" ON public.classwork FOR ALL
  USING (auth.uid() = teacher_id)
  WITH CHECK (
    auth.uid() = teacher_id
    AND EXISTS (
      SELECT 1 FROM public.teacher_assignments ta
      WHERE ta.teacher_id = auth.uid()
        AND ta.academic_year_id = classwork.academic_year_id
        AND ta.board = classwork.board AND ta.standard = classwork.standard
    )
  );

-- ── H. no anonymous reads; geofence coordinates stay with the admin ──
DROP POLICY IF EXISTS "announcements: general read" ON public.announcements;
CREATE POLICY "announcements: general read" ON public.announcements FOR SELECT TO authenticated
  USING (
    is_active = true
    AND (expires_at IS NULL OR expires_at > now())
    AND (
      type IN ('general', 'emergency')
      OR (type = 'staff' AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role IN ('teacher', 'admin')))
    )
  );

DROP POLICY IF EXISTS "geofence_settings: teacher read" ON public.geofence_settings;

-- ── I. identifiers and sequences ──────────────────────────
CREATE OR REPLACE FUNCTION private.keep_student_id() RETURNS TRIGGER AS $$
BEGIN
  IF OLD.student_id IS NOT NULL AND NEW.student_id IS DISTINCT FROM OLD.student_id THEN
    RAISE EXCEPTION 'A student ID is permanent and cannot be changed';
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SET search_path = public;
REVOKE ALL ON FUNCTION private.keep_student_id() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS student_profiles_keep_id ON public.student_profiles;
CREATE TRIGGER student_profiles_keep_id BEFORE UPDATE ON public.student_profiles
  FOR EACH ROW EXECUTE FUNCTION private.keep_student_id();

REVOKE ALL ON FUNCTION public.next_student_id() FROM PUBLIC, anon;
REVOKE ALL ON FUNCTION public.next_teacher_id() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.next_student_id() TO authenticated;
GRANT EXECUTE ON FUNCTION public.next_teacher_id() TO authenticated;

-- A password reset must also update the stored student access code.
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

  INSERT INTO public.audit_logs (performed_by, action, entity_type, entity_id)
  VALUES (auth.uid(), 'password_reset', 'users', p_user_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION admin_reset_user_password(UUID, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION admin_reset_user_password(UUID, TEXT) TO authenticated;

-- ── J. indexes ────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS fee_payments_monthly_fee_idx ON public.fee_payments (monthly_fee_id);
CREATE INDEX IF NOT EXISTS homework_teacher_idx ON public.homework (teacher_id);
CREATE INDEX IF NOT EXISTS classwork_teacher_idx ON public.classwork (teacher_id);
CREATE INDEX IF NOT EXISTS chat_rooms_teacher_idx ON public.chat_rooms (teacher_id);
CREATE INDEX IF NOT EXISTS student_enrollments_year_idx ON public.student_enrollments (academic_year_id);
