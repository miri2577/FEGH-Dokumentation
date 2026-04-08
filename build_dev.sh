#!/bin/bash

# Entwicklungs-Build mit Entwicklermodus aktiviert
# Dieses Skript erstellt einen Build für Entwicklung und Tests

set -e

echo "🛠️  Erstelle Entwicklungs-Build..."
echo "⚠️  ENTWICKLERMODUS WIRD AKTIVIERT"
echo ""

# Cleanup
echo "🧹 Bereinige vorherige Builds..."
flutter clean
flutter pub get

echo ""
echo "🔧 Baue App mit Entwickler-Features..."
echo "   - Keychain-Verschlüsselung deaktiviert"
echo "   - Debug-Logs aktiviert"
echo "   - Erweiterte Datei-Zugriffe erlaubt"
echo ""

# Build mit Entwicklermodus
flutter build macos --release --dart-define=DEVELOPER_MODE=true

# App Bundle Pfad
APP="build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"

echo "🔐 Signiere App für lokale Entwicklung..."
codesign --force --deep --sign - --timestamp=none "$APP"
xattr -dr com.apple.quarantine "$APP"

echo ""
echo "✅ Entwicklungs-Build erfolgreich erstellt!"
echo ""
echo "⚠️  WICHTIGER HINWEIS:"
echo "   Diese Version ist NUR für Entwicklung und Tests!"
echo "   Für Production verwende: ./build_prod.sh"
echo ""
echo "📱 App starten:"
echo "   open \"$APP\""
echo ""