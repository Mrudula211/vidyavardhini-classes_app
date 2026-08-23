<#
Project setup script for Vidyavardhini Classes App

Run from repository root:

.\setup.ps1
#>

Write-Host "==================================="
Write-Host "Vidyavardhini Classes App Setup"
Write-Host "==================================="

if (Test-Path ".env") {
	Write-Host "`nFound .env with client-safe Supabase values."
} else {
	Write-Host "`nNo .env file found. Create one from .env.example with SUPABASE_URL and SUPABASE_ANON_KEY."
}

Write-Host "`nInstalling Flutter packages..."
flutter pub get

Write-Host "`nChecking Flutter installation..."
flutter doctor -v

Write-Host "`nFlutter Version:"
flutter --version

Write-Host "`nRunning code analyzer..."
flutter analyze

Write-Host "`nSetup completed successfully."

Write-Host ""
Write-Host "Next Steps:"
Write-Host "1. Keep the Supabase service-role key only in server-side secrets or Edge Functions."
Write-Host "2. Make sure android/app/google-services.json exists for Android Firebase."
Write-Host "3. Add ios/Runner/GoogleService-Info.plist if you are building for iOS."
Write-Host "4. On Windows, enable Developer Mode so Flutter can create plugin symlinks."
Write-Host "5. Run: flutter run --dart-define-from-file=.env"