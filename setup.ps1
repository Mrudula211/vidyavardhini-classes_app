<#
Project setup script for Vidyavardhini Classes App

Run from repository root:

.\setup.ps1
#>

Write-Host "==================================="
Write-Host "Vidyavardhini Classes App Setup"
Write-Host "==================================="

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
Write-Host "1. Configure Supabase credentials (if not already configured)."
Write-Host "2. Configure Firebase (if the project uses Firebase)."
Write-Host "3. Run: flutter run"