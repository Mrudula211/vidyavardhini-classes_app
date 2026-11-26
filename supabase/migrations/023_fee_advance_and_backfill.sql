-- 023: smarter fee payments (replaces record_fee_payment from 022).
--
-- The owner's rule: a student's fee is fixed per month (fee_structure). When
-- the admin records ₹4000 or ₹6000 for a ₹2000/month student:
--   1. first every unpaid month since the student joined is paid, oldest
--      first. Months that were never generated (from the later of the
--      student's joining date and the academic-year start, up to this month)
--      are created first, so "previous fees not paid" is found;
--   2. whatever is left pays the UPCOMING months in advance: those months are
--      created now and marked paid. The monthly job (ON CONFLICT DO NOTHING)
--      later leaves them as they are.
-- Advance payment cannot go past the end of the academic year.
-- Safe to re-run.

CREATE OR REPLACE FUNCTION public.record_fee_payment(
  p_monthly_fee_id UUID,
  p_amount         NUMERIC,
  p_method         TEXT,
  p_payment_date   DATE,
  p_reference      TEXT DEFAULT NULL,
  p_notes          TEXT DEFAULT NULL
) RETURNS JSONB AS $$
DECLARE
  v_student   UUID;
  v_year_id   UUID;
  v_start     DATE;
  v_end       DATE;
  v_joined    DATE;
  v_fee       NUMERIC;
  v_month     DATE;
  v_left      NUMERIC := p_amount;
  v_part      NUMERIC;
  v_row       RECORD;
  v_fee_id    UUID;
  v_due       NUMERIC;
  v_guard     INT := 0;
  v_months    JSONB := '[]'::jsonb;
  v_note      TEXT;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the admin can record fee payments';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Enter a payment amount greater than zero';
  END IF;

  SELECT mf.student_id INTO v_student FROM public.monthly_fees mf WHERE mf.id = p_monthly_fee_id;
  IF v_student IS NULL THEN
    RAISE EXCEPTION 'Fee record not found';
  END IF;

  SELECT id, start_date, end_date INTO v_year_id, v_start, v_end
  FROM public.academic_years WHERE is_current = true LIMIT 1;

  SELECT monthly_fee INTO v_fee
  FROM public.fee_structure WHERE student_id = v_student AND academic_year_id = v_year_id;

  SELECT created_at::date INTO v_joined FROM public.student_profiles WHERE id = v_student;

  -- Lock this student's fee rows so two payments cannot race.
  PERFORM 1 FROM public.monthly_fees WHERE student_id = v_student FOR UPDATE;

  -- 1a. Create any missing month from joining (or year start) up to now.
  IF v_year_id IS NOT NULL AND COALESCE(v_fee, 0) > 0 THEN
    v_month := date_trunc('month', GREATEST(COALESCE(v_joined, v_start), v_start))::date;
    WHILE v_month <= date_trunc('month', current_date)::date LOOP
      INSERT INTO public.monthly_fees (student_id, academic_year_id, month, year, expected_amount)
      VALUES (v_student, v_year_id, EXTRACT(MONTH FROM v_month)::smallint,
              EXTRACT(YEAR FROM v_month)::smallint, v_fee)
      ON CONFLICT (student_id, month, year) DO NOTHING;
      v_month := (v_month + INTERVAL '1 month')::date;
    END LOOP;
  END IF;

  v_note := NULLIF(trim(coalesce(p_notes, '')), '');

  -- 1b. Pay unpaid months, oldest first.
  FOR v_row IN
    SELECT id, month, year, expected_amount - paid_amount AS due
    FROM public.monthly_fees
    WHERE student_id = v_student AND status <> 'waived'
      AND expected_amount > paid_amount
    ORDER BY year, month
  LOOP
    EXIT WHEN v_left <= 0;
    v_part := LEAST(v_left, v_row.due);
    INSERT INTO public.fee_payments (monthly_fee_id, amount, payment_method, payment_date,
                                     reference_number, collected_by, notes)
    VALUES (v_row.id, v_part, p_method::payment_method, p_payment_date,
            NULLIF(trim(coalesce(p_reference, '')), ''), auth.uid(),
            CASE WHEN v_part < p_amount
                 THEN concat_ws(' ', v_note, '(part of a ₹' || trim(to_char(p_amount, 'FM999999990.##')) || ' payment)')
                 ELSE v_note END);
    UPDATE public.monthly_fees
    SET paid_amount = (SELECT COALESCE(SUM(amount), 0) FROM public.fee_payments WHERE monthly_fee_id = v_row.id),
        updated_at = now()
    WHERE id = v_row.id;
    v_months := v_months || jsonb_build_object('month', v_row.month, 'year', v_row.year, 'amount', v_part, 'advance', false);
    v_left := v_left - v_part;
  END LOOP;

  -- 2. Anything left pays the coming months in advance.
  IF v_left > 0 THEN
    IF v_year_id IS NULL OR COALESCE(v_fee, 0) <= 0 THEN
      RAISE EXCEPTION 'All fees are paid and this student has no monthly fee set, so an advance cannot be recorded. Set the monthly fee first.';
    END IF;

    SELECT (make_date(year, month, 1) + INTERVAL '1 month')::date INTO v_month
    FROM public.monthly_fees WHERE student_id = v_student
    ORDER BY year DESC, month DESC LIMIT 1;
    v_month := GREATEST(COALESCE(v_month, date_trunc('month', current_date)::date),
                        date_trunc('month', current_date)::date);

    WHILE v_left > 0 LOOP
      v_guard := v_guard + 1;
      IF v_month > v_end OR v_guard > 24 THEN
        RAISE EXCEPTION 'This amount pays beyond the end of the academic year (%). Record at most the fees up to then.', v_end;
      END IF;

      INSERT INTO public.monthly_fees (student_id, academic_year_id, month, year, expected_amount)
      VALUES (v_student, v_year_id, EXTRACT(MONTH FROM v_month)::smallint,
              EXTRACT(YEAR FROM v_month)::smallint, v_fee)
      ON CONFLICT (student_id, month, year) DO NOTHING;

      SELECT id, expected_amount - paid_amount INTO v_fee_id, v_due
      FROM public.monthly_fees
      WHERE student_id = v_student
        AND month = EXTRACT(MONTH FROM v_month) AND year = EXTRACT(YEAR FROM v_month);

      IF v_due > 0 THEN
        v_part := LEAST(v_left, v_due);
        INSERT INTO public.fee_payments (monthly_fee_id, amount, payment_method, payment_date,
                                         reference_number, collected_by, notes)
        VALUES (v_fee_id, v_part, p_method::payment_method, p_payment_date,
                NULLIF(trim(coalesce(p_reference, '')), ''), auth.uid(),
                concat_ws(' ', v_note, '(advance, part of a ₹' || trim(to_char(p_amount, 'FM999999990.##')) || ' payment)'));
        UPDATE public.monthly_fees
        SET paid_amount = (SELECT COALESCE(SUM(amount), 0) FROM public.fee_payments WHERE monthly_fee_id = v_fee_id),
            updated_at = now()
        WHERE id = v_fee_id;
        v_months := v_months || jsonb_build_object(
          'month', EXTRACT(MONTH FROM v_month)::int, 'year', EXTRACT(YEAR FROM v_month)::int,
          'amount', v_part, 'advance', true);
        v_left := v_left - v_part;
      END IF;

      v_month := (v_month + INTERVAL '1 month')::date;
    END LOOP;
  END IF;

  RETURN jsonb_build_object('allocated', v_months);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.record_fee_payment(UUID, NUMERIC, TEXT, DATE, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_fee_payment(UUID, NUMERIC, TEXT, DATE, TEXT, TEXT) TO authenticated;
