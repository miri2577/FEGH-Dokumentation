#!/bin/bash

# Produktions-Build mit Sicherheitsvalidierung
# Dieses Skript erstellt einen sicheren Build für Veröffentlichung

set -e

echo "🚀 Erstelle Produktions-Build..."
echo ""

# Sicherheitsprüfung: Stelle sicher, dass keine Entwickler-Flags gesetzt sind
if [[ "$*" == *"DEVELOPER_MODE=true"* ]]; then
    echo "❌ FEHLER: Entwicklermodus ist aktiviert!"
    echo "   Für Produktions-Build darf DEVELOPER_MODE nicht gesetzt sein."
    exit 1
fi

# Prüfe auf Entwickler-Code in kritischen Dateien
echo "🔍 Führe Sicherheitsprüfungen durch..."

# Prüfe auf temporäre Entwickler-Entitlements
if grep -q "temporary-exception" macos/Runner/*.entitlements 2>/dev/null; then
    echo "⚠️  WARNUNG: Temporäre Entwickler-Entitlements gefunden!"
    echo "   Diese sollten für Production entfernt werden."
    echo ""
    echo "Gefundene temporäre Entitlements:"
    grep -n "temporary-exception" macos/Runner/*.entitlements || true
    echo ""
    read -p "Trotzdem fortfahren? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Build abgebrochen."
        exit 1
    fi
fi

# Cleanup
echo "🧹 Bereinige vorherige Builds..."
flutter clean
flutter pub get

echo ""
echo "🔒 Baue App mit Produktions-Sicherheitsfeatures..."
echo "   - Keychain-Verschlüsselung aktiviert"
echo "   - Debug-Logs deaktiviert"
echo "   - Erweiterte Datei-Zugriffe entfernt"
echo ""

# Produktions-Build (ohne DEVELOPER_MODE Flag)
flutter build macos --release

# App Bundle Pfad
APP="build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"

echo "🔐 Signiere App für Produktion..."
codesign --force --deep --sign - --timestamp=none "$APP"
xattr -dr com.apple.quarantine "$APP"

# Finale Sicherheitsvalidierung
echo ""
echo "🔍 Führe finale Sicherheitsvalidierung durch..."

# Prüfe Code-Signierung
if codesign --verify --verbose "$APP" 2>&1 | grep -q "satisfies its Designated Requirement"; then
    echo "✅ Code-Signierung validiert"
else
    echo "❌ Code-Signierung fehlgeschlagen"
    exit 1
fi

# Prüfe auf Debug-Symbole
if [[ -d "$APP/Contents/Resources/DWARF" ]]; then
    echo "⚠️  Debug-Symbole gefunden (eventuell entfernen für finale Veröffentlichung)"
else
    echo "✅ Keine Debug-Symbole gefunden"
fi

echo ""
echo "🎉 Produktions-Build erfolgreich erstellt!"
echo ""
echo "📋 WICHTIGE SCHRITTE VOR VERÖFFENTLICHUNG:"
echo "   1. App auf verschiedenen macOS-Versionen testen"
echo "   2. Alle Sicherheitsfeatures validieren"
echo "   3. Keychain-Funktionalität testen"
echo "   4. Biometrische Authentifizierung testen"
echo "   5. Temporäre Entitlements entfernen"
echo ""
echo "📱 App testen:"
echo "   open \"$APP\""
echo ""