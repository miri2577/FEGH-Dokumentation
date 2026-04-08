# 🛠️ Entwicklermodus System

Dieses System ermöglicht sichere Entwicklung und Tests ohne Kompromittierung der Produktionssicherheit.

## 🚨 **KRITISCHER SICHERHEITSHINWEIS**

**⚠️ Der Entwicklermodus MUSS vor jeder Veröffentlichung deaktiviert werden!**
**⚠️ Apps im Entwicklermodus haben reduzierte Sicherheitsfeatures!**

## 📋 **Überblick**

Das Entwicklermodus-System bietet:
- ✅ Sichere Trennung zwischen Entwicklung und Produktion
- ✅ Automatische Sicherheitsprüfungen
- ✅ Deutliche UI-Warnungen im Entwicklermodus
- ✅ Build-Skripte mit Validierung
- ✅ Release-Checkliste

## 🔧 **Entwicklung**

### Entwicklungs-Build erstellen:
```bash
./build_dev.sh
```

**Features im Entwicklermodus:**
- 🔓 Keychain-Verschlüsselung deaktiviert (für einfache Tests)
- 📝 Debug-Logs aktiviert
- 📁 Erweiterte Datei-Zugriffe erlaubt
- 📱 Unverschlüsselte Backup-Importe möglich
- 🔒 Biometrie-Überprüfung übersprungen

### App mit Entwicklermodus starten:
```bash
# Nach build_dev.sh:
open "build/macos/Build/Products/Release/eingliederungshilfe_flutter.app"

# Oder direkt mit Logs:
"build/macos/Build/Products/Release/eingliederungshilfe_flutter.app/Contents/MacOS/eingliederungshilfe_flutter"
```

## 🚀 **Produktion**

### Produktions-Build erstellen:
```bash
./build_prod.sh
```

**Features im Produktions-Modus:**
- 🔒 Keychain-Verschlüsselung aktiviert
- 🚫 Debug-Logs deaktiviert
- 🔒 Sichere Datei-Zugriffe
- 🛡️ Vollständige Biometrie-Authentifizierung
- 🔐 Vollständige Verschlüsselung

### Automatische Sicherheitsprüfungen:
Das `build_prod.sh` Skript prüft automatisch:
- ❌ Entwicklermodus-Flags
- ❌ Temporäre Entwickler-Entitlements
- ✅ Code-Signierung
- ✅ Debug-Symbole

## 🎯 **UI-Elemente**

### 1. Warnung-Banner
- Erscheint oben in der App wenn Entwicklermodus aktiv
- Roter Hintergrund mit deutlicher Warnung
- Info-Button für Details

### 2. Startup-Dialog
- Wird beim App-Start im Entwicklermodus angezeigt
- Listet alle aktiven Entwickler-Features
- Muss bestätigt werden um fortzufahren

### 3. Entwickler-Info-Dialog
- Zeigt alle aktiven Entwickler-Features
- Sicherheits-Checkliste für Release
- Produktionsbereitschafts-Status

## 📊 **Sicherheits-Checkliste**

Die App überprüft automatisch:

| Check | Kritisch | Beschreibung |
|-------|----------|--------------|
| ❌ Entwicklermodus deaktiviert | 🔴 | Muss für Release deaktiviert sein |
| ❌ Keychain aktiviert | 🔴 | Verschlüsselung muss funktionieren |
| ❌ Debug-Logs deaktiviert | 🟡 | Keine Sicherheits-Logs in Produktion |
| ❌ Erweiterte Datei-Zugriffe entfernt | 🔴 | Keine Entwickler-Datei-Zugriffe |
| ❌ Biometrie aktiviert | 🔴 | Authentifizierung muss aktiv sein |
| ❌ Release-Build-Modus | 🔴 | Release-Build verwenden |

## 🔨 **Integration in bestehenden Code**

### Bestehende Services anpassen:

```dart
// Beispiel für SecureStorage Service:
import '../config/developer_mode.dart';

class SecureStorageService {
  Future<void> store(String key, String value) async {
    if (DeveloperMode.useKeychain) {
      // Normale Keychain-Speicherung
      await _secureStorage.write(key: key, value: value);
    } else {
      // Entwicklermodus: Unverschlüsselt speichern
      if (DeveloperMode.allowSecurityDebugLogs) {
        print('🔓 DEV: Speichere unverschlüsselt: $key');
      }
      // Temporäre Speicherung für Tests
      await _devStorage.write(key, value);
    }
  }
}
```

### UI-Integration:

```dart
// In main.dart oder App-Widget:
import 'widgets/developer_warning_banner.dart';

class MyApp extends StatelessWidget {
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Column(
        children: [
          const DeveloperWarningBanner(), // Warnung-Banner
          Expanded(
            child: YourMainWidget(),
          ),
        ],
      ),
    );
  }
}
```

## 🚨 **Release-Checkliste**

Vor jeder Veröffentlichung MUSS geprüft werden:

### ✅ **Code-Ebene:**
- [ ] Entwicklermodus-Flags entfernt
- [ ] `DEVELOPER_MODE=true` nicht in Build-Befehlen
- [ ] Keine Debug-Logs in kritischen Bereichen
- [ ] Alle temporären Workarounds entfernt

### ✅ **Build-Ebene:**
- [ ] `./build_prod.sh` verwendet (nicht `./build_dev.sh`)
- [ ] Sicherheitsprüfungen bestanden
- [ ] Code-Signierung validiert
- [ ] Release-Build erstellt

### ✅ **Entitlements:**
- [ ] Temporäre Entwickler-Entitlements entfernt
- [ ] Keychain-Zugriffe korrekt konfiguriert
- [ ] App Sandbox aktiviert
- [ ] Minimal erforderliche Berechtigungen

### ✅ **Funktional:**
- [ ] Keychain-Verschlüsselung funktioniert
- [ ] Biometrische Authentifizierung aktiv
- [ ] Sichere Datei-Zugriffe
- [ ] Keine Entwickler-UI-Elemente sichtbar

## 🔍 **Validierung**

### Automatische Prüfung:
```dart
// In der App:
if (!ProductionReadinessChecker.isProductionReady()) {
  print('❌ App ist nicht bereit für Veröffentlichung!');
  print(ProductionReadinessChecker.getReadinessReport());
}
```

### Manuelle Prüfung:
1. App starten - keine Entwickler-Warnungen sichtbar
2. Keychain-Funktionen testen
3. Biometrische Authentifizierung testen
4. Datei-Zugriffe testen (sollten sicher sein)

## 📁 **Datei-Struktur**

```
lib/
├── config/
│   └── developer_mode.dart          # Zentrale Konfiguration
├── widgets/
│   └── developer_warning_banner.dart # UI-Komponenten
└── services/
    └── *                            # Services mit DeveloperMode-Integration

build_dev.sh                         # Entwicklungs-Build
build_prod.sh                        # Produktions-Build
ENTWICKLERMODUS.md                   # Diese Dokumentation
```

## ⚙️ **Konfiguration**

### Entwicklermodus aktivieren:
```bash
# Option 1: Build-Parameter
flutter build --dart-define=DEVELOPER_MODE=true

# Option 2: Debug-Modus erlauben (nur für lokale Entwicklung)
flutter build --dart-define=ALLOW_DEBUG_DEV_MODE=true
```

### Produktions-Build:
```bash
# Ohne Flags = Produktions-Modus
flutter build macos --release
```

## 🆘 **Notfall-Checkliste**

**Falls versehentlich Entwickler-Build veröffentlicht:**

1. ⏹️ **Sofort stoppen** - Veröffentlichung zurückziehen
2. 🔍 **Schäden bewerten** - Welche Sicherheitsfeatures waren deaktiviert?
3. 🔧 **Korrigieren** - Produktions-Build erstellen
4. 📢 **Kommunizieren** - Betroffene Nutzer informieren falls nötig
5. 🔒 **Validieren** - Vollständige Sicherheitsprüfung

---

**⚠️ WICHTIG: Diese Dokumentation ist Teil des Sicherheitssystems und sollte regelmäßig überprüft werden!**