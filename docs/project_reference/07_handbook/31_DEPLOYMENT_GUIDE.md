# 31 Deployment Guide

## Purpose
Provides instructions for compiling, signing, and deploying the application to production environments.

## Prerequisites
- Flutter SDK 3.x installed.
- Supabase Project (Production environment) provisioned.
- Firebase Project (Production) provisioned.
- Google Play Console Developer Account.
- Apple Developer Account (if targeting iOS).

## Environment Setup
1. Create a `.env.production` file containing the production Supabase URL, Anon Key, and Firebase configurations.
2. Never commit this file to version control.

## Android Deployment
1. **App Signing:** Ensure `key.properties` is configured in `android/` pointing to the production `.jks` keystore.
2. **Version Bump:** Update `version: 1.0.0+1` in `pubspec.yaml` (increment the build number `+1`).
3. **Build Command:**
   ```bash
   flutter build appbundle --release --dart-define-from-file=.env.production
   ```
4. **Upload:** Take the resulting `app-release.aab` from `build/app/outputs/bundle/release/` and upload it to the Google Play Console (Internal Testing or Production track).

## iOS Deployment (Future)
1. **Provisioning:** Ensure correct certificates and provisioning profiles are set up in Xcode.
2. **Build Command:**
   ```bash
   flutter build ipa --release --dart-define-from-file=.env.production
   ```
3. **Upload:** Use the Transporter app or Xcode to upload the `.ipa` to App Store Connect.

## Backend Deployment (Supabase)
1. Apply migrations to the production DB using Supabase CLI: `supabase db push`.
2. Deploy edge functions: `supabase functions deploy`.
3. Configure Storage buckets (ensure public/private access levels match the dev environment).

## Cross-References
- [05_SUPABASE_ANALYSIS.md](../02_backend/05_SUPABASE_ANALYSIS.md)
