-- ============================================================
-- 008_automation.sql
-- Server-side automation: scheduled jobs (pg_cron), push delivery and
-- backups (pg_net → Edge Functions).
--
--   • monthly-fee-generate  1st of month  → generate_monthly_fees_for_month()
--   • monthly-fee-reminder  10th of month → queue_fee_reminders()
--   • daily-backup          every day     → backup_logs row → backup-trigger
--   • notifications INSERT                → send-push Edge Function (FCM)
--   • backup_logs  INSERT (pending)       → backup-trigger Edge Function
--
-- Edge Function calls read two Supabase Vault secrets. Until both exist the
-- HTTP calls are skipped (rows are still written), so this migration is safe
-- to apply before the functions are deployed:
--   project_url        e.g. https://<ref>.supabase.co
--   automation_secret  random string; must equal the AUTOMATION_SECRET
--                      Edge Function secret
--
-- pg_cron runs in UTC. Asia/Kolkata is UTC+05:30.
-- ============================================================

CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pg_net;

CREATE SCHEMA IF NOT EXISTS private;
REVOKE ALL ON SCHEMA private FROM PUBLIC, anon, authenticated;

-- ── call an Edge Function asynchronously ──────────────────
CREATE OR REPLACE FUNCTION private.call_edge_function(p_name TEXT, p_body JSONB)
RETURNS VOID AS $$
DECLARE
  v_url    TEXT;
  v_secret TEXT;
BEGIN
  SELECT decrypted_secret INTO v_url
  FROM vault.decrypted_secrets WHERE name = 'project_url';
  SELECT decrypted_secret INTO v_secret
  FROM vault.decrypted_secrets WHERE name = 'automation_secret';

  IF v_url IS NULL OR v_secret IS NULL THEN
    RAISE LOG 'call_edge_function(%): vault secrets not configured, skipped', p_name;
    RETURN;
  END IF;

  PERFORM net.http_post(
    url     := rtrim(v_url, '/') || '/functions/v1/' || p_name,
    body    := p_body,
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'x-automation-secret', v_secret
    ),
    timeout_milliseconds := 10000
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public, extensions;

REVOKE ALL ON FUNCTION private.call_edge_function(TEXT, JSONB) FROM PUBLIC, anon, authenticated;

-- ── push: one HTTP call per INSERT statement ──────────────
CREATE OR REPLACE FUNCTION private.dispatch_notification_push()
RETURNS TRIGGER AS $$
DECLARE
  v_ids JSONB;
BEGIN
  SELECT jsonb_agg(id) INTO v_ids FROM new_rows;
  IF v_ids IS NOT NULL THEN
    PERFORM private.call_edge_function('send-push', jsonb_build_object('notification_ids', v_ids));
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS notifications_push_dispatch ON notifications;
CREATE TRIGGER notifications_push_dispatch
  AFTER INSERT ON notifications
  REFERENCING NEW TABLE AS new_rows
  FOR EACH STATEMENT EXECUTE FUNCTION private.dispatch_notification_push();

-- ── fee reminder (business rule 9) ────────────────────────
-- One notification per active student with any pending / partially paid
-- month in the current academic year. Returns the number of students queued.
CREATE OR REPLACE FUNCTION queue_fee_reminders()
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
BEGIN
  INSERT INTO notifications (user_id, title, body, type, data)
  SELECT
    mf.student_id,
    'Fee reminder',
    'You have ₹' || to_char(SUM(mf.remaining_amount), 'FM99,99,99,990')
      || ' pending across ' || COUNT(*) || ' month(s). Please clear your dues.',
    'fee_reminder',
    jsonb_build_object('pending_amount', SUM(mf.remaining_amount), 'months', COUNT(*))
  FROM monthly_fees mf
  JOIN academic_years ay ON ay.id = mf.academic_year_id AND ay.is_current
  JOIN student_profiles sp ON sp.id = mf.student_id AND sp.status = 'active'
  WHERE mf.status IN ('pending', 'partially_paid')
    AND mf.remaining_amount > 0
  GROUP BY mf.student_id;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION queue_fee_reminders() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION generate_monthly_fees_for_month(SMALLINT, SMALLINT) FROM PUBLIC, anon, authenticated;

-- ── backups ───────────────────────────────────────────────
INSERT INTO storage.buckets (id, name, public)
VALUES ('backups', 'backups', false)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "backups: admin read" ON storage.objects;
CREATE POLICY "backups: admin read" ON storage.objects FOR SELECT
  USING (bucket_id = 'backups' AND EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

CREATE OR REPLACE FUNCTION private.dispatch_backup()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'pending' THEN
    PERFORM private.call_edge_function('backup-trigger', jsonb_build_object('backup_id', NEW.id));
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS backup_logs_dispatch ON backup_logs;
CREATE TRIGGER backup_logs_dispatch
  AFTER INSERT ON backup_logs
  FOR EACH ROW EXECUTE FUNCTION private.dispatch_backup();

-- Scheduled backups are attributed to the (single) admin account.
CREATE OR REPLACE FUNCTION private.queue_scheduled_backup()
RETURNS VOID AS $$
  INSERT INTO backup_logs (initiated_by, status)
  SELECT id, 'pending' FROM users WHERE role = 'admin' LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION private.queue_scheduled_backup() FROM PUBLIC, anon, authenticated;

-- ── schedules (cron.schedule upserts by job name) ─────────
-- 00:01 UTC on the 1st = 05:31 IST
SELECT cron.schedule(
  'monthly-fee-generate',
  '1 0 1 * *',
  $$SELECT public.generate_monthly_fees_for_month(
      EXTRACT(MONTH FROM (now() AT TIME ZONE 'Asia/Kolkata'))::SMALLINT,
      EXTRACT(YEAR  FROM (now() AT TIME ZONE 'Asia/Kolkata'))::SMALLINT)$$
);

-- 03:30 UTC on the 10th = 09:00 IST
SELECT cron.schedule('monthly-fee-reminder', '30 3 10 * *', $$SELECT public.queue_fee_reminders()$$);

-- 20:30 UTC daily = 02:00 IST
SELECT cron.schedule('daily-backup', '30 20 * * *', $$SELECT private.queue_scheduled_backup()$$);
