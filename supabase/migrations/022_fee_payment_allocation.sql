-- 022: one payment can cover several months.
--
-- Before: a payment was always booked on the month the admin opened, so
-- paying October + November together on November made November "paid ₹4000
-- of ₹2000" (pending -₹2000) while October still showed ₹2000 pending.
-- The app also added the amount to paid_amount itself after the trigger had
-- already summed the payments, which could count a payment twice.
--
-- Now: record_fee_payment() spreads the amount over the student's unpaid
-- months, oldest first (one fee_payments row per month), and refuses an
-- amount larger than everything the student owes. paid_amount is always the
-- sum of the payment rows. A one-time repair below moves existing
-- over-payments to the same student's unpaid months.
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
  v_left      NUMERIC := p_amount;
  v_due_total NUMERIC;
  v_part      NUMERIC;
  v_row       RECORD;
  v_months    JSONB := '[]'::jsonb;
BEGIN
  IF NOT public.is_admin() THEN
    RAISE EXCEPTION 'Only the admin can record fee payments';
  END IF;
  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'Enter a payment amount greater than zero';
  END IF;

  SELECT student_id INTO v_student FROM public.monthly_fees WHERE id = p_monthly_fee_id;
  IF v_student IS NULL THEN
    RAISE EXCEPTION 'Fee record not found';
  END IF;

  -- Lock this student's fee rows so two payments cannot race.
  PERFORM 1 FROM public.monthly_fees WHERE student_id = v_student FOR UPDATE;

  SELECT COALESCE(SUM(GREATEST(expected_amount - paid_amount, 0)), 0)
  INTO v_due_total
  FROM public.monthly_fees
  WHERE student_id = v_student AND status <> 'waived';

  IF p_amount > v_due_total THEN
    RAISE EXCEPTION 'Amount is more than the total due for this student (₹%). Record the extra once the next month''s fee is generated.',
      trim(to_char(v_due_total, 'FM999999990.##'));
  END IF;

  FOR v_row IN
    SELECT id, month, year, GREATEST(expected_amount - paid_amount, 0) AS due
    FROM public.monthly_fees
    WHERE student_id = v_student AND status <> 'waived'
      AND expected_amount > paid_amount
    ORDER BY year, month
  LOOP
    EXIT WHEN v_left <= 0;
    v_part := LEAST(v_left, v_row.due);

    INSERT INTO public.fee_payments (
      monthly_fee_id, amount, payment_method, payment_date,
      reference_number, collected_by, notes
    ) VALUES (
      v_row.id, v_part, p_method::payment_method, p_payment_date,
      NULLIF(trim(coalesce(p_reference, '')), ''), auth.uid(),
      CASE WHEN v_part < p_amount
           THEN concat_ws(' ', NULLIF(trim(coalesce(p_notes, '')), ''),
                          '(part of a ₹' || trim(to_char(p_amount, 'FM999999990.##')) || ' payment)')
           ELSE NULLIF(trim(coalesce(p_notes, '')), '') END
    );

    -- Keep paid_amount equal to the payment rows (works with or without
    -- the sync trigger).
    UPDATE public.monthly_fees
    SET paid_amount = (SELECT COALESCE(SUM(amount), 0) FROM public.fee_payments WHERE monthly_fee_id = v_row.id),
        updated_at = now()
    WHERE id = v_row.id;

    v_months := v_months || jsonb_build_object('month', v_row.month, 'year', v_row.year, 'amount', v_part);
    v_left := v_left - v_part;
  END LOOP;

  RETURN jsonb_build_object('allocated', v_months);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

REVOKE ALL ON FUNCTION public.record_fee_payment(UUID, NUMERIC, TEXT, DATE, TEXT, TEXT) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.record_fee_payment(UUID, NUMERIC, TEXT, DATE, TEXT, TEXT) TO authenticated;

-- ── One-time repair of existing data ─────────────────────────
DO $$
DECLARE
  v_over   RECORD;
  v_target RECORD;
  v_pay    RECORD;
  v_excess NUMERIC;
  v_due    NUMERIC;
  v_move   NUMERIC;
BEGIN
  -- 1. paid_amount = sum of payment rows (undoes any double counting).
  UPDATE public.monthly_fees mf
  SET paid_amount = s.total, updated_at = now()
  FROM (
    SELECT mf2.id, COALESCE(SUM(fp.amount), 0) AS total
    FROM public.monthly_fees mf2
    LEFT JOIN public.fee_payments fp ON fp.monthly_fee_id = mf2.id
    GROUP BY mf2.id
  ) s
  WHERE mf.id = s.id AND mf.paid_amount IS DISTINCT FROM s.total;

  -- 2. Move over-payments to the same student's unpaid months, oldest first.
  FOR v_over IN
    SELECT id, student_id, month, year, paid_amount - expected_amount AS excess
    FROM public.monthly_fees
    WHERE paid_amount > expected_amount
    ORDER BY year, month
  LOOP
    v_excess := v_over.excess;

    FOR v_target IN
      SELECT id, expected_amount - paid_amount AS due
      FROM public.monthly_fees
      WHERE student_id = v_over.student_id AND id <> v_over.id
        AND status <> 'waived' AND expected_amount > paid_amount
      ORDER BY year, month
    LOOP
      EXIT WHEN v_excess <= 0;
      v_due := v_target.due;

      -- Take the money from the newest payment rows of the over-paid month.
      FOR v_pay IN
        SELECT * FROM public.fee_payments
        WHERE monthly_fee_id = v_over.id
        ORDER BY created_at DESC
      LOOP
        EXIT WHEN v_excess <= 0 OR v_due <= 0;
        v_move := LEAST(v_excess, v_due, v_pay.amount);

        IF v_move = v_pay.amount THEN
          UPDATE public.fee_payments
          SET monthly_fee_id = v_target.id,
              notes = concat_ws(' ', notes, format('(moved from %s/%s)', v_over.month, v_over.year))
          WHERE id = v_pay.id;
        ELSE
          UPDATE public.fee_payments SET amount = amount - v_move WHERE id = v_pay.id;
          INSERT INTO public.fee_payments (
            monthly_fee_id, amount, payment_method, payment_date,
            reference_number, collected_by, notes
          ) VALUES (
            v_target.id, v_move, v_pay.payment_method, v_pay.payment_date,
            v_pay.reference_number, v_pay.collected_by,
            concat_ws(' ', v_pay.notes, format('(moved from %s/%s)', v_over.month, v_over.year))
          );
        END IF;

        v_excess := v_excess - v_move;
        v_due := v_due - v_move;
      END LOOP;

      UPDATE public.monthly_fees
      SET paid_amount = (SELECT COALESCE(SUM(amount), 0) FROM public.fee_payments WHERE monthly_fee_id = v_target.id),
          updated_at = now()
      WHERE id = v_target.id;
    END LOOP;

    UPDATE public.monthly_fees
    SET paid_amount = (SELECT COALESCE(SUM(amount), 0) FROM public.fee_payments WHERE monthly_fee_id = v_over.id),
        updated_at = now()
    WHERE id = v_over.id;
  END LOOP;
END $$;
