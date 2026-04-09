# Bekannte Probleme

Basierend auf der Code-Analyse (Stand: April 2026).

## Architektur

### AppProvider als "God Object"

Der zentrale `AppProvider` verwaltet alle App-Zustande in einer Datei (~1700 Zeilen). Dies betrifft Authentifizierung, Klienten, Termine, Arbeitszeiten, Mitarbeiter, Urlaub, Einstellungen, Sprache und Nachrichten.

**Empfehlung**: Aufteilen in spezialisierte Provider (AuthProvider, ClientProvider, AppointmentProvider, SettingsProvider).

### Grosse Quelldateien

| Datei | Groesse | Beschreibung |
|-------|---------|-------------|
| pdf_generator_service.dart | ~75 KB | PDF-Generierung mit 3 Varianten |
| settings_screen.dart | ~87 KB | Einstellungs-Screen mit vielen Sektionen |
| work_time_screen.dart | ~53 KB | Arbeitszeit-Screen |
| hidrive_webdav_client.dart | ~40 KB | WebDAV-Client |

## Sicherheit

### Entwickler-MEK-Fallback

In `crypto_storage.dart` existiert ein Entwickler-Fallback fuer den MEK wenn der Keychain nicht verfuegbar ist. Dieser muss vor einem Produktions-Release entfernt oder abgesichert werden.

### Nachrichten-Verschluesselung

Die End-to-End-Verschluesselung fuer das Nachrichtensystem ist nicht vollstaendig implementiert. Nachrichten werden aktuell mit dem Team-Key verschluesselt, nicht mit individuellen Schluesselpaaren.

## Tests

### Minimale Testabdeckung

Aktuell existieren nur 3 Testdateien:

- `widget_test.dart` -- Basis-Smoke-Test
- `pdf_fields_test.dart` -- PDF-Formularfeld-Extraktion
- `pdf_debug_test.dart` -- PDF-Debug-Utilities

**Fehlend**: Unit-Tests fuer Verschluesselung, Backup/Restore, DSGVO-Loeschung, TOTP-Verifikation, Berechtigungspruefung.

## Code-Qualitaet

### Inkonsistente Fehlerbehandlung

Fehler werden uneinheitlich behandelt: `print()`, `SnackBar`, `_error`-Feld im Provider, und direkte Exception-Weitergabe existieren nebeneinander. Kein zentraler Error-Handler.

### Veraltete APIs

Einige Stellen verwenden veraltete Flutter-APIs wie `withOpacity()` (statt `withValues(alpha:)`).

### Nicht verwendeter Code

Mehrere Methoden und Imports sind nicht in Verwendung und koennten entfernt werden.

## Plattform

### Web-Einschraenkungen

- `FlutterSecureStorage` funktioniert auf Web nur eingeschraenkt
- Biometrische Authentifizierung nicht verfuegbar
- Certificate Pinning nicht moeglich (Browser-Kontrolle)
- `_secureDataDir` nicht verfuegbar (Fehler beim Speichern)

### iOS Build nur auf macOS

Flutter kann iOS-Apps nicht auf Windows oder Linux kompilieren. Ein Mac mit Xcode ist fuer iOS-Builds erforderlich.
