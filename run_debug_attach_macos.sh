#!/usr/bin/env bash

set -euo pipefail

echo "🛠️ macOS Debug-Build + Attach (DeveloperMode)"

command -v flutter >/dev/null 2>&1 || { echo "❌ flutter nicht gefunden"; exit 1; }

flutter config --enable-macos-desktop >/dev/null 2>&1 || true
flutter clean >/dev/null 2>&1 || true
flutter pub get

echo "🏗️ Baue Debug (mit VM Service)"
flutter build macos --debug --dart-define=DEVELOPER_MODE=true

APP_DIR="build/macos/Build/Products/Debug"
APP_PATH="$APP_DIR/eingliederungshilfe_flutter.app"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH=$(find "$APP_DIR" -maxdepth 1 -type d -name "*.app" | head -n1 || true)
fi
if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "❌ Keine .app gefunden"
  exit 1
fi

echo "🧾 Entferne Quarantäne: $APP_PATH"
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

echo "🔐 Ad-hoc Signatur (deep)"
codesign --force --deep --sign - --timestamp=none "$APP_PATH"

echo "🚀 Starte App"
open "$APP_PATH"

echo "⏳ Warte kurz und attach an laufende Flutter-App…"
sleep 2

set +e
flutter attach -d macos
STATUS=$?
set -e

if [[ $STATUS -ne 0 ]]; then
  echo "⚠️ attach fehlgeschlagen. Versuche direkt mit flutter run."
  echo "👉 Alternativ: flutter run -d macos --dart-define=DEVELOPER_MODE=true"
fi

