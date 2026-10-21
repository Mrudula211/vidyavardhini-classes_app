# DATABASE_SCHEMA.md — Vidyavardhini Classes

All tables live in the `public` schema on Supabase PostgreSQL.  
RLS is **enabled on every table**. Service role is never used from Flutter.

---

## 1. Enums

```sql
-- Run once during migration
CREATE TYPE user_role AS ENUM ('admin', 'teacher', 'student');
CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');
CREATE TYPE board_type AS ENUM ('SSC', 'CBSE');
CREATE TYPE standard_type AS ENUM ('1st','2nd','3rd','4th','5th','6th','7th','8th','9th','10th');
CREATE TYPE student_status AS ENUM ('pending','active','inactive','archived','banned','rejected');
CREATE TYPE attendance_status AS ENUM ('present','absent','holiday','leave');
CREATE TYPE absence_reason_type AS ENUM ('sick','family_function','travel','personal','other');
CREATE TYPE fee_status AS ENUM ('pending','partially_paid','paid','waived');
CREATE TYPE payment_method AS ENUM ('cash','upi','bank_transfer','cheque');
CREATE TYPE salary_status AS ENUM ('pending','paid');
CREATE TYPE announcement_type AS ENUM ('general','staff','emergency');
CREATE TYPE announcement_priority AS ENUM ('normal','high','urgent');
CREATE TYPE file_type AS ENUM ('image','pdf','text','video');
CREATE TYPE backup_status AS ENUM ('pending','success','failed');
```

---

## 2. Core Tables

### 2.1 users

```sql
CREATE TABLE users (
  id          UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone       VARCHAR(15) UNIQUE NOT NULL,
  role        user_role NOT NULL,
  fcm_token   TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT true,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Users can read their own record
CREATE POLICY "users: own read" ON users
  FOR SELECT USING (auth.uid() = id);

-- Admin can read all users
CREATE POLICY "users: admin read all" ON users
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

-- Users can update their own FCM token
CREATE POLICY "users: update own fcm" ON users
  FOR UPDATE USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

-- New users can insert their own row (post OTP verification)
CREATE POLICY "users: insert own" ON users
  FOR INSERT WITH CHECK (auth.uid() = id);
```

---

### 2.2 admin_profiles

```sql
CREATE TABLE admin_profiles (
  id                UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  full_name         VARCHAR(100) NOT NULL,
  email             VARCHAR(255),
  access_code_hash  VARCHAR(255) NOT NULL,
  password_hash     VARCHAR(255) NOT NULL,
  profile_photo_url TEXT,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE admin_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "admin_profiles: admin only" ON admin_profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 2.3 teacher_profiles

```sql
CREATE TABLE teacher_profiles (
  id                UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  teacher_id        VARCHAR(10) UNIQUE NOT NULL,   -- TCH0001
  full_name         VARCHAR(100) NOT NULL,
  gender            gender_type,
  dob               DATE,
  email             VARCHAR(255),
  joining_date      DATE,
  profile_photo_url TEXT,
  monthly_salary    NUMERIC(10,2) NOT NULL DEFAULT 0,
  access_code_hash  VARCHAR(255) NOT NULL,
  is_active         BOOLEAN NOT NULL DEFAULT true,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sequence for teacher IDs
CREATE SEQUENCE teacher_id_seq START 1;

ALTER TABLE teacher_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_profiles: own read" ON teacher_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "teacher_profiles: admin all" ON teacher_profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 2.4 student_profiles

```sql
CREATE TABLE student_profiles (
  id                UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  student_id        VARCHAR(10) UNIQUE,             -- STU0001 (set on approval)
  full_name         VARCHAR(100) NOT NULL,
  gender            gender_type NOT NULL,
  dob               DATE NOT NULL,
  parent_name       VARCHAR(100) NOT NULL,
  parent_phone      VARCHAR(15) NOT NULL,
  whatsapp_number   VARCHAR(15) NOT NULL,
  email             VARCHAR(255),
  school_name       VARCHAR(150) NOT NULL,
  board             board_type NOT NULL,
  standard          standard_type NOT NULL,
  profile_photo_url TEXT,
  status            student_status NOT NULL DEFAULT 'pending',
  rejection_reason  TEXT,
  approved_by       UUID REFERENCES users(id),
  approved_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Sequence for student IDs — never reuse
CREATE SEQUENCE student_id_seq START 1;

ALTER TABLE student_profiles ENABLE ROW LEVEL SECURITY;

-- Students read own profile
CREATE POLICY "student_profiles: own read" ON student_profiles
  FOR SELECT USING (auth.uid() = id);

-- Students insert own profile (registration)
CREATE POLICY "student_profiles: own insert" ON student_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

-- Teachers read students in their assigned classes (current year)
CREATE POLICY "student_profiles: teacher read assigned" ON student_profiles
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM teacher_assignments ta
      JOIN academic_years ay ON ay.id = ta.academic_year_id AND ay.is_current = true
      WHERE ta.teacher_id = auth.uid()
        AND ta.board = student_profiles.board
        AND ta.standard = student_profiles.standard
    )
  );

-- Admin full access
CREATE POLICY "student_profiles: admin all" ON student_profiles
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 3. Academic Year Tables

### 3.1 academic_years

```sql
CREATE TABLE academic_years (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  year_label  VARCHAR(10) NOT NULL UNIQUE,   -- '2026-27'
  start_date  DATE NOT NULL,
  end_date    DATE NOT NULL,
  is_current  BOOLEAN NOT NULL DEFAULT false,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one year can be current
CREATE UNIQUE INDEX academic_years_one_current ON academic_years (is_current)
  WHERE is_current = true;

ALTER TABLE academic_years ENABLE ROW LEVEL SECURITY;

CREATE POLICY "academic_years: all read" ON academic_years
  FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "academic_years: admin write" ON academic_years
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 3.2 student_enrollments

```sql
CREATE TABLE student_enrollments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID NOT NULL REFERENCES student_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  is_promoted      BOOLEAN NOT NULL DEFAULT false,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year_id)
);

ALTER TABLE student_enrollments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_enrollments: own read" ON student_enrollments
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "student_enrollments: admin all" ON student_enrollments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "student_enrollments: teacher read" ON student_enrollments
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'teacher')
  );
```

---

### 3.3 teacher_assignments

```sql
CREATE TABLE teacher_assignments (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id       UUID NOT NULL REFERENCES teacher_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  subject          VARCHAR(50) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, academic_year_id, board, standard, subject)
);

ALTER TABLE teacher_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_assignments: own read" ON teacher_assignments
  FOR SELECT USING (auth.uid() = teacher_id);

CREATE POLICY "teacher_assignments: admin all" ON teacher_assignments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 4. Attendance Tables

### 4.1 student_attendance

```sql
CREATE TABLE student_attendance (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID NOT NULL REFERENCES student_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  date             DATE NOT NULL,
  status           attendance_status NOT NULL,
  marked_by        UUID NOT NULL REFERENCES users(id),   -- teacher who marked
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, date)
);

CREATE INDEX student_attendance_student_date ON student_attendance (student_id, date DESC);
CREATE INDEX student_attendance_year ON student_attendance (academic_year_id, date DESC);

ALTER TABLE student_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "student_attendance: own read" ON student_attendance
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "student_attendance: teacher write" ON student_attendance
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM teacher_assignments ta
      JOIN academic_years ay ON ay.id = ta.academic_year_id AND ay.is_current = true
      JOIN student_profiles sp ON sp.id = student_id
        AND sp.board = ta.board AND sp.standard = ta.standard
      WHERE ta.teacher_id = auth.uid()
    )
  );

CREATE POLICY "student_attendance: admin all" ON student_attendance
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 4.2 absence_reasons

```sql
CREATE TABLE absence_reasons (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  attendance_id UUID NOT NULL REFERENCES student_attendance(id) ON DELETE CASCADE,
  reason        absence_reason_type NOT NULL,
  description   TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE absence_reasons ENABLE ROW LEVEL SECURITY;

CREATE POLICY "absence_reasons: student own read" ON absence_reasons
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM student_attendance sa
      WHERE sa.id = attendance_id AND sa.student_id = auth.uid()
    )
  );

CREATE POLICY "absence_reasons: teacher/admin write" ON absence_reasons
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher','admin'))
  );

CREATE POLICY "absence_reasons: admin all" ON absence_reasons
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 4.3 teacher_attendance

```sql
CREATE TABLE teacher_attendance (
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id           UUID NOT NULL REFERENCES teacher_profiles(id),
  date                 DATE NOT NULL,
  status               attendance_status NOT NULL DEFAULT 'absent',
  check_in_time        TIMESTAMPTZ,
  latitude             NUMERIC(10,7),
  longitude            NUMERIC(10,7),
  is_manual_correction BOOLEAN NOT NULL DEFAULT false,
  corrected_by         UUID REFERENCES users(id),
  correction_reason    TEXT,
  created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, date)
);

CREATE INDEX teacher_attendance_teacher_date ON teacher_attendance (teacher_id, date DESC);

ALTER TABLE teacher_attendance ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_attendance: own read" ON teacher_attendance
  FOR SELECT USING (auth.uid() = teacher_id);

CREATE POLICY "teacher_attendance: self insert" ON teacher_attendance
  FOR INSERT WITH CHECK (auth.uid() = teacher_id);

CREATE POLICY "teacher_attendance: admin all" ON teacher_attendance
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 5. Content Tables

### 5.1 homework

```sql
CREATE TABLE homework (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id       UUID NOT NULL REFERENCES teacher_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  subject          VARCHAR(50) NOT NULL,
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  due_date         DATE NOT NULL,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX homework_class ON homework (academic_year_id, board, standard, created_at DESC);

ALTER TABLE homework ENABLE ROW LEVEL SECURITY;

CREATE POLICY "homework: teacher write own class" ON homework
  FOR INSERT WITH CHECK (
    auth.uid() = teacher_id AND
    EXISTS (
      SELECT 1 FROM teacher_assignments ta
      JOIN academic_years ay ON ay.id = ta.academic_year_id AND ay.is_current = true
      WHERE ta.teacher_id = auth.uid() AND ta.board = board AND ta.standard = standard
    )
  );

CREATE POLICY "homework: teacher read own" ON homework
  FOR SELECT USING (auth.uid() = teacher_id);

CREATE POLICY "homework: student read enrolled class" ON homework
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM student_enrollments se
      JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
      WHERE se.student_id = auth.uid() AND se.board = board AND se.standard = standard
    )
  );

CREATE POLICY "homework: admin all" ON homework
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 5.2 homework_attachments

```sql
CREATE TABLE homework_attachments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  homework_id UUID NOT NULL REFERENCES homework(id) ON DELETE CASCADE,
  file_url    TEXT NOT NULL,
  file_type   file_type NOT NULL,
  file_name   VARCHAR(255) NOT NULL,
  file_size   INTEGER,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE homework_attachments ENABLE ROW LEVEL SECURITY;

-- Same visibility as parent homework (join)
CREATE POLICY "homework_attachments: read with homework" ON homework_attachments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM homework h
      WHERE h.id = homework_id AND (
        h.teacher_id = auth.uid() OR
        EXISTS (
          SELECT 1 FROM student_enrollments se
          JOIN academic_years ay ON ay.id = se.academic_year_id AND ay.is_current = true
          WHERE se.student_id = auth.uid() AND se.board = h.board AND se.standard = h.standard
        ) OR
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
      )
    )
  );

CREATE POLICY "homework_attachments: teacher insert" ON homework_attachments
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM homework h WHERE h.id = homework_id AND h.teacher_id = auth.uid()
    )
  );
```

---

### 5.3 classwork / classwork_attachments

```sql
-- Same structure as homework / homework_attachments minus due_date
CREATE TABLE classwork (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id       UUID NOT NULL REFERENCES teacher_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  subject          VARCHAR(50) NOT NULL,
  title            VARCHAR(200) NOT NULL,
  description      TEXT,
  is_active        BOOLEAN NOT NULL DEFAULT true,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE classwork_attachments (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  classwork_id UUID NOT NULL REFERENCES classwork(id) ON DELETE CASCADE,
  file_url     TEXT NOT NULL,
  file_type    file_type NOT NULL,
  file_name    VARCHAR(255) NOT NULL,
  file_size    INTEGER,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- RLS mirrors homework tables (omitted for brevity — same pattern)
ALTER TABLE classwork ENABLE ROW LEVEL SECURITY;
ALTER TABLE classwork_attachments ENABLE ROW LEVEL SECURITY;
```

---

## 6. Communication Tables

### 6.1 chat_rooms

```sql
CREATE TABLE chat_rooms (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id UUID NOT NULL REFERENCES student_profiles(id),
  teacher_id UUID NOT NULL REFERENCES teacher_profiles(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, teacher_id)
);

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;

CREATE POLICY "chat_rooms: member read" ON chat_rooms
  FOR SELECT USING (auth.uid() = student_id OR auth.uid() = teacher_id);

CREATE POLICY "chat_rooms: student create" ON chat_rooms
  FOR INSERT WITH CHECK (auth.uid() = student_id);

CREATE POLICY "chat_rooms: admin read all" ON chat_rooms
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 6.2 messages

```sql
CREATE TABLE messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  room_id    UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES users(id),
  content    TEXT,
  file_url   TEXT,
  file_type  file_type,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX messages_room_time ON messages (room_id, created_at DESC);

ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "messages: room member read" ON messages
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM chat_rooms cr
      WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid())
    )
  );

CREATE POLICY "messages: room member insert" ON messages
  FOR INSERT WITH CHECK (
    auth.uid() = sender_id AND
    EXISTS (
      SELECT 1 FROM chat_rooms cr
      WHERE cr.id = room_id AND (cr.student_id = auth.uid() OR cr.teacher_id = auth.uid())
    )
  );

CREATE POLICY "messages: admin read all" ON messages
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 6.3 announcements

```sql
CREATE TABLE announcements (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  created_by       UUID NOT NULL REFERENCES users(id),
  title            VARCHAR(200) NOT NULL,
  content          TEXT NOT NULL,
  type             announcement_type NOT NULL DEFAULT 'general',
  priority         announcement_priority NOT NULL DEFAULT 'normal',
  target_board     board_type,              -- NULL means all boards
  target_standard  standard_type,           -- NULL means all standards
  is_active        BOOLEAN NOT NULL DEFAULT true,
  expires_at       TIMESTAMPTZ,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE announcement_attachments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  file_url        TEXT NOT NULL,
  file_type       file_type NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE announcement_seen (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID NOT NULL REFERENCES announcements(id) ON DELETE CASCADE,
  user_id         UUID NOT NULL REFERENCES users(id),
  seen_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (announcement_id, user_id)
);

ALTER TABLE announcements ENABLE ROW LEVEL SECURITY;
ALTER TABLE announcement_seen ENABLE ROW LEVEL SECURITY;

-- General announcements: all authenticated users
-- Staff announcements: teachers + admin only
CREATE POLICY "announcements: general all read" ON announcements
  FOR SELECT USING (
    is_active = true AND (
      type = 'general' OR type = 'emergency' OR
      (type = 'staff' AND EXISTS (
        SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher','admin')
      ))
    )
  );

CREATE POLICY "announcements: admin write" ON announcements
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "announcement_seen: own insert read" ON announcement_seen
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "announcement_seen: admin read all" ON announcement_seen
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 7. Finance Tables

### 7.1 fee_structure

```sql
CREATE TABLE fee_structure (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID NOT NULL REFERENCES student_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  monthly_fee      NUMERIC(10,2) NOT NULL DEFAULT 0,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, academic_year_id)
);

ALTER TABLE fee_structure ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fee_structure: student own read" ON fee_structure
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "fee_structure: admin all" ON fee_structure
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 7.2 monthly_fees

```sql
CREATE TABLE monthly_fees (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  student_id       UUID NOT NULL REFERENCES student_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  month            SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year             SMALLINT NOT NULL,
  expected_amount  NUMERIC(10,2) NOT NULL,
  paid_amount      NUMERIC(10,2) NOT NULL DEFAULT 0,
  remaining_amount NUMERIC(10,2) GENERATED ALWAYS AS (expected_amount - paid_amount) STORED,
  status           fee_status NOT NULL DEFAULT 'pending',
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (student_id, month, year)
);

CREATE INDEX monthly_fees_student ON monthly_fees (student_id, year DESC, month DESC);
CREATE INDEX monthly_fees_status ON monthly_fees (status, year, month);

ALTER TABLE monthly_fees ENABLE ROW LEVEL SECURITY;

CREATE POLICY "monthly_fees: student own read" ON monthly_fees
  FOR SELECT USING (auth.uid() = student_id);

CREATE POLICY "monthly_fees: admin all" ON monthly_fees
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 7.3 fee_payments

```sql
CREATE TABLE fee_payments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  monthly_fee_id  UUID NOT NULL REFERENCES monthly_fees(id),
  amount          NUMERIC(10,2) NOT NULL CHECK (amount > 0),
  payment_method  payment_method NOT NULL,
  payment_date    DATE NOT NULL,
  reference_number VARCHAR(100),
  collected_by    UUID NOT NULL REFERENCES users(id),
  notes           TEXT,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE fee_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "fee_payments: student own read" ON fee_payments
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM monthly_fees mf WHERE mf.id = monthly_fee_id AND mf.student_id = auth.uid()
    )
  );

CREATE POLICY "fee_payments: admin all" ON fee_payments
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 7.4 teacher_salary

```sql
CREATE TABLE teacher_salary (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id     UUID NOT NULL REFERENCES teacher_profiles(id),
  month          SMALLINT NOT NULL CHECK (month BETWEEN 1 AND 12),
  year           SMALLINT NOT NULL,
  monthly_salary NUMERIC(10,2) NOT NULL,
  working_days   SMALLINT NOT NULL,
  present_days   SMALLINT NOT NULL DEFAULT 0,
  absent_days    SMALLINT GENERATED ALWAYS AS (working_days - present_days) STORED,
  daily_salary   NUMERIC(10,2) GENERATED ALWAYS AS (
    CASE WHEN working_days > 0 THEN monthly_salary / working_days ELSE 0 END
  ) STORED,
  earned_salary  NUMERIC(10,2) GENERATED ALWAYS AS (
    CASE WHEN working_days > 0 THEN (monthly_salary / working_days) * present_days ELSE 0 END
  ) STORED,
  status         salary_status NOT NULL DEFAULT 'pending',
  payment_date   DATE,
  payment_method VARCHAR(50),
  notes          TEXT,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (teacher_id, month, year)
);

ALTER TABLE teacher_salary ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_salary: own read" ON teacher_salary
  FOR SELECT USING (auth.uid() = teacher_id);

CREATE POLICY "teacher_salary: admin all" ON teacher_salary
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 8. System Tables

### 8.1 geofence_settings

```sql
CREATE TABLE geofence_settings (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  latitude       NUMERIC(10,7) NOT NULL,
  longitude      NUMERIC(10,7) NOT NULL,
  radius_meters  INTEGER NOT NULL DEFAULT 100,
  updated_by     UUID NOT NULL REFERENCES users(id),
  updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE geofence_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "geofence_settings: teacher read" ON geofence_settings
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('teacher','admin'))
  );

CREATE POLICY "geofence_settings: admin write" ON geofence_settings
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 8.2 teacher_timetable

```sql
CREATE TABLE teacher_timetable (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  teacher_id       UUID NOT NULL REFERENCES teacher_profiles(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  day_of_week      SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),  -- 0=Sun
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  board            board_type NOT NULL,
  standard         standard_type NOT NULL,
  subject          VARCHAR(50) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE teacher_timetable ENABLE ROW LEVEL SECURITY;

CREATE POLICY "teacher_timetable: own read" ON teacher_timetable
  FOR SELECT USING (auth.uid() = teacher_id);

CREATE POLICY "teacher_timetable: admin all" ON teacher_timetable
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 8.3 audit_logs

```sql
CREATE TABLE audit_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  performed_by UUID NOT NULL REFERENCES users(id),
  action       VARCHAR(100) NOT NULL,
  entity_type  VARCHAR(50),
  entity_id    UUID,
  old_value    JSONB,
  new_value    JSONB,
  ip_address   VARCHAR(45),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX audit_logs_time ON audit_logs (created_at DESC);
CREATE INDEX audit_logs_entity ON audit_logs (entity_type, entity_id);

ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- INSERT only — no update or delete
CREATE POLICY "audit_logs: admin read" ON audit_logs
  FOR SELECT USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );

CREATE POLICY "audit_logs: insert authenticated" ON audit_logs
  FOR INSERT WITH CHECK (auth.uid() = performed_by);
```

---

### 8.4 notifications

```sql
CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id),
  title      VARCHAR(200) NOT NULL,
  body       TEXT NOT NULL,
  type       VARCHAR(50) NOT NULL,
  data       JSONB,
  is_read    BOOLEAN NOT NULL DEFAULT false,
  sent_at    TIMESTAMPTZ,
  read_at    TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX notifications_user ON notifications (user_id, created_at DESC);

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "notifications: own read/update" ON notifications
  FOR ALL USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "notifications: admin insert all" ON notifications
  FOR INSERT WITH CHECK (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 8.5 promotion_history

```sql
CREATE TABLE promotion_history (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  to_academic_year_id   UUID NOT NULL REFERENCES academic_years(id),
  promoted_by           UUID NOT NULL REFERENCES users(id),
  students_promoted     INTEGER NOT NULL DEFAULT 0,
  otp_verified          BOOLEAN NOT NULL DEFAULT false,
  promoted_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE promotion_history ENABLE ROW LEVEL SECURITY;

CREATE POLICY "promotion_history: admin all" ON promotion_history
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

### 8.6 backup_logs

```sql
CREATE TABLE backup_logs (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  initiated_by UUID NOT NULL REFERENCES users(id),
  status       backup_status NOT NULL DEFAULT 'pending',
  storage_path TEXT,
  size_bytes   BIGINT,
  error_msg    TEXT,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at TIMESTAMPTZ
);

ALTER TABLE backup_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY "backup_logs: admin all" ON backup_logs
  FOR ALL USING (
    EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
  );
```

---

## 9. Key Functions & Triggers

### 9.1 Next Student ID

```sql
CREATE OR REPLACE FUNCTION next_student_id() RETURNS VARCHAR AS $$
DECLARE
  next_num INTEGER;
BEGIN
  next_num := nextval('student_id_seq');
  RETURN 'STU' || LPAD(next_num::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;
```

### 9.2 Fee Status Auto-Update

```sql
CREATE OR REPLACE FUNCTION update_fee_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.paid_amount >= NEW.expected_amount THEN
    NEW.status := 'paid';
  ELSIF NEW.paid_amount > 0 THEN
    NEW.status := 'partially_paid';
  ELSE
    NEW.status := 'pending';
  END IF;
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fee_status_trigger
  BEFORE INSERT OR UPDATE ON monthly_fees
  FOR EACH ROW EXECUTE FUNCTION update_fee_status();
```

### 9.3 Update paid_amount on fee_payments Insert

```sql
CREATE OR REPLACE FUNCTION sync_monthly_fee_on_payment()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE monthly_fees
  SET paid_amount = (
    SELECT COALESCE(SUM(amount), 0)
    FROM fee_payments
    WHERE monthly_fee_id = NEW.monthly_fee_id
  )
  WHERE id = NEW.monthly_fee_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_fee_payment
  AFTER INSERT ON fee_payments
  FOR EACH ROW EXECUTE FUNCTION sync_monthly_fee_on_payment();
```

### 9.4 Auto-Update updated_at

```sql
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to all tables with updated_at column
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION update_updated_at();
-- (repeat for all relevant tables)
```

---

### 9.5 Automation (migration 008)

- Extensions: `pg_cron`, `pg_net`. Schema `private` (no API access) holds `call_edge_function`, `dispatch_notification_push`, `dispatch_backup`, `queue_scheduled_backup`.
- Trigger `notifications_push_dispatch` (AFTER INSERT, statement-level) → `send-push`.
- Trigger `backup_logs_dispatch` (AFTER INSERT, row-level) → `backup-trigger` when `status = 'pending'`.
- `queue_fee_reminders()` — one `fee_reminder` notification per active student with pending/partial months in the current year. Execute revoked from API roles.
- `generate_monthly_fees_for_month` — execute revoked from API roles (cron only).
- Storage bucket `backups` (private); admin-only SELECT policy on `storage.objects`.
- Cron jobs: `monthly-fee-generate`, `monthly-fee-reminder`, `daily-backup`.
- Requires Vault secrets `project_url` and `automation_secret`; without them HTTP calls are skipped.

---

### 9.6 Chat/timetable alignment & RLS hardening (migration 009)

- Adds `chat_messages` (app's message table; `message_type` text), `timetable_slots` (class-wide weekly slots, text weekdays, optional teacher, `room_number`), and `chat_rooms.last_message` / `last_message_at`. Legacy `messages` / `teacher_timetable` from 001 are no longer used by the app.
- Policies: members read/send/mark-read `chat_messages`; members update `chat_rooms`; admin all on `timetable_slots`, teachers read all, students read their own board+standard.
- `chat_messages` added to the `supabase_realtime` publication.
- Safety net: enables RLS on every `public` table that has it off (no policy = service role only).

---

### 9.7 Attachments, geofence, promotion, audit (migration 010)

- Fixes `homework: student read` / `classwork: student read` (qualified columns; active students only).
- Buckets `homework-attachments`, `classwork-attachments` (private, 20 MB) + `storage.objects` policies (teacher upload/delete in own folder; read via attachment-row RLS).
- `mark_teacher_present(lat, lng)` - teacher geofence check-in. `promote_students(confirm, password, year_label, start, end)` - admin only; requires `CONFIRM`, password, and OTP in JWT `amr` within 10 min; promotes 1st-9th, archives 10th/inactive, copies fee structure + teacher assignments, writes `promotion_history` + audit. `send_fee_reminder(student_id)` - admin only.
- `private.audit_row()` + triggers writing `audit_logs` (performed_by = caller; skipped for cron).

---

### 9.8 Security hardening & auth fixes (migration 011)

- `users`: insert limited to `role = 'student'`; unique index `users_single_admin`; trigger `users_guard_update` blocks role changes and non-admin phone/is_active changes.
- `student_profiles` insert must be `pending` with null `student_id`/`approved_*`.
- Dropped policies: `teacher_attendance: self insert` (use `mark_teacher_present`), `audit_logs: insert only` (triggers write audit rows).
- `verify_my_teacher_access_code(code)` / `verify_my_admin_credentials(code, password)` — caller-bound (`auth.uid()`), rate-limited via `private.access_attempts`; admin password checked against `auth.users.encrypted_password`. Legacy `verify_admin_credentials` / `verify_teacher_access_code` are revoked from API roles.
- `create_teacher_profile` — admin-only, requires 6-digit code, normalises phone via `private.normalize_phone`.
- Data repair: phone formats normalised; NULL auth token columns set to `''`.

---

## 10. Indexes Summary

```sql
-- Performance-critical indexes beyond PKs/UQs
CREATE INDEX ON student_profiles (status, board, standard);
CREATE INDEX ON student_profiles (board, standard) WHERE status = 'active';
CREATE INDEX ON student_attendance (student_id, academic_year_id, date DESC);
CREATE INDEX ON teacher_attendance (teacher_id, date DESC);
CREATE INDEX ON monthly_fees (student_id, year DESC, month DESC);
CREATE INDEX ON monthly_fees (status) WHERE status IN ('pending','partially_paid');
CREATE INDEX ON homework (academic_year_id, board, standard, created_at DESC);
CREATE INDEX ON messages (room_id, created_at DESC);
CREATE INDEX ON announcements (type, is_active, created_at DESC);
CREATE INDEX ON audit_logs (performed_by, created_at DESC);
CREATE INDEX ON notifications (user_id, is_read, created_at DESC);
```
