#!/usr/bin/env bash

set -euo pipefail

echo "🛠️ macOS Debug-Build (mit DeveloperMode)"

# 1) Voraussetzungen
command -v flutter >/dev/null 2>&1 || { echo "❌ flutter nicht gefunden"; exit 1; }

echo "🔧 Stelle sicher, dass macOS Desktop aktiviert ist"
flutter config --enable-macos-desktop >/dev/null 2>&1 || true

echo "🧹 Clean & Dependencies"
flutter clean >/dev/null 2>&1 || true
flutter pub get

# 2) Debug-Build erstellen
echo "🏗️ Baue Debug..."
flutter build macos --debug --dart-define=DEVELOPER_MODE=true

# 3) App-Bundle finden
APP_DIR="build/macos/Build/Products/Debug"

# Prefer the expected app name
PREFERRED_APP="$APP_DIR/eingliederungshilfe_flutter.app"
if [[ -d "$PREFERRED_APP" ]]; then
  APP_PATH="$PREFERRED_APP"
else
  # Fallback: search for any .app in Debug dir
  APP_PATH=$(find "$APP_DIR" -maxdepth 1 -type d -name "*.app" | head -n1 || true)
fi

if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  # Broader search in build tree
  APP_PATH=$(find build/macos -type d -name "*.app" | head -n1 || true)
fi

if [[ -z "${APP_PATH:-}" || ! -d "$APP_PATH" ]]; then
  echo "❌ Keine .app gefunden (gesucht in $APP_DIR und build/macos)"
  exit 1
fi

echo "📦 App: $APP_PATH"

# 4) Quarantäne entfernen und ad-hoc signieren
echo "🧾 Entferne Quarantäne von: $APP_PATH"
xattr -dr com.apple.quarantine "$APP_PATH" 2>/dev/null || true

echo "🔐 Ad-hoc Signatur (deep)"
codesign --force --deep --sign - --timestamp=none "$APP_PATH"

echo "🧪 Prüfe Signatur"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

# 5) Starten
echo "🚀 Starte App"
open "$APP_PATH"

echo ""
echo "💡 Hinweis: Dies ist ein Debug-Build (DeveloperMode aktiv)."
echo "   Für Logs bitte 'Console.app' öffnen oder 'flutter attach' nutzen:"
echo "   flutter attach -d macos"
echo ""
