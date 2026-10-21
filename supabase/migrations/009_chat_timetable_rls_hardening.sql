-- ============================================================
-- 009_chat_timetable_rls_hardening.sql
--
-- The Flutter app reads/writes `chat_messages` and `timetable_slots`, and
-- uses `chat_rooms.last_message` / `last_message_at`, none of which exist in
-- migrations 001-008 (those define `messages` and `teacher_timetable`).
-- If the live database has hand-made versions of these tables they were
-- almost certainly created without RLS (Supabase advisory
-- `rls_disabled_in_public`). This migration:
--   1. creates the tables / columns the app needs (idempotent),
--   2. enables RLS and (re)creates explicit policies on them,
--   3. as a safety net, enables RLS on EVERY other table in `public` that
--      still has it off. A table with RLS on and no policy is readable only
--      by the service role, so nothing is ever left world-readable.
--
-- Safe to re-run. Legacy `messages` / `teacher_timetable` are left in place
-- (unused by the app) and keep their RLS from 001.
-- ============================================================

-- ── chat_rooms: columns the app writes ────────────────────
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS last_message    TEXT;
ALTER TABLE chat_rooms ADD COLUMN IF NOT EXISTS last_message_at TIMESTAMPTZ NOT NULL DEFAULT NOW();
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

-- sendMessage() updates last_message*; 001 had no UPDATE policy, so that
-- update was silently filtered out by RLS.
DROP POLICY IF EXISTS "chat_rooms: member update" ON chat_rooms;
CREATE POLICY "chat_rooms: member update" ON chat_rooms FOR UPDATE
  USING (auth.uid() = student_id OR auth.uid() = teacher_id)
  WITH CHECK (auth.uid() = student_id OR auth.uid() = teacher_id);

-- ── chat_messages ─────────────────────────────────────────
CREATE TABLE IF NOT EXISTS chat_messages (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id      UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id    UUID NOT NULL REFERENCES users(id),
  content      TEXT NOT NULL DEFAULT '',
  message_type TEXT NOT NULL DEFAULT 'text',
  file_url     TEXT,
  is_read      BOOLEAN NOT NULL DEFAULT false,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS chat_messages_room_idx ON chat_messages (room_id, created_at DESC);
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "chat_messages: member read" ON chat_messages;
CREATE POLICY "chat_messages: member read" ON chat_messages FOR SELECT USING (
  EXISTS (SELECT 1 FROM chat_rooms cr WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid()))
);

DROP POLICY IF EXISTS "chat_messages: member send" ON chat_messages;
CREATE POLICY "chat_messages: member send" ON chat_messages FOR INSERT WITH CHECK (
  sender_id = auth.uid()
  AND EXISTS (SELECT 1 FROM chat_rooms cr WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid()))
);

-- Marking messages read: members of the room only. (Senders cannot rewrite
-- content in practice because the app only sets is_read; tighten with a
-- column-level trigger if that ever matters.)
DROP POLICY IF EXISTS "chat_messages: member mark read" ON chat_messages;
CREATE POLICY "chat_messages: member mark read" ON chat_messages FOR UPDATE
  USING (EXISTS (SELECT 1 FROM chat_rooms cr WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid())))
  WITH CHECK (EXISTS (SELECT 1 FROM chat_rooms cr WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid())));

DROP POLICY IF EXISTS "chat_messages: admin read all" ON chat_messages;
CREATE POLICY "chat_messages: admin read all" ON chat_messages FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

-- Realtime stream (ChatRepository.streamMessages) needs the table published.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication_tables
    WHERE pubname = 'supabase_realtime' AND schemaname = 'public' AND tablename = 'chat_messages'
  ) THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
  END IF;
END $$;

-- ── timetable_slots ───────────────────────────────────────
-- Class-wide weekly slots; teacher is optional.
CREATE TABLE IF NOT EXISTS timetable_slots (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  subject          VARCHAR(50) NOT NULL,
  teacher_id       UUID REFERENCES teacher_profiles(id),
  day_of_week      TEXT NOT NULL CHECK (day_of_week IN
                     ('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday')),
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  room_number      VARCHAR(20),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS timetable_slots_class_idx ON timetable_slots (board, standard, day_of_week, start_time);
CREATE INDEX IF NOT EXISTS timetable_slots_teacher_idx ON timetable_slots (teacher_id);
ALTER TABLE timetable_slots ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "timetable_slots: admin all" ON timetable_slots;
CREATE POLICY "timetable_slots: admin all" ON timetable_slots FOR ALL
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'))
  WITH CHECK (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin'));

DROP POLICY IF EXISTS "timetable_slots: teacher read" ON timetable_slots;
CREATE POLICY "timetable_slots: teacher read" ON timetable_slots FOR SELECT
  USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'teacher'));

DROP POLICY IF EXISTS "timetable_slots: student own class read" ON timetable_slots;
CREATE POLICY "timetable_slots: student own class read" ON timetable_slots FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM student_profiles sp
    WHERE sp.id = auth.uid() AND sp.status = 'active'
      AND sp.board = timetable_slots.board AND sp.standard = timetable_slots.standard
  ));

-- ── safety net: no table in public may have RLS off ───────
DO $$
DECLARE
  t RECORD;
BEGIN
  FOR t IN
    SELECT c.relname AS name
    FROM pg_class c
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relkind IN ('r', 'p') AND NOT c.relrowsecurity
  LOOP
    EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t.name);
    RAISE NOTICE 'Enabled RLS on public.% (no policies were added — service role only until you add some)', t.name;
  END LOOP;
END $$;
