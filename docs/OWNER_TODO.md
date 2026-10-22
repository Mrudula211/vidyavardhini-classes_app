# OWNER_TODO.md — Steps only you can do

Everything that can be built without your accounts, devices or secrets is done.
This file is the single, current list of what is left for you. (Older steps about
SMS providers, DLT registration, test phone numbers and parent self-registration
no longer apply and were removed: the app has **no SMS**, and **the admin creates
every student**.)

Updated 2026-10-22.

---

## 1. Where things stand

**Confirmed working on your phone**
- [x] Admin login (email/mobile + password + access code) and the admin dashboard.
- [x] Admin credentials replaced (the exposed ones are no longer valid).
- [x] Student approval, student ID, student dashboard login, dark-mode text, Hindi/Marathi chips.
- [x] Migrations up to 014 applied (RLS safety net, hardening, recursion fix, password logins).

**Written and tested in code, but not yet confirmed against your live database**
- [ ] Migrations **015, 016, 017** (admin Security screen, admin creates students + access codes, real login methods on the student card).
- [ ] Add Student screen, access-code card, "Generate a new code".
- [ ] Attachments, teacher GPS check-in, promotion, fee reminders, audit logs.
- [ ] Push notifications, monthly fee generation, fee reminders and nightly backups (need section 4).

---

## 2. Do this next (about 15 minutes)

1. **Check which migrations are applied.** In the Supabase SQL Editor run this. Every column should say `true`:
   ```sql
   select
     exists (select 1 from pg_proc where proname = 'is_admin')                       as m013_is_admin,
     exists (select 1 from pg_proc where proname = 'admin_reset_user_password')      as m014_reset,
     exists (select 1 from pg_proc where proname = 'change_my_admin_access_code')    as m015_security,
     exists (select 1 from pg_proc where proname = 'create_student_account')         as m016_students,
     exists (select 1 from pg_tables where tablename = 'student_access_codes')       as m016_codes,
     exists (select 1 from pg_proc where proname = 'get_student_login_methods')      as m017_logins;
   ```
2. **Run any missing migration**, in numeric order, from `supabase/migrations/` (paste the whole file, click Run, accept the "potential issues" popup — it only replaces functions and old policies). Each file is safe to re-run.
3. **Authentication -> Sign In / Providers:**
   - turn **OFF "Allow new users to sign up"** (nobody should be able to create an account on their own);
   - keep the **Email** and **Phone** providers enabled with **"Confirm email"** and **"Enable phone confirmations"** off. The Twilio placeholder values stay — nothing is ever sent.
4. **Make the GitHub repository private** (Settings -> General -> Danger zone -> Change visibility). The old admin password is still in its history.
5. **Install the newest build:** plug in the phone, run `flutter install -d <your phone id> --release` (find the id with `flutter devices`), or copy `build\app\outputs\flutter-apk\app-release.apk` to the phone.

---

## 3. Test on the phone, in this order

Use made-up names and numbers. Tell me what happens, with a screenshot of anything wrong.

1. **Admin:** Login -> email/mobile + password -> access code -> dashboard.
2. **Add a student:** Student Desk -> add-person icon (top right) -> fill the form (a login mobile number you will remember, e.g. `9000000001`) -> ADD STUDENT. Copy the access code from the dialog.
3. **Student login:** log out -> Login -> the student's mobile number + the access code -> Student dashboard. Open Homework, Classwork, My fee status, Timetable: they should show empty messages, not errors.
4. **Lost code:** as admin open the student -> "Generate a new code" -> log in again with the new one (the old one must fail).
5. **Language:** on the Login screen tap हिन्दी, then मराठी; log in and check the dashboard follows.
6. **Teacher:** as admin choose Teacher Desk -> add a teacher (name, mobile and/or email, a login password, an access code). Log in as that teacher with mobile/email + password, then the access code.
7. **Homework with files:** as the teacher create homework with a PDF and a photo; as the student open both. A student of a different class must not see it.
8. **Teacher GPS attendance:** as admin set the geofence (Geofence Settings -> use current location); as the teacher open My Attendance inside and outside the radius.
9. **Security screen:** as admin open Security -> change the password and/or access code -> log out and in with the new ones.
10. **Offline:** turn on airplane mode: the offline banner shows and changes are blocked.

---

## 4. Turn on push notifications, monthly fees and backups (needs a computer with the Supabase CLI)

The code and database parts are ready. Until this is done: push notifications are not delivered and the Backup button does nothing. (The monthly-fee and reminder jobs are already scheduled in the database.)

1. Install the CLI (`npm install -g supabase` or `scoop install supabase`), then `supabase login` and, in the project folder, `supabase link --project-ref rcocjtblpbbslrivqpmm`.
2. The two Vault secrets (`project_url`, `automation_secret`) already exist. Use the **same secret value** below.
3. Firebase Console -> Project settings -> Service accounts -> **Generate new private key** (a `.json` file; never commit it).
4. Set the function secrets:
   ```
   supabase secrets set AUTOMATION_SECRET=THE_SAME_VALUE_AS_IN_VAULT
   supabase secrets set FIREBASE_SERVICE_ACCOUNT="$(cat path/to/service-account.json)"
   ```
5. Deploy both functions:
   ```
   supabase functions deploy send-push --no-verify-jwt
   supabase functions deploy backup-trigger --no-verify-jwt
   ```
6. Verify: Admin -> Backups -> Trigger Manual Backup, wait a minute, refresh: status `success`. Post an announcement: a phone with the app should get a push.

---

## 5. Things to decide

- [ ] **Hindi and Marathi wording:** ask Mrs. Gharat or a staff member to read the student screens in both languages. Send me any wording that sounds unnatural (all text is in `lib/l10n/app_hi.arb` and `app_mr.arb`).
- [ ] **Teachers adding students?** Today only the admin can (the database function is admin-only). Say the word if teachers should too.
- [ ] **Forgot-password by email:** optional. To enable it, edit the Supabase "Magic Link" email template so it contains `{{ .Token }}` and add your own SMTP sender (the built-in sender is heavily rate-limited). Students do not need it: the admin regenerates a lost code.
- [ ] **Access codes are stored readable** (admin-only) so you can show them again. Say if you would rather have them shown only once.
- [ ] **Merge the work into `main`:** the branch `feat/automation-and-release-prep` is pushed; open the pull request when you are happy.
- [ ] **Old commits:** about 16 older commits on `main` carry a "Co-Authored-By: Claude" line. Removing it means rewriting `main` and force-pushing; I will not do that without your explicit OK (and a backup branch first).

---

## 6. Release to the Play Store

1. Create the signing key (once; keep it safe — losing it means you cannot update the app):
   `keytool -genkey -v -keystore C:\Users\asusm\keys\vidyavardhini-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Copy `android/key.properties.example` to `android/key.properties` and fill in the real path and passwords (gitignored).
3. Build: `flutter build appbundle --release` -> `build/app/outputs/bundle/release/app-release.aab`.
4. Create a Google Play Developer account (one-time US$25) at https://play.google.com/console, create the app, upload the `.aab` to **Testing -> Internal testing**, add tester emails.
5. Add your upload key's SHA-1 to Firebase (Project settings -> Your apps -> Add fingerprint): `keytool -list -v -keystore C:\Users\asusm\keys\vidyavardhini-upload.jks -alias upload`. Re-download `google-services.json` if Firebase gives a new one.
6. Store assets: app name, short and full description, 2-8 phone screenshots, 512x512 icon, 1024x500 feature graphic, and a **privacy policy URL** (required: the app collects phone numbers, location and photos). Fill the Play **Data safety** form (phone, email, location, photos, files, FCM token).
7. The app icon and splash come from `images/logo-icon.png` (about 580 px). For a crisper icon, supply a 1024x1024 PNG and ask me to regenerate.

---

## 7. Optional / later

- Build flavors (dev/prod) if you want a separate Supabase project for testing.
- Restoring a backup is a manual database operation for now (backups are JSON files in the private `backups` storage bucket).
- Integration tests for the auth and fee-payment flows (need a test Supabase project).
- Teacher/admin working screens are English only (student and login screens are translated).
