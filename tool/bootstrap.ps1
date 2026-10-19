$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '..')
flutter create --platforms=android,ios,web --org io.crowly --project-name crowly .
if ($LASTEXITCODE -ne 0) { throw 'flutter create falhou' }
python tool/configure_platforms.py
if ($LASTEXITCODE -ne 0) { throw 'A configuração de plataformas falhou' }
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'flutter pub get falhou' }
Write-Host 'Demo: flutter run --dart-define=DEMO_MODE=true'
