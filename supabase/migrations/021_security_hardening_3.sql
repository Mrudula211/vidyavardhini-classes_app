-- ============================================================
-- Vidyavardhini Classes — Third Security Hardening Pass
-- Migration: 021
-- ============================================================

-- ── 1. Active User Helper & Server-Side Ban / Inactive Enforcement ──
-- Prevents banned or deactivated users from reading or writing data
-- even if they hold an unexpired session token.
CREATE OR REPLACE FUNCTION public.is_active_user()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND is_active = true
  )
  -- students who left, were deactivated, banned or rejected
  AND NOT EXISTS (
    SELECT 1 FROM public.student_profiles
    WHERE id = auth.uid() AND status IN ('banned', 'rejected', 'inactive', 'archived')
  )
  -- teachers switched off on their profile
  AND NOT EXISTS (
    SELECT 1 FROM public.teacher_profiles
    WHERE id = auth.uid() AND is_active = false
  );
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.is_active_user() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_active_user() TO authenticated;

-- ── 2. Sync Monthly Fees on Payment UPDATE & DELETE ──────────
-- The original trigger only listened on AFTER INSERT. If an admin
-- updated or deleted a fee payment, paid_amount became out-of-sync.
CREATE OR REPLACE FUNCTION public.sync_monthly_fee_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'DELETE' THEN
    UPDATE public.monthly_fees
    SET paid_amount = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.fee_payments
      WHERE monthly_fee_id = OLD.monthly_fee_id
    ),
    updated_at = now()
    WHERE id = OLD.monthly_fee_id;
    RETURN OLD;
  ELSE
    UPDATE public.monthly_fees
    SET paid_amount = (
      SELECT COALESCE(SUM(amount), 0)
      FROM public.fee_payments
      WHERE monthly_fee_id = NEW.monthly_fee_id
    ),
    updated_at = now()
    WHERE id = NEW.monthly_fee_id;

    -- If a payment record was moved from one monthly fee to another
    IF TG_OP = 'UPDATE' AND OLD.monthly_fee_id IS DISTINCT FROM NEW.monthly_fee_id THEN
      UPDATE public.monthly_fees
      SET paid_amount = (
        SELECT COALESCE(SUM(amount), 0)
        FROM public.fee_payments
        WHERE monthly_fee_id = OLD.monthly_fee_id
      ),
      updated_at = now()
      WHERE id = OLD.monthly_fee_id;
    END IF;

    RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS sync_fee_payment ON public.fee_payments;
CREATE TRIGGER sync_fee_payment
  AFTER INSERT OR UPDATE OR DELETE ON public.fee_payments
  FOR EACH ROW EXECUTE FUNCTION public.sync_monthly_fee_on_payment();

-- ── 3. Notification Spam Protection ──────────────────────────
-- Users should only read, mark read (update), or delete their own
-- notifications. Inserting notifications must only be done by Admin
-- or trusted system triggers/functions to prevent FCM push spam.
DROP POLICY IF EXISTS "notifications: own all" ON public.notifications;
DROP POLICY IF EXISTS "notifications: own read" ON public.notifications;
DROP POLICY IF EXISTS "notifications: own update" ON public.notifications;
DROP POLICY IF EXISTS "notifications: own delete" ON public.notifications;

CREATE POLICY "notifications: own read" ON public.notifications
  FOR SELECT USING (auth.uid() = user_id AND public.is_active_user());

CREATE POLICY "notifications: own update" ON public.notifications
  FOR UPDATE USING (auth.uid() = user_id AND public.is_active_user())
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications: own delete" ON public.notifications
  FOR DELETE USING (auth.uid() = user_id AND public.is_active_user());

-- ── 4. Teacher Scope Limits on Enrollments ────────────────────
-- Teachers may only read enrollments of classes assigned to them
-- in the current academic year, rather than all classes academy-wide.
DROP POLICY IF EXISTS "student_enrollments: teacher read" ON public.student_enrollments;

CREATE POLICY "student_enrollments: teacher read" ON public.student_enrollments
  FOR SELECT USING (
    public.is_active_user() AND EXISTS (
      SELECT 1 FROM public.teacher_assignments ta
      JOIN public.academic_years ay ON ay.id = ta.academic_year_id AND ay.is_current = true
      WHERE ta.teacher_id = auth.uid()
        AND ta.academic_year_id = student_enrollments.academic_year_id
        AND ta.board = student_enrollments.board
        AND ta.standard = student_enrollments.standard
    )
  );

-- ── 5. Teacher Scope Limits on Absence Reasons ───────────────
-- Teachers may only insert absence reasons for students in their
-- assigned classes.
DROP POLICY IF EXISTS "absence_reasons: teacher/admin write" ON public.absence_reasons;

CREATE POLICY "absence_reasons: teacher/admin write" ON public.absence_reasons
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM public.users WHERE id = auth.uid() AND role = 'admin' AND is_active = true)
    OR (
      public.is_active_user() AND EXISTS (
        SELECT 1 FROM public.student_attendance sa
        JOIN public.student_enrollments se
          ON se.student_id = sa.student_id AND se.academic_year_id = sa.academic_year_id
        JOIN public.teacher_assignments ta
          ON ta.academic_year_id = se.academic_year_id
         AND ta.board = se.board
         AND ta.standard = se.standard
        WHERE sa.id = absence_reasons.attendance_id
          AND ta.teacher_id = auth.uid()
      )
    )
  );

-- ── 6. Academic-Year Scoping on Attendance Read ──────────────
-- A student sees only their own attendance of the CURRENT academic year.
-- The original policy is called "own read"; drop it too, otherwise it stays
-- and (policies are OR'ed) the new rule would change nothing.
DROP POLICY IF EXISTS "student_attendance: own read" ON public.student_attendance;
DROP POLICY IF EXISTS "student_attendance: student read" ON public.student_attendance;

CREATE POLICY "student_attendance: student read" ON public.student_attendance
  FOR SELECT USING (
    auth.uid() = student_id
    AND public.is_active_user()
    AND academic_year_id = (SELECT id FROM public.academic_years WHERE is_current = true LIMIT 1)
  );

-- ── 7. Server-side block for banned / inactive users (every table) ──
-- The checks above cover a few tables. This adds one RESTRICTIVE policy to
-- every public table with RLS: whatever the other policies allow, a signed-in
-- person must be the admin or an active user. users / student_profiles /
-- teacher_profiles are left out so the app can still read the person's own
-- status and sign a banned person out. Table owners, SECURITY DEFINER
-- functions, cron jobs and the service role are not affected.
DO $$
DECLARE
  t TEXT;
BEGIN
  FOR t IN
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND rowsecurity
      AND tablename NOT IN ('users', 'student_profiles', 'teacher_profiles')
  LOOP
    EXECUTE format('DROP POLICY IF EXISTS "live users only" ON public.%I', t);
    EXECUTE format(
      'CREATE POLICY "live users only" ON public.%I AS RESTRICTIVE FOR ALL TO authenticated '
      'USING ((SELECT public.is_admin()) OR (SELECT public.is_active_user())) '
      'WITH CHECK ((SELECT public.is_admin()) OR (SELECT public.is_active_user()))', t);
  END LOOP;
END $$;

-- Same for files (homework, classwork, chat, profile photos, backups).
DO $$
BEGIN
  DROP POLICY IF EXISTS "live users only" ON storage.objects;
  CREATE POLICY "live users only" ON storage.objects AS RESTRICTIVE FOR ALL TO authenticated
    USING ((SELECT public.is_admin()) OR (SELECT public.is_active_user()))
    WITH CHECK ((SELECT public.is_admin()) OR (SELECT public.is_active_user()));
EXCEPTION WHEN insufficient_privilege THEN
  RAISE NOTICE 'storage.objects policy not added (no permission): %', SQLERRM;
END $$;
