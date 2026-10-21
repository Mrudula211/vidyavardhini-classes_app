-- ============================================================
-- 010_attachments_geofence_promotion_audit.sql
--
--   A. Fix homework/classwork student-read RLS (unqualified `board`/`standard`
--      inside the subquery resolved to the enrollment row, so the class check
--      was always true and any student could read every class's content).
--   B. Private storage buckets + policies for homework/classwork attachments.
--   C. mark_teacher_present(): server-side geofence check-in (business rule 7).
--   D. promote_students(): academic-year promotion guarded by CONFIRM text,
--      admin password and a recent SMS-OTP login (business rule 10).
--   E. send_fee_reminder(): admin-triggered reminder for one student.
--   F. Audit triggers so sensitive writes actually reach audit_logs.
--
-- Safe to re-run.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── A. student-read policies ──────────────────────────────
DROP POLICY IF EXISTS "homework: student read" ON homework;
CREATE POLICY "homework: student read" ON homework FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM student_enrollments se
    JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
    JOIN student_profiles sp ON sp.id = se.student_id AND sp.status = 'active'
    WHERE se.student_id = auth.uid()
      AND se.academic_year_id = homework.academic_year_id
      AND se.board = homework.board
      AND se.standard = homework.standard
  )
);

DROP POLICY IF EXISTS "classwork: student read" ON classwork;
CREATE POLICY "classwork: student read" ON classwork FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM student_enrollments se
    JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
    JOIN student_profiles sp ON sp.id = se.student_id AND sp.status = 'active'
    WHERE se.student_id = auth.uid()
      AND se.academic_year_id = classwork.academic_year_id
      AND se.board = classwork.board
      AND se.standard = classwork.standard
  )
);

-- ── B. attachment storage ─────────────────────────────────
INSERT INTO storage.buckets (id, name, public, file_size_limit)
VALUES
  ('homework-attachments',  'homework-attachments',  false, 20971520),
  ('classwork-attachments', 'classwork-attachments', false, 20971520)
ON CONFLICT (id) DO UPDATE SET public = false, file_size_limit = EXCLUDED.file_size_limit;

-- Object path convention: <teacher_uid>/<timestamp>_<filename>
DROP POLICY IF EXISTS "attachments: teacher upload" ON storage.objects;
CREATE POLICY "attachments: teacher upload" ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id IN ('homework-attachments', 'classwork-attachments')
    AND (storage.foldername(name))[1] = auth.uid()::text
    AND EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'teacher')
  );

DROP POLICY IF EXISTS "attachments: teacher delete own" ON storage.objects;
CREATE POLICY "attachments: teacher delete own" ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id IN ('homework-attachments', 'classwork-attachments')
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

-- Read access follows the attachment rows' own RLS (teacher owner, admin,
-- students of the class). Sub-selects run with the caller's privileges.
DROP POLICY IF EXISTS "attachments: read via row" ON storage.objects;
CREATE POLICY "attachments: read via row" ON storage.objects FOR SELECT TO authenticated
  USING (
    (bucket_id = 'homework-attachments' AND EXISTS (
       SELECT 1 FROM public.homework_attachments ha WHERE ha.file_url = storage.objects.name))
    OR
    (bucket_id = 'classwork-attachments' AND EXISTS (
       SELECT 1 FROM public.classwork_attachments ca WHERE ca.file_url = storage.objects.name))
  );

-- ── C. teacher geofence check-in ──────────────────────────
CREATE OR REPLACE FUNCTION mark_teacher_present(p_lat DOUBLE PRECISION, p_lng DOUBLE PRECISION)
RETURNS JSONB AS $$
DECLARE
  v_uid      UUID := auth.uid();
  v_fence    geofence_settings%ROWTYPE;
  v_distance DOUBLE PRECISION;
  v_today    DATE := (now() AT TIME ZONE 'Asia/Kolkata')::date;
  v_marked   BOOLEAN := false;
  v_status   attendance_status;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = v_uid AND role = 'teacher' AND is_active) THEN
    RAISE EXCEPTION 'Only active teachers can check in';
  END IF;

  SELECT * INTO v_fence FROM geofence_settings ORDER BY updated_at DESC LIMIT 1;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Geofence has not been configured by the admin yet';
  END IF;

  -- Haversine distance in metres.
  v_distance := 2 * 6371000 * asin(sqrt(
      power(sin(radians(p_lat - v_fence.latitude::double precision) / 2), 2) +
      cos(radians(v_fence.latitude::double precision)) * cos(radians(p_lat)) *
      power(sin(radians(p_lng - v_fence.longitude::double precision) / 2), 2)));

  IF v_distance <= v_fence.radius_meters THEN
    INSERT INTO teacher_attendance (teacher_id, date, status, check_in_time, latitude, longitude)
    VALUES (v_uid, v_today, 'present', now(), p_lat, p_lng)
    ON CONFLICT (teacher_id, date) DO UPDATE
      SET status = 'present', check_in_time = now(),
          latitude = EXCLUDED.latitude, longitude = EXCLUDED.longitude, updated_at = now()
      WHERE teacher_attendance.status = 'absent' AND NOT teacher_attendance.is_manual_correction;
    v_marked := true;
  END IF;

  SELECT status INTO v_status FROM teacher_attendance WHERE teacher_id = v_uid AND date = v_today;

  RETURN jsonb_build_object(
    'in_range', v_marked,
    'distance_m', round(v_distance::numeric, 1),
    'radius_m', v_fence.radius_meters,
    'status', v_status
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION mark_teacher_present(DOUBLE PRECISION, DOUBLE PRECISION) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION mark_teacher_present(DOUBLE PRECISION, DOUBLE PRECISION) TO authenticated;

-- ── D. promotion ──────────────────────────────────────────
-- Guards (all enforced here, not in the app):
--   1. caller is the admin
--   2. p_confirm is exactly 'CONFIRM'
--   3. p_password matches admin_profiles.password_hash
--   4. the JWT proves an OTP login within the last 10 minutes (Supabase
--      records it in the `amr` claim after verifyOTP). Fails closed if absent.
-- Rules: SSC/CBSE 1st..9th move up one standard; 10th and inactive students
-- become 'archived'. Fee structure and teacher assignments carry over.
CREATE OR REPLACE FUNCTION promote_students(
  p_confirm    TEXT,
  p_password   TEXT,
  p_year_label TEXT,
  p_start_date DATE,
  p_end_date   DATE
) RETURNS JSONB AS $$
DECLARE
  v_uid       UUID := auth.uid();
  v_hash      TEXT;
  v_old       academic_years%ROWTYPE;
  v_new_id    UUID;
  v_standards TEXT[] := ARRAY['1st','2nd','3rd','4th','5th','6th','7th','8th','9th','10th'];
  v_promoted  INTEGER := 0;
  v_archived  INTEGER := 0;
  v_otp_ok    BOOLEAN;
  r           RECORD;
  v_next      TEXT;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = v_uid AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can promote students';
  END IF;
  IF p_confirm IS DISTINCT FROM 'CONFIRM' THEN
    RAISE EXCEPTION 'Type CONFIRM exactly to proceed';
  END IF;

  -- Supabase Auth holds the real password (same source as login).
  SELECT encrypted_password INTO v_hash FROM auth.users WHERE id = v_uid;
  IF v_hash IS NULL OR v_hash <> crypt(coalesce(p_password, ''), v_hash) THEN
    RAISE EXCEPTION 'Incorrect admin password';
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM jsonb_array_elements(coalesce(auth.jwt() -> 'amr', '[]'::jsonb)) a
    WHERE a ->> 'method' IN ('otp', 'sms')
      AND (a ->> 'timestamp')::double precision > extract(epoch FROM now()) - 600
  ) INTO v_otp_ok;
  IF NOT v_otp_ok THEN
    RAISE EXCEPTION 'OTP verification required (verify the SMS code, then retry within 10 minutes)';
  END IF;

  SELECT * INTO v_old FROM academic_years WHERE is_current FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'No current academic year'; END IF;
  IF p_end_date <= p_start_date OR p_start_date <= v_old.end_date THEN
    RAISE EXCEPTION 'New year must start after % and end after it starts', v_old.end_date;
  END IF;
  IF EXISTS (SELECT 1 FROM academic_years WHERE year_label = p_year_label) THEN
    RAISE EXCEPTION 'Academic year % already exists', p_year_label;
  END IF;

  UPDATE academic_years SET is_current = false WHERE id = v_old.id;
  INSERT INTO academic_years (year_label, start_date, end_date, is_current)
  VALUES (p_year_label, p_start_date, p_end_date, true) RETURNING id INTO v_new_id;

  FOR r IN
    SELECT se.id AS enrollment_id, se.student_id, se.board, se.standard, sp.status
    FROM student_enrollments se
    JOIN student_profiles sp ON sp.id = se.student_id
    WHERE se.academic_year_id = v_old.id AND sp.status IN ('active', 'inactive')
  LOOP
    v_next := v_standards[array_position(v_standards, r.standard::text) + 1];

    IF r.status = 'inactive' OR v_next IS NULL THEN
      UPDATE student_profiles SET status = 'archived', updated_at = now() WHERE id = r.student_id;
      v_archived := v_archived + 1;
    ELSE
      INSERT INTO student_enrollments (student_id, academic_year_id, board, standard)
      VALUES (r.student_id, v_new_id, r.board, v_next::standard_type);
      UPDATE student_profiles SET standard = v_next::standard_type, updated_at = now() WHERE id = r.student_id;
      INSERT INTO fee_structure (student_id, academic_year_id, monthly_fee)
        SELECT student_id, v_new_id, monthly_fee FROM fee_structure
        WHERE student_id = r.student_id AND academic_year_id = v_old.id
        ON CONFLICT DO NOTHING;
      v_promoted := v_promoted + 1;
    END IF;
    UPDATE student_enrollments SET is_promoted = true WHERE id = r.enrollment_id;
  END LOOP;

  INSERT INTO teacher_assignments (teacher_id, academic_year_id, board, standard, subject)
    SELECT teacher_id, v_new_id, board, standard, subject
    FROM teacher_assignments WHERE academic_year_id = v_old.id
    ON CONFLICT DO NOTHING;

  INSERT INTO promotion_history (from_academic_year_id, to_academic_year_id, promoted_by, students_promoted, otp_verified)
  VALUES (v_old.id, v_new_id, v_uid, v_promoted, true);

  INSERT INTO audit_logs (performed_by, action, entity_type, entity_id, old_value, new_value)
  VALUES (v_uid, 'students_promoted', 'academic_years', v_new_id,
          jsonb_build_object('year', v_old.year_label),
          jsonb_build_object('year', p_year_label, 'promoted', v_promoted, 'archived', v_archived));

  RETURN jsonb_build_object('promoted', v_promoted, 'archived', v_archived, 'academic_year_id', v_new_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION promote_students(TEXT, TEXT, TEXT, DATE, DATE) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION promote_students(TEXT, TEXT, TEXT, DATE, DATE) TO authenticated;

-- ── E. manual fee reminder ────────────────────────────────
CREATE OR REPLACE FUNCTION send_fee_reminder(p_student_id UUID)
RETURNS JSONB AS $$
DECLARE
  v_amount NUMERIC;
  v_months INTEGER;
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin') THEN
    RAISE EXCEPTION 'Only the admin can send fee reminders';
  END IF;

  SELECT COALESCE(SUM(mf.remaining_amount), 0), COUNT(*)
  INTO v_amount, v_months
  FROM monthly_fees mf
  JOIN academic_years ay ON ay.id = mf.academic_year_id AND ay.is_current
  WHERE mf.student_id = p_student_id
    AND mf.status IN ('pending', 'partially_paid') AND mf.remaining_amount > 0;

  IF v_months = 0 THEN
    RETURN jsonb_build_object('sent', false, 'reason', 'No pending fees for this student');
  END IF;

  INSERT INTO notifications (user_id, title, body, type, data)
  VALUES (p_student_id, 'Fee reminder',
          'You have ₹' || to_char(v_amount, 'FM99,99,99,990') || ' pending across ' || v_months
            || ' month(s). Please clear your dues.',
          'fee_reminder',
          jsonb_build_object('pending_amount', v_amount, 'months', v_months));

  RETURN jsonb_build_object('sent', true, 'pending_amount', v_amount, 'months', v_months);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION send_fee_reminder(UUID) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION send_fee_reminder(UUID) TO authenticated;

-- ── F. audit triggers ─────────────────────────────────────
-- Writes performed_by = the calling user; skipped for system jobs (no JWT).
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
    CASE WHEN TG_OP <> 'INSERT' THEN to_jsonb(OLD) END,
    CASE WHEN TG_OP <> 'DELETE' THEN to_jsonb(NEW) END
  );
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.audit_row() FROM PUBLIC, anon, authenticated;

DO $$
DECLARE
  spec TEXT[];
  specs TEXT[][] := ARRAY[
    -- trigger name, table, events, label, optional WHEN
    ['audit_fee_payments',     'fee_payments',        'INSERT OR UPDATE OR DELETE', 'fee_payment',  ''],
    ['audit_fee_structure',    'fee_structure',       'INSERT OR UPDATE',           'fee_structure', ''],
    ['audit_teacher_salary',   'teacher_salary',      'INSERT OR UPDATE',           'salary',        ''],
    ['audit_homework',         'homework',            'INSERT OR DELETE',           'homework',      ''],
    ['audit_classwork',        'classwork',           'INSERT OR DELETE',           'classwork',     ''],
    ['audit_geofence',         'geofence_settings',   'INSERT OR UPDATE',           'geofence',      ''],
    ['audit_teacher_profiles', 'teacher_profiles',    'INSERT OR UPDATE',           'teacher',       '']
  ];
BEGIN
  FOREACH spec SLICE 1 IN ARRAY specs LOOP
    EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.%I', spec[1], spec[2]);
    EXECUTE format(
      'CREATE TRIGGER %I AFTER %s ON public.%I FOR EACH ROW EXECUTE FUNCTION private.audit_row(%L)',
      spec[1], spec[3], spec[2], spec[4]);
  END LOOP;
END $$;

-- Triggers that need a WHEN clause (cannot mix OLD with INSERT).
DROP TRIGGER IF EXISTS audit_monthly_fees ON monthly_fees;
CREATE TRIGGER audit_monthly_fees AFTER UPDATE ON monthly_fees FOR EACH ROW
  WHEN (OLD.expected_amount IS DISTINCT FROM NEW.expected_amount OR OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.audit_row('monthly_fee');

DROP TRIGGER IF EXISTS audit_student_status ON student_profiles;
CREATE TRIGGER audit_student_status AFTER UPDATE ON student_profiles FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.audit_row('student_status');

DROP TRIGGER IF EXISTS audit_student_attendance_edit ON student_attendance;
CREATE TRIGGER audit_student_attendance_edit AFTER UPDATE ON student_attendance FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE FUNCTION private.audit_row('student_attendance_correction');

DROP TRIGGER IF EXISTS audit_teacher_attendance_edit ON teacher_attendance;
CREATE TRIGGER audit_teacher_attendance_edit AFTER UPDATE ON teacher_attendance FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status AND NEW.is_manual_correction)
  EXECUTE FUNCTION private.audit_row('teacher_attendance_correction');
