# OWNER_TODO.md — Steps only you can do

Everything in the repo that can be built without your accounts, devices or secrets is done.
What remains needs your Supabase / Firebase / Google Play access or a physical phone.
Do the sections in order, starting with section 0; each is independent of the ones after it.

---

## 0. URGENT — rotate the admin credentials (do this first)

The admin password, email, phone and 6-digit access code were hardcoded in the app's login screen and seeded in `supabase/migrations/004_seed_admin.sql`, so they are also in git history. Anyone with the APK or the repository can read them and sign in as admin. The hardcoded fallbacks are now removed from the app, but the old password stays compromised until you change it.

You need to do the following manually:

1. Open Supabase Dashboard -> **Authentication -> Users** and open the admin user.
2. Set a new strong random password (12+ characters, not reused anywhere).
3. Change the admin access code (stored hashed in `admin_profiles`; see `supabase/migrations/003_auth_rpc.sql` for how it is checked). Tell me and I will write the SQL, without you pasting the code into chat.
4. Keep the new values in a password manager only. Never put them in code, docs or chat.
5. If the GitHub repository is public, make it private now.
6. Sign in on a phone with the new credentials to confirm they work.

Known limitation: access-code-only login is verified on the server but creates no Supabase session, so RLS-protected data still needs an email and password sign-in. Tell me if you want that flow redesigned.

---

## 0b. URGENT — table without Row-Level Security (Supabase advisory, 17 Oct 2026)

Supabase emailed a critical `rls_disabled_in_public` warning for project `rcocjtblpbbslrivqpmm`: at least one table in `public` can be read, edited and deleted by anyone who has the project URL and anon key (the anon key ships inside the app). The repository is not the cause — all 28 tables created by migrations 001-007 enable RLS — so the table was probably created by hand in the dashboard, or a migration was only partly applied.

You need to do the following manually:

1. Open Supabase Dashboard -> **SQL Editor** and run this to list the exposed tables:
   ```sql
   select schemaname, tablename
   from pg_tables
   where schemaname = 'public' and not rowsecurity;
   ```
2. If a table is one of ours (for example `audit_logs`, `fee_payments`, `student_profiles`), re-run the matching part of `supabase/migrations/001_initial_schema.sql` so its RLS policies exist, then run: `alter table public.<name> enable row level security;`
3. If a table is not in the migrations (something you created manually), tell me its name and columns and I will write correct policies. Until then, lock it down with `alter table public.<name> enable row level security;` — with RLS on and no policy, only the service role can access it.
4. Re-run the query from step 1; it must return zero rows.
5. Dashboard -> **Advisors** (sidebar) -> run the Security advisor and clear every remaining warning, or tell me what is left.
6. If any exposed table held real student, fee or phone data, treat it as possibly read by others: check **Logs -> API** for unexpected access, and let affected families know if needed.

---

## 1. Turn on automation (push, monthly fees, reminders, backups)

Code is ready: `supabase/migrations/008_automation.sql` and `supabase/functions/`.
Until you do this, **push notifications are never delivered, monthly fees are not auto-generated, fee reminders are not sent, and the Backup button does nothing**.

You need to do the following manually:

1. Install the Supabase CLI: `npm install -g supabase` (or `scoop install supabase`), then run `supabase login`.
2. In the project folder run: `supabase link --project-ref rcocjtblpbbslrivqpmm`
3. Check migration 006/007 are already applied in your project (SQL Editor → run `select * from supabase_migrations.schema_migrations;` if you use the CLI, otherwise confirm 001–007 were pasted earlier).
4. Open Supabase Dashboard → **Database → Extensions** and enable **pg_cron** and **pg_net** (008 also tries to enable them).
5. Generate a random secret (any 32+ character string), e.g. run `openssl rand -hex 32`. Keep it; you use it twice below.
6. Open Dashboard → **SQL Editor** and run (replace the secret):
   ```sql
   select vault.create_secret('https://rcocjtblpbbslrivqpmm.supabase.co', 'project_url');
   select vault.create_secret('PASTE_YOUR_SECRET', 'automation_secret');
   ```
7. Run the migration: `supabase db push` (or paste `supabase/migrations/008_automation.sql` into the SQL Editor and run it).
8. Get the Firebase service account: Firebase Console → **Project settings → Service accounts → Generate new private key**. A `.json` file downloads. **Never commit it.**
9. Set the Edge Function secrets:
   ```
   supabase secrets set AUTOMATION_SECRET=PASTE_YOUR_SECRET
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
   ```
   (`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are provided to functions automatically.)
10. Deploy both functions (they authenticate via the shared secret, so JWT verification is off):
    ```
    supabase functions deploy send-push --no-verify-jwt
    supabase functions deploy backup-trigger --no-verify-jwt
    ```
11. Verify:
    - Log in as admin → **Backups → Trigger Manual Backup**, wait ~1 minute, refresh: status should be `success`. If `failed`, the `error_msg` column in `backup_logs` says why.
    - Post an announcement and confirm a phone with the app installed receives a push.
    - Dashboard → **Database → Cron Jobs**: three jobs should be listed (`monthly-fee-generate`, `monthly-fee-reminder`, `daily-backup`).

> Note: the fee generation job only creates rows for students who have a `fee_structure` entry for the current academic year.

---

## 2. Verify security against the live database

The RLS audit so far was static (code read-through only). Live per-role testing was never done.

1. Create or use one account for each role: admin, an active teacher, an active student.
2. For each, sign in on a phone and try: a student opening another student's fees, a teacher opening Fees/Revenue, a teacher editing a fee payment.
3. Everything outside the role's own data must be refused or hidden. Write down anything that is not and send it to me.
4. Confirm students can still read their own notifications and fees after migration 008.

---

## 3. Manual QA on a real Android phone

1. Install a debug build: `flutter run --dart-define-from-file=.env` (or your usual command).
2. Walk through each role end to end: student registration → admin approval → student first-login password → attendance → homework → fees → chat → announcements.
3. Switch the phone to **dark mode** and open every screen (the "Dark mode QA pass" item is still open). Note any unreadable text or white-on-white areas.
4. Turn on airplane mode: the offline banner should appear, cached lists should still load, and writes should be blocked with a message.
5. Test on at least three screen sizes (small phone, large phone, tablet or emulator).
6. Send me the list of problems and I will fix them.

---

## 4. Release build and Play Store

1. Create the signing key (once, keep it safe — **losing it means you cannot update the app**):
   ```
   keytool -genkey -v -keystore C:\Users\asusm\keys\vidyavardhini-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
2. Copy `android/key.properties.example` to `android/key.properties` and fill in the real path and passwords. (Gitignored.)
3. Build: `flutter build appbundle --release` → output at `build/app/outputs/bundle/release/app-release.aab`.
4. Create a Google Play Developer account (one-time US$25 fee) at https://play.google.com/console.
5. Create the app, then upload the `.aab` to **Testing → Internal testing**, add tester emails, and install via the opt-in link.
6. Add your upload key's SHA-1 to Firebase (Project settings → Your apps → Add fingerprint). Get it with: `keytool -list -v -keystore C:\Users\asusm\keys\vidyavardhini-upload.jks -alias upload`. Replace `google-services.json` with the re-downloaded copy if Firebase gives you a new one.
7. If you use Google Maps in release, add the same SHA-1 to your Maps API key restrictions.

---

## 5. Store assets (need your design decisions)

1. **App icon / splash**: already generated from `images/logo-icon.png` (about 580px). Check how it looks on a phone. For a crisper result, supply a 1024×1024 PNG and ask me to regenerate.
2. **Play Store listing**: app name, short description (80 chars), full description, 2–8 phone screenshots, a 512×512 icon and a 1024×500 feature graphic.
3. **Privacy policy URL** — required by Play because the app collects phone numbers, location and photos. Host a page and paste the URL into the Play Console.
4. Fill the Play Console **Data safety** form (phone, location, photos, files, FCM token).

---

## 6. Optional / later

- **Build flavors (dev/prod)** — still open in Phase 0; only worth doing if you want a separate Supabase project for testing.
- **Backup restore** — v1 only creates backups (JSON in the private `backups` bucket; download from Dashboard → Storage). Restoring is a manual database operation for now.
- **Login form widget test** and **integration tests** (auth flow, fee payment) — need a test Supabase project and credentials.
- **Multi-device release testing** — step 3 above.
