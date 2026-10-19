#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
flutter create --platforms=android,ios,web --org io.crowly --project-name crowly .
python3 tool/configure_platforms.py
flutter pub get
printf '\nPronto. Demo: flutter run --dart-define=DEMO_MODE=true\n'
