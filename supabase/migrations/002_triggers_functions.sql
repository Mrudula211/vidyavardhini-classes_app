-- ============================================================
-- Vidyavardhini Classes — Triggers & Functions
-- Migration: 002 (run after 001)
-- ============================================================

-- ── next_student_id ────────────────────────────────────────
CREATE OR REPLACE FUNCTION next_student_id() RETURNS VARCHAR AS $$
DECLARE next_num INTEGER;
BEGIN
  next_num := nextval('student_id_seq');
  RETURN 'STU' || LPAD(next_num::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- ── next_teacher_id ────────────────────────────────────────
CREATE OR REPLACE FUNCTION next_teacher_id() RETURNS VARCHAR AS $$
DECLARE next_num INTEGER;
BEGIN
  next_num := nextval('teacher_id_seq');
  RETURN 'TCH' || LPAD(next_num::TEXT, 4, '0');
END;
$$ LANGUAGE plpgsql;

-- ── updated_at auto-update ─────────────────────────────────
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_teacher_profiles_updated_at BEFORE UPDATE ON teacher_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_student_profiles_updated_at BEFORE UPDATE ON student_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_homework_updated_at BEFORE UPDATE ON homework FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_classwork_updated_at BEFORE UPDATE ON classwork FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_monthly_fees_updated_at BEFORE UPDATE ON monthly_fees FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_teacher_salary_updated_at BEFORE UPDATE ON teacher_salary FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_fee_structure_updated_at BEFORE UPDATE ON fee_structure FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_student_attendance_updated_at BEFORE UPDATE ON student_attendance FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_teacher_attendance_updated_at BEFORE UPDATE ON teacher_attendance FOR EACH ROW EXECUTE FUNCTION update_updated_at();
CREATE TRIGGER update_announcements_updated_at BEFORE UPDATE ON announcements FOR EACH ROW EXECUTE FUNCTION update_updated_at();

-- ── fee status auto-update ─────────────────────────────────
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
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER fee_status_trigger
  BEFORE INSERT OR UPDATE ON monthly_fees
  FOR EACH ROW EXECUTE FUNCTION update_fee_status();

-- ── sync paid_amount after fee_payments insert ─────────────
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

-- ── generate monthly fee records (called by Edge Function) ─
CREATE OR REPLACE FUNCTION generate_monthly_fees_for_month(p_month SMALLINT, p_year SMALLINT)
RETURNS INTEGER AS $$
DECLARE
  v_count INTEGER := 0;
  v_year_id UUID;
BEGIN
  SELECT id INTO v_year_id FROM academic_years WHERE is_current = true LIMIT 1;
  IF v_year_id IS NULL THEN RETURN 0; END IF;

  INSERT INTO monthly_fees (student_id, academic_year_id, month, year, expected_amount)
  SELECT
    fs.student_id,
    fs.academic_year_id,
    p_month,
    p_year,
    fs.monthly_fee
  FROM fee_structure fs
  JOIN student_profiles sp ON sp.id = fs.student_id AND sp.status = 'active'
  WHERE fs.academic_year_id = v_year_id
  ON CONFLICT (student_id, month, year) DO NOTHING;

  GET DIAGNOSTICS v_count = ROW_COUNT;
  RETURN v_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
