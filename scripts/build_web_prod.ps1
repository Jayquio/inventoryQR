# Build Flutter web for production with the public API URL baked in.
# Run from repo root:  .\scripts\build_web_prod.ps1
$ErrorActionPreference = "Stop"
$apiUrl = "https://api.medtechinventorysystem.org"
Set-Location (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path))
flutter pub get
flutter build web --release --dart-define=API_BASE_URL=$apiUrl
Write-Host "Done. Commit folder build/web/ then push so Docker on the server can COPY it."
