-- Create extension pgcrypto if it does not exist
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- 1. RPC for Admin Login Validation
CREATE OR REPLACE FUNCTION verify_admin_login(p_access_code TEXT, p_password TEXT)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_admin_profile RECORD;
    v_code_valid BOOLEAN;
    v_pass_valid BOOLEAN;
BEGIN
    -- Fetch the first available admin profile (assuming a single admin architecture or any valid admin)
    -- In a multi-admin system, you might pass a username/id, but for now we check the single admin.
    SELECT access_code_hash, password_hash INTO v_admin_profile
    FROM admin_profiles
    LIMIT 1;

    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;

    -- Verify the access code and password using crypt
    v_code_valid := (v_admin_profile.access_code_hash = crypt(p_access_code, v_admin_profile.access_code_hash));
    v_pass_valid := (v_admin_profile.password_hash = crypt(p_password, v_admin_profile.password_hash));

    IF v_code_valid AND v_pass_valid THEN
        RETURN TRUE;
    ELSE
        RETURN FALSE;
    END IF;
END;
$$;

-- 2. RPC for Teacher Login Validation
CREATE OR REPLACE FUNCTION verify_teacher_login(p_access_code TEXT)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_teacher RECORD;
BEGIN
    -- We need to check all teacher_profiles to see if the access code matches one
    -- In a real scenario, this implies iterating over all teachers (which is okay for small N)
    FOR v_teacher IN SELECT id, access_code_hash FROM teacher_profiles LOOP
        IF v_teacher.access_code_hash = crypt(p_access_code, v_teacher.access_code_hash) THEN
            RETURN v_teacher.id;
        END IF;
    END LOOP;

    -- If no match is found, return NULL
    RETURN NULL;
END;
$$;
