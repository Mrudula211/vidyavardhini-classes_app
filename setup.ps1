<#
Project setup script for Vidyavardhini Classes App

Run from repository root:

.\setup.ps1
#>

Write-Host "==================================="
Write-Host "Vidyavardhini Classes App Setup"
Write-Host "==================================="

if (Test-Path "lib\core\constants\supabase_keys.dart") {
	Write-Host "`nFound lib\core\constants\supabase_keys.dart."
} else {
	Write-Host "`nNo lib\core\constants\supabase_keys.dart found. Copy lib\core\constants\supabase_keys.example.dart to that path and fill in your Supabase URL and anon/publishable key."
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
Write-Host "1. Copy lib\core\constants\supabase_keys.example.dart to supabase_keys.dart and fill in your Supabase URL and anon/publishable key (never the service-role key)."
Write-Host "2. Make sure android/app/google-services.json exists for Android Firebase."
Write-Host "3. Add ios/Runner/GoogleService-Info.plist if you are building for iOS."
Write-Host "4. On Windows, enable Developer Mode so Flutter can create plugin symlinks."
Write-Host "5. Run: flutter run"