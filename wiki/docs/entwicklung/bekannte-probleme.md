# Bekannte Probleme

Stand: Version 0.2.0-beta.1 (April 2026)

## Architektur

### AppProvider als "God Object" (teilweise behoben)

Der zentrale `AppProvider` verwaltet alle App-Zustande in einer Datei (~1700 Zeilen). Spezialisierte Provider (`AuthProvider`, `ClientProvider`, `SettingsProvider`) sind erstellt und koennen schrittweise die einzelnen Screens uebernehmen.

**Status**: Provider erstellt, Migration der Screens laeuft.

### Grosse Quelldateien

| Datei | Groesse | Beschreibung |
|-------|---------|-------------|
| pdf_generator_service.dart | ~75 KB | PDF-Generierung mit 3 Varianten |
| settings_screen.dart | ~87 KB | Einstellungs-Screen mit vielen Sektionen |
| work_time_screen.dart | ~53 KB | Arbeitszeit-Screen |
| hidrive_webdav_client.dart | ~40 KB | WebDAV-Client |

## Sicherheit (behoben in 0.2.0-beta.1)

Die folgenden Sicherheitsprobleme wurden in Version 0.2.0-beta.1 behoben:

| Problem | Status | Fix |
|---------|:------:|-----|
| Unsicheres Passwort-Hashing (SHA256) | Behoben | PBKDF2 100k Iterationen |
| Developer-Mode immer aktiv im Debug | Behoben | Default auf false |
| MEK-Fallback `.dev_mek_UNSECURE` | Behoben | Komplett entfernt |
| Debug-Prints mit sensiblen Daten | Behoben | kDebugMode-Guard |
| Session-Timeout nicht erzwungen | Behoben | In isAuthenticated integriert |
| Leere Catch-Bloecke | Behoben | Logging hinzugefuegt |
| Cloud-Sync Race Conditions | Behoben | Await statt fire-and-forget |
| Decryption ohne Error-Handling | Behoben | Try-catch mit Fehlermeldung |
| Keine sichere Loeschung | Behoben | Ueberschreiben vor Loeschen |
| Android MANAGE_EXTERNAL_STORAGE | Behoben | maxSdkVersion=32 |

## Tests

### Testabdeckung (verbessert in 0.2.0-beta.1)

| Testdatei | Tests | Bereich |
|-----------|:-----:|---------|
| totp_service_test.dart | 12 | TOTP-Generierung, Verifikation, Base32 |
| permission_service_test.dart | 18 | Alle 5 Rollen, alle Berechtigungen |
| recovery_service_test.dart | 9 | Recovery-Key, Token, Verschluesselung |
| password_hashing_test.dart | 8 | PBKDF2, Salt, Migration |
| widget_test.dart | 1 | Smoke-Test |
| pdf_fields_test.dart | 1 | PDF-Formularfelder |
| **Gesamt** | **49** | |

**Noch fehlend**: Integration-Tests fuer Cloud-Sync, Backup/Restore, GDPR-Loeschung.

## Plattform

### Web-Einschraenkungen

- `FlutterSecureStorage` funktioniert auf Web nur eingeschraenkt
- Biometrische Authentifizierung nicht verfuegbar
- Certificate Pinning nicht moeglich (Browser-Kontrolle)
- **Warnung wird beim Start angezeigt** (seit 0.2.0-beta.1)

### iOS Build nur auf macOS

Flutter kann iOS-Apps nicht auf Windows oder Linux kompilieren. Ein Mac mit Xcode ist fuer iOS-Builds erforderlich.

### Video Calls

Video-/Audio-Anrufe sind im Chat als Buttons vorhanden, nutzen aber aktuell Element Web als Fallback. Native WebRTC-Integration ist geplant.

## Veraltete APIs

Einige Stellen verwenden veraltete Flutter-APIs wie `withOpacity()` (statt `withValues(alpha:)`). Diese werden schrittweise migriert.
