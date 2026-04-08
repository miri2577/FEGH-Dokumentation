# Changelog 2026-02-25 - Versionierung, Impressum & Quick-Action-Fix

## Version 0.1.0-alpha.1

### Umbenennung
- App-Titel von "Eingliederungshilfe" zu **FEGH-Dokumentation** geaendert
- Betrifft: MaterialApp title, Ladebildschirm, Willkommenstext, Hilfe-Screen

### Versionierung
- Version von `1.0.0+1` auf `0.1.0-alpha.1` gesetzt (semantisch korrekt fuer Pre-Release)
- pubspec.yaml description aktualisiert

### Impressum
- Settings > App-Informationen komplett ueberarbeitet:
  - App-Name: FEGH-Dokumentation
  - Version: 0.1.0-alpha.1
  - Entwickler: Mirko Richter
  - Copyright: 2025-2026 Mirko Richter. Alle Rechte vorbehalten.

### Quick-Action-Fix
- **"Neuer Klient" Quick-Action** im Dashboard navigiert jetzt direkt zu `CreateClientScreen()` statt zur Klientenliste
- **"Klient erstellen" Button** im Termin-Screen (wenn keine Klienten vorhanden) navigiert jetzt zu `CreateClientScreen()` statt nur `Navigator.pop()`

### Geaenderte Dateien
| Datei | Aenderung |
|-------|-----------|
| `pubspec.yaml` | Version + Description |
| `lib/main.dart` | App-Title + Ladetext |
| `lib/screens/home_screen.dart` | Quick-Action + Willkommenstext + Import |
| `lib/screens/create_appointment_screen.dart` | Klient-erstellen-Button + Import |
| `lib/screens/settings_screen.dart` | Impressum-Section |
| `lib/screens/hilfe_screen.dart` | App-Name-Referenzen |
