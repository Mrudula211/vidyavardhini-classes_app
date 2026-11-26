-- 024: repair app-created logins that cannot sign in.
--
-- Accounts made by older versions of create_teacher_profile (e.g. TCH0008,
-- created 2026-10-07) can be missing what Supabase Auth needs to accept an
-- email + password login, so even a freshly reset access code is rejected
-- with "Invalid login credentials". This brings every teacher/student login
-- in line with what the current create functions write. Safe to re-run.
-- The SELECT at the end shows each teacher's login state.

-- 1. Basic fields Supabase Auth filters on.
UPDATE auth.users u
SET instance_id = '00000000-0000-0000-0000-000000000000',
    aud  = 'authenticated',
    role = 'authenticated',
    updated_at = now()
FROM public.users pu
WHERE pu.id = u.id AND pu.role IN ('teacher', 'student')
  AND (u.instance_id IS DISTINCT FROM '00000000-0000-0000-0000-000000000000'
       OR u.aud IS DISTINCT FROM 'authenticated'
       OR u.role IS DISTINCT FROM 'authenticated');

-- 2. Teacher login email = the email on the teacher profile (when no other
--    account already uses it).
UPDATE auth.users u
SET email = lower(trim(tp.email)), updated_at = now()
FROM public.teacher_profiles tp
WHERE tp.id = u.id
  AND NULLIF(trim(coalesce(tp.email, '')), '') IS NOT NULL
  AND (u.email IS NULL OR lower(u.email) <> lower(trim(tp.email)))
  AND NOT EXISTS (
    SELECT 1 FROM auth.users x
    WHERE lower(x.email) = lower(trim(tp.email)) AND x.id <> u.id
  );

-- 3. Confirmed, not banned, not deleted; NULL token columns (which make
--    Supabase Auth fail) become empty strings.
UPDATE auth.users u
SET email_confirmed_at = CASE WHEN u.email IS NOT NULL THEN COALESCE(u.email_confirmed_at, now()) ELSE u.email_confirmed_at END,
    phone_confirmed_at = CASE WHEN u.phone IS NOT NULL THEN COALESCE(u.phone_confirmed_at, now()) ELSE u.phone_confirmed_at END,
    banned_until = NULL,
    deleted_at = NULL,
    confirmation_token = COALESCE(u.confirmation_token, ''),
    recovery_token = COALESCE(u.recovery_token, ''),
    email_change_token_new = COALESCE(u.email_change_token_new, ''),
    email_change = COALESCE(u.email_change, ''),
    updated_at = now()
FROM public.users pu
WHERE pu.id = u.id AND pu.role IN ('teacher', 'student') AND pu.is_active = true;

-- 4. Identity rows (one per email / phone), as the create functions add.
DO $$
BEGIN
  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  SELECT gen_random_uuid(), u.id, u.email,
         jsonb_build_object('sub', u.id::text, 'email', u.email, 'email_verified', true),
         'email', now(), now(), now()
  FROM auth.users u
  JOIN public.users pu ON pu.id = u.id AND pu.role IN ('teacher', 'student')
  WHERE u.email IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = u.id AND i.provider = 'email');

  INSERT INTO auth.identities (id, user_id, provider_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
  SELECT gen_random_uuid(), u.id, u.phone,
         jsonb_build_object('sub', u.id::text, 'phone', u.phone, 'phone_verified', true),
         'phone', now(), now(), now()
  FROM auth.users u
  JOIN public.users pu ON pu.id = u.id AND pu.role IN ('teacher', 'student')
  WHERE u.phone IS NOT NULL
    AND NOT EXISTS (SELECT 1 FROM auth.identities i WHERE i.user_id = u.id AND i.provider = 'phone');
EXCEPTION WHEN OTHERS THEN
  RAISE NOTICE 'identity rows not added: %', SQLERRM;
END $$;

-- 5. Show the result for every teacher.
SELECT tp.teacher_id,
       tp.email AS profile_email,
       u.email  AS login_email,
       u.phone  AS login_phone,
       u.email_confirmed_at IS NOT NULL AS email_confirmed,
       u.encrypted_password IS NOT NULL AND u.encrypted_password <> '' AS has_password,
       (SELECT string_agg(provider, ',') FROM auth.identities i WHERE i.user_id = u.id) AS identities
FROM public.teacher_profiles tp
LEFT JOIN auth.users u ON u.id = tp.id
ORDER BY tp.teacher_id;
