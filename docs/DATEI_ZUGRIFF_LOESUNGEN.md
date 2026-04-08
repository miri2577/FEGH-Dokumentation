# Lösungen für Datei-Import in der macOS App

## Problem
Die App läuft im App Sandbox Modus und kann nicht auf unverschlüsselte Backup-Daten zugreifen, die außerhalb der Sandbox-Container liegen.

## ✅ Implementierte Lösung: Erweiterte Entitlements

### Hinzugefügte Entitlements
Die folgenden Entitlements wurden zu beiden Entitlement-Dateien hinzugefügt:

**Dateien:**
- `macos/Runner/Release.entitlements`
- `macos/Runner/DebugProfile.entitlements`

**Neue Entitlements:**
```xml
<!-- Bookmark-Support für persistente Dateizugriffe -->
<key>com.apple.security.files.bookmarks.app-scope</key>
<true/>
<key>com.apple.security.files.bookmarks.document-scope</key>
<true/>

<!-- Temporäre Ausnahme für erweiterten Dateizugriff (NUR für Tests) -->
<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
<array>
    <string>/</string>
</array>
```

### Was diese Entitlements bewirken:

1. **Bookmarks**: Ermöglicht der App, persistente Referenzen auf Dateien zu speichern, die der Nutzer ausgewählt hat
2. **Home-relative-path**: Temporäre Ausnahme für Zugriff auf das gesamte Benutzerverzeichnis (nur für Entwicklung/Tests)

## 🔄 Build-Prozess mit erweiterten Rechten

```bash
# 1. App mit neuen Entitlements bauen
flutter build macos --release

# 2. Ad-hoc signieren
APP="build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"
codesign --force --deep --sign - --timestamp=none "$APP"

# 3. Quarantäne entfernen
xattr -dr com.apple.quarantine "$APP"

# 4. App starten
open "$APP"
```

## 📁 Alternative Lösungsansätze

### Option 1: Datei-Picker verwenden (Empfohlen für Production)
```dart
// Die App sollte den nativen Datei-Picker verwenden
import 'package:file_picker/file_picker.dart';

Future<void> importBackupData() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['json', 'txt', 'backup'],
  );

  if (result != null) {
    File file = File(result.files.single.path!);
    // File ist jetzt über Sandbox-Berechtigung zugänglich
    String contents = await file.readAsString();
    // Backup-Daten verarbeiten...
  }
}
```

### Option 2: Drag & Drop Support
```dart
// DropTarget Widget für Drag & Drop von Dateien
import 'package:desktop_drop/desktop_drop.dart';

Widget build(BuildContext context) {
  return DropTarget(
    onDragDone: (detail) {
      for (final file in detail.files) {
        // Datei wurde in die App gezogen
        importBackupFromFile(file.path);
      }
    },
    child: Container(
      child: Text('Backup-Datei hier hinziehen'),
    ),
  );
}
```

### Option 3: App ohne Sandbox (Nur für Entwicklung)
```xml
<!-- In beiden .entitlements Dateien auskommentieren: -->
<!--
<key>com.apple.security.app-sandbox</key>
<true/>
-->
```

⚠️ **Warnung**: Ohne Sandbox verliert die App wichtige Sicherheitsfeatures!

## 🧪 Datei-Zugriff testen

### Test-Backup-Datei erstellen:
```bash
# Beispiel-Backup-Datei im Home-Verzeichnis erstellen
echo '{"version": "1.0", "data": "test backup data"}' > ~/test_backup.json
```

### In der App testen:
1. App starten
2. Datei-Import-Funktion verwenden
3. Zu `~/test_backup.json` navigieren
4. Datei sollte erfolgreich importiert werden

## 🔐 Sicherheitsaspekte

### Aktuelle Konfiguration (für Tests):
- ✅ App Sandbox aktiviert
- ✅ Keychain-Zugriff konfiguriert
- ✅ Netzwerk-Client-Berechtigung
- ✅ Benutzer-ausgewählte Dateien (read-write)
- ✅ Downloads-Ordner (read-write)
- ⚠️ Temporäre Ausnahme für Home-Verzeichnis (nur für Tests)

### Für Production empfohlen:
```xml
<!-- Entfernen Sie diese Zeilen für Production: -->
<!--
<key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
<array>
    <string>/</string>
</array>
-->
```

## 📋 Vollständige Entitlements-Referenz

### Release.entitlements (Final)
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
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
    <key>com.apple.security.files.bookmarks.app-scope</key>
    <true/>
    <key>com.apple.security.files.bookmarks.document-scope</key>
    <true/>
    <!-- NUR für Entwicklung/Tests: -->
    <key>com.apple.security.temporary-exception.files.home-relative-path.read-write</key>
    <array>
        <string>/</string>
    </array>
</dict>
</plist>
```

## 🚀 Nächste Schritte

1. **Aktuell**: App kann unverschlüsselte Backup-Daten aus dem gesamten Dateisystem importieren
2. **Testen**: Verschiedene Backup-Dateien und -formate ausprobieren
3. **Sicherheit**: Für Production die temporäre Ausnahme entfernen
4. **UI/UX**: Datei-Picker und Drag & Drop in der App implementieren

## 🛠️ Troubleshooting

**Problem**: App kann immer noch nicht auf Dateien zugreifen
```bash
# 1. Entitlements der laufenden App prüfen
codesign -d --entitlements - "$APP"

# 2. App neu signieren
codesign --force --deep --sign - --timestamp=none "$APP"

# 3. App neu starten
pkill eingliederungshilfe_flutter && open "$APP"
```

**Problem**: Bestimmte Ordner immer noch nicht zugänglich
```bash
# System-Berechtigungen in den Systemeinstellungen prüfen:
# Systemeinstellungen > Sicherheit & Datenschutz > Datenschutz > Vollständiger Festplattenzugriff
# App manuell hinzufügen falls nötig
```

Die App sollte jetzt in der Lage sein, unverschlüsselte Backup-Daten für Sicherheitstests zu importieren!