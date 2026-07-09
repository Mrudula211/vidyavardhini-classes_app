<#
Project setup script for vidyavardhini-classes_app
Run this from the repository root in PowerShell:
  .\setup.ps1
#>

Write-Host "Installing Dart/Flutter dependencies..."
flutter pub get

Write-Host "Verifying Flutter setup..."
flutter --version

Write-Host "Running Flutter analyzer..."
flutter analyze

Write-Host "Setup complete. If this is the first run, ensure you add your Supabase and Firebase config files as documented in README.md."
