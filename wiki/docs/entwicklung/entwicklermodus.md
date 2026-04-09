# Entwicklermodus

## Aktivierung

Der Entwicklermodus wird ueber Build-Parameter gesteuert:

```bash
# Explizit aktivieren
flutter run --dart-define=DEVELOPER_MODE=true

# Im Debug-Modus (kDebugMode) automatisch aktiv
flutter run    # Aktiviert durch allowDebugModeActivation
```

## Auswirkungen

| Feature | Entwicklermodus | Produktion |
|---------|:--------------:|:----------:|
| Keychain-Verschluesselung | Deaktiviert | Aktiviert |
| Debug-Logs fuer Sicherheit | Aktiviert | Deaktiviert |
| Erweiterte Datei-Zugriffe | Aktiviert | Deaktiviert |
| Unverschluesselte Backups | Erlaubt | Verboten |
| Biometrie-Check | Uebersprungen | Aktiv |
| Warnungs-Banner in UI | Sichtbar | Versteckt |

## Produktionsreife-Checkliste

Die Klasse `ProductionReadinessChecker` prueft vor Release:

| Check | Level | Beschreibung |
|-------|-------|-------------|
| Entwicklermodus deaktiviert | Kritisch | DEVELOPER_MODE darf nicht gesetzt sein |
| Keychain aktiviert | Kritisch | Sichere Schluesselspeicherung |
| Debug-Logs deaktiviert | Wichtig | Keine Sicherheits-Logs in Produktion |
| Erweiterte Datei-Zugriffe entfernt | Kritisch | Kein Entwickler-Dateizugriff |
| Biometrie aktiv | Kritisch | Authentifizierung nicht ueberspringbar |
| Release-Build | Kritisch | kReleaseMode muss true sein |

## Build-Skripte

### build_dev.sh (Entwicklung)
- Flutter clean + pub get
- Build mit `DEVELOPER_MODE=true`
- Keychain deaktiviert
- Debug-Logs aktiviert
- Code-Signierung fuer lokale Entwicklung

### build_prod.sh (Produktion)
- Prueft dass DEVELOPER_MODE **nicht** gesetzt ist
- Scannt nach temporaeren Entwickler-Entitlements
- Flutter clean + pub get
- Release-Build
- Validiert Code-Signierung
- Prueft auf Debug-Symbole
- Fuehrt Sicherheitsvalidierung durch
