# macOS Code-Signing für Flutter Apps ohne Developer Account

Dieses Dokument beschreibt, wie Sie eine Flutter macOS App ohne Apple Developer Account lokal signieren und starten können.

## Problem

Ohne korrekte Code-Signierung beendet macOS Flutter Apps sofort mit dem Fehler:
```
Termination Reason: CODESIGNING … Taskgated Invalid Signature
codeSigningID: ""
```

## Lösung: Ad-hoc Code-Signierung

### 1. Clean Build erstellen

```bash
# Flutter clean und release build
flutter clean
flutter build macos --release
```

### 2. App Bundle ad-hoc signieren

```bash
# Pfad zur erstellten App
APP="build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"

# Tiefe Signierung über das gesamte Bundle (wichtig für Frameworks und Plugins)
codesign --force --deep --sign - --timestamp=none "$APP"
```

**Wichtig:**
- `--deep` signiert alle Frameworks (z.B. FlutterMacOS.framework) und Plugin-Bundles
- `-` bedeutet ad-hoc Signierung (kein Zertifikat erforderlich)
- `--timestamp=none` verhindert Timestamp-Server Probleme

### 3. Quarantäne-Flag entfernen

```bash
# Quarantäne entfernen (falls App aus ZIP/Download stammt)
xattr -dr com.apple.quarantine "$APP"
```

### 4. Code-Signierung verifizieren

```bash
# Signierung prüfen
codesign -dv --verbose=4 "$APP"
```

Erwartete Ausgabe sollte enthalten:
- `Signature=adhoc`
- `Identifier=com.example.eingliederungshilfeFlutter`
- Keine Fehler

### 5. App starten

```bash
# App öffnen
open "$APP"

# Oder direkt ausführen
"$APP/Contents/MacOS/eingliederungshilfe_flutter"
```

## Verifikation

```bash
# Prüfen ob App läuft
ps aux | grep eingliederungshilfe_flutter
```

## Sicherheitseinstellungen

### macOS Deployment Target auf 15.0 setzen

Die App ist konfiguriert mit modernen Sicherheitsstandards:

**Podfile** (`macos/Podfile`):
```ruby
platform :osx, '15.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_macos_build_settings(target)

    # Force minimum macOS deployment target to 15.0 for all pods
    target.build_configurations.each do |config|
      if config.build_settings['MACOSX_DEPLOYMENT_TARGET'].to_f < 15.0
        config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
```

### Entitlements

**Debug/Profile** (`macos/Runner/DebugProfile.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.example.eingliederungshilfeFlutter</string>
</array>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

**Release** (`macos/Runner/Release.entitlements`):
```xml
<key>com.apple.security.app-sandbox</key>
<true/>
<key>com.apple.security.network.client</key>
<true/>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.example.eingliederungshilfeFlutter</string>
</array>
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.example.eingliederungshilfeFlutter</string>
</array>
<key>com.apple.security.files.user-selected.read-write</key>
<true/>
<key>com.apple.security.files.downloads.read-write</key>
<true/>
```

## Vollständiges Skript

```bash
#!/bin/bash

# Pfad zur Flutter App
cd /path/to/your/flutter/project

# Clean build
flutter clean
flutter build macos --release

# App Bundle Pfad
APP="build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"

# Ad-hoc signieren
codesign --force --deep --sign - --timestamp=none "$APP"

# Quarantäne entfernen
xattr -dr com.apple.quarantine "$APP"

# Signierung verifizieren
echo "Code-Signierung Status:"
codesign -dv --verbose=4 "$APP"

# App starten
echo "App wird gestartet..."
open "$APP"

# Status prüfen
sleep 2
ps aux | grep eingliederungshilfe_flutter | grep -v grep
```

## Hinweise

- ✅ Funktioniert mit SIP (System Integrity Protection) aktiviert
- ✅ Funktioniert mit Gatekeeper aktiviert
- ✅ Kein Apple Developer Account erforderlich
- ✅ Alle Sicherheitsfeatures testbar
- ⚠️ App ist nur lokal signiert (nicht für Distribution geeignet)
- ⚠️ Debug-Modus hat weiterhin Code-Signing Probleme (nutzen Sie Release-Modus)

## Troubleshooting

**Problem:** App startet immer noch nicht
```bash
# Alte Signaturen komplett entfernen und neu signieren
codesign --remove-signature "$APP"
codesign --force --deep --sign - --timestamp=none "$APP"
```

**Problem:** Frameworks nicht signiert
```bash
# Prüfen welche Frameworks signiert sind
find "$APP" -name "*.framework" -exec codesign -dv {} \;
```

**Problem:** Plugin-Bundles verursachen Probleme
```bash
# Alle Bundles einzeln signieren
find "$APP" -name "*.bundle" -exec codesign --force --sign - {} \;
```