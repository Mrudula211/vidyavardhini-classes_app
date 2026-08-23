-- ============================================================
-- Vidyavardhini Classes — Auth RPCs
-- Migration: 003
-- ============================================================

-- Enable pgcrypto extension for bcrypt functions
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ── verify_admin_credentials ────────────────────────────────
CREATE OR REPLACE FUNCTION verify_admin_credentials(
  p_access_code TEXT,
  p_password TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_access_code_hash VARCHAR;
  v_password_hash VARCHAR;
BEGIN
  -- We assume there's only one admin profile, or we fetch the first one.
  -- Given the existing flutter implementation selects without conditions:
  SELECT access_code_hash, password_hash
  INTO v_access_code_hash, v_password_hash
  FROM admin_profiles
  LIMIT 1;

  IF v_access_code_hash IS NULL OR v_password_hash IS NULL THEN
    RETURN FALSE;
  END IF;

  IF v_access_code_hash = crypt(p_access_code, v_access_code_hash) AND
     v_password_hash = crypt(p_password, v_password_hash) THEN
    RETURN TRUE;
  END IF;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ── verify_teacher_access_code ──────────────────────────────
CREATE OR REPLACE FUNCTION verify_teacher_access_code(
  p_access_code TEXT
) RETURNS BOOLEAN AS $$
DECLARE
  v_hash VARCHAR;
BEGIN
  -- We iterate through teacher hashes. If one matches, return true.
  -- A more optimized way would be to pass teacher_id, but the flutter implementation
  -- just checks against all teacher access codes.
  FOR v_hash IN SELECT access_code_hash FROM teacher_profiles WHERE access_code_hash IS NOT NULL LOOP
    IF v_hash = crypt(p_access_code, v_hash) THEN
      RETURN TRUE;
    END IF;
  END LOOP;

  RETURN FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
