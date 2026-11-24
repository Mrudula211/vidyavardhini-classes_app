-- 019: make the announcements table match what the app sends.
--
-- The app has always written `target_type` (all | students | teachers |
-- specific_class) and priorities general | urgent | emergency, but the table
-- only had `type` (general | staff | emergency) and a priority enum of
-- normal | high | urgent. Publishing failed with
--   "Could not find the 'target_type' column of 'announcements'".
-- Safe to re-run.

-- 1. Who the announcement is for.
ALTER TABLE public.announcements
  ADD COLUMN IF NOT EXISTS target_type text NOT NULL DEFAULT 'all';

ALTER TABLE public.announcements
  DROP CONSTRAINT IF EXISTS announcements_target_type_check;
ALTER TABLE public.announcements
  ADD CONSTRAINT announcements_target_type_check
  CHECK (target_type IN ('all', 'students', 'teachers', 'specific_class'));

-- Old rows written for staff only stay visible to staff only.
UPDATE public.announcements SET target_type = 'teachers' WHERE type = 'staff';

-- 2. Priority: the app's three levels.
DO $$
BEGIN
  IF (SELECT data_type FROM information_schema.columns
      WHERE table_schema = 'public' AND table_name = 'announcements'
        AND column_name = 'priority') = 'USER-DEFINED' THEN
    ALTER TABLE public.announcements ALTER COLUMN priority DROP DEFAULT;
    ALTER TABLE public.announcements ALTER COLUMN priority TYPE text
      USING (CASE priority::text
               WHEN 'normal' THEN 'general'
               WHEN 'high' THEN 'urgent'
               ELSE priority::text
             END);
  END IF;
END $$;

ALTER TABLE public.announcements ALTER COLUMN priority SET DEFAULT 'general';
ALTER TABLE public.announcements
  DROP CONSTRAINT IF EXISTS announcements_priority_check;
ALTER TABLE public.announcements
  ADD CONSTRAINT announcements_priority_check
  CHECK (priority IN ('general', 'urgent', 'emergency'));

-- A class announcement needs a class.
ALTER TABLE public.announcements
  DROP CONSTRAINT IF EXISTS announcements_class_target_check;
ALTER TABLE public.announcements
  ADD CONSTRAINT announcements_class_target_check
  CHECK (target_type <> 'specific_class'
         OR (target_board IS NOT NULL AND target_standard IS NOT NULL));

-- 3. Read access follows the audience (the admin has the write-all policy).
DROP POLICY IF EXISTS "announcements: general read" ON public.announcements;
CREATE POLICY "announcements: general read" ON public.announcements
  FOR SELECT TO authenticated
  USING (
    is_active = true
    AND (expires_at IS NULL OR expires_at > now())
    AND (
      target_type = 'all'
      OR (target_type = 'teachers' AND EXISTS (
            SELECT 1 FROM public.users u
            WHERE u.id = auth.uid() AND u.role = 'teacher'))
      OR (target_type = 'students' AND EXISTS (
            SELECT 1 FROM public.student_profiles sp
            WHERE sp.id = auth.uid()))
      OR (target_type = 'specific_class' AND EXISTS (
            SELECT 1 FROM public.student_profiles sp
            WHERE sp.id = auth.uid()
              AND sp.board = announcements.target_board
              AND sp.standard = announcements.target_standard))
    )
  );

-- Make PostgREST pick up the new column straight away.
NOTIFY pgrst, 'reload schema';
