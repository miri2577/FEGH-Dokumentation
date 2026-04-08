# Code-Analyse Bericht: Eingliederungshilfe Flutter App

**Datum:** 2026-02-20
**Flutter-Version:** 3.35.3 (Dart 3.9.2)
**Analysiert von:** Claude Code (Opus 4.6)

---

## 1. Build-Status

| Plattform | Ergebnis | Details |
|-----------|----------|---------|
| **Android (APK)** | Kompiliert erfolgreich | Debug-Build in ~95s |
| **iOS** | Kompiliert erfolgreich | Release-Build ohne Codesigning, 44.5MB |
| **Flutter-Version** | 3.35.3 (stabil) | 6 Monate alt, Update verfuegbar |

Die Haupt-App kompiliert fehlerfrei auf beiden Zielplattformen (iOS und Android).
Die Personalverwaltung hat Compile-Errors im Shift-Modul (siehe Abschnitt 2).

---

## 2. Statische Analyse

### Zusammenfassung

| Kategorie | Haupt-App | Personalverwaltung | Gesamt |
|-----------|-----------|-------------------|--------|
| **Errors** | 3 | 35 | 38 |
| **Warnings** | ~30 | ~127 | ~157 |
| **Infos** | ~400 | ~450 | ~850+ |

### 2.1 Fehler in der Haupt-App (3 Stueck)

Alle 3 Fehler befinden sich in `lib/screens/calendar_screen_simple.dart`:

| Fehler | Zeile | Beschreibung |
|--------|-------|--------------|
| `undefined_method` | 37 | `getAppointmentsForDay` existiert nicht in `AppProvider` |
| `undefined_method` | 54 | `AdaptiveScaffold` nicht definiert |
| `undefined_getter` | 111 | `title` Getter fehlt auf `Appointment` |

**Ursache:** `calendar_screen_simple.dart` ist eine verwaiste Datei. Es existiert bereits die vollstaendige `calendar_screen.dart`. Die simple-Variante wird nirgends importiert oder verwendet.

**Empfehlung:** Datei `calendar_screen_simple.dart` loeschen.

### 2.2 Fehler in der Personalverwaltung (35 Stueck)

Fast alle Fehler konzentrieren sich auf das Shift-Modul:

| Datei | Fehleranzahl | Ursache |
|-------|-------------|---------|
| `features/shifts/widgets/bulk_shift_dialog.dart` | ~12 | Shift-Model geaendert, UI nicht angepasst |
| `features/shifts/widgets/shift_calendar_widget.dart` | ~18 | Fehlende required-Parameter, umbenannte Felder |
| `features/shifts/shift_planning_screen.dart` | 1 | `shiftType` Getter fehlt |

**Konkrete Probleme:**
- `ShiftType.morning` existiert nicht mehr als Enum-Wert
- `shiftType` Getter wurde entfernt/umbenannt im Shift-Model
- `Employee`-Konstruktor hat neue required-Parameter (`address`, `contractType`, `createdAt`, `dateOfBirth`, `employeeNumber`, `hoursPerWeek`, `updatedAt`)
- `contractualHours` wurde in einen anderen Parameter umbenannt
- `ColorScheme.warningContainer` / `onWarningContainer` existieren nicht in der aktuellen Flutter-Version

**Empfehlung:** Shift-Model und zugehoerige Widgets synchronisieren oder das Shift-Feature temporaer deaktivieren.

### 2.3 Wichtige Warnings in der Haupt-App

| Warning | Datei | Beschreibung |
|---------|-------|--------------|
| `unused_element` | `app_provider.dart:467` | `_saveMitarbeiter()` wird nie aufgerufen |
| `unused_element` | `app_provider.dart:485` | `_saveFreizeitAntraege()` wird nie aufgerufen |
| `unused_element` | `settings_screen.dart:520` | `_showBackupDialog()` wird nie aufgerufen |
| `unused_element` | `settings_screen.dart:588` | `_showRestoreDialog()` wird nie aufgerufen |
| `unused_element` | `settings_screen.dart:869` | `_handleBackupAction()` wird nie aufgerufen |
| `unused_element` | `settings_screen.dart:1352` | `_openBackupFolder()` wird nie aufgerufen |
| `unused_element` | `hidrive_webdav_client.dart:1071` | `_calculateFileHash()` wird nie aufgerufen |
| `unused_element` | `crypto_storage.dart:397` | `_getWebStorageKeys()` wird nie aufgerufen |
| `unused_element` | `export_service.dart:147` | `_mapToMimeType()` wird nie aufgerufen |
| `unused_element` | `web_auth_service.dart:35` | `_checkPasswordSet()` wird nie aufgerufen |
| `unused_element` | `secure_storage_service.dart:1019` | `_schemaToOrgDataType()` wird nie aufgerufen |
| `unused_import` | `home_screen.dart:10` | `developer_warning_banner.dart` importiert aber nicht genutzt |
| `unused_import` | `home_screen.dart:21` | `mitarbeiter_screen.dart` importiert aber nicht genutzt |
| `unused_import` | `messages_screen.dart:2` | `provider` importiert aber nicht genutzt |
| `unused_import` | `settings_screen.dart:17` | `responsive_utils.dart` importiert aber nicht genutzt |
| `unused_field` | `calendar_screen.dart:39` | `_calendarFormat` gesetzt aber nie gelesen |
| `unused_field` | `work_time_screen.dart:22` | `_description` gesetzt aber nie gelesen |
| `unused_field` | `auth_screen.dart:24` | `_isSettingPassword` gesetzt aber nie gelesen |
| `unused_field` | `hidrive_webdav_client.dart:550,553` | `_username`, `_rootSubdirectory` nie gelesen |
| `dead_code` | `settings_screen.dart:1460` | Toter Code-Pfad |
| `invalid_null_aware_operator` | `app_provider.dart:803-804` | Unnoetiger `?.` Operator |

### 2.4 Haeufige Info-Meldungen

| Info-Typ | Anzahl (ca.) | Beschreibung |
|----------|-------------|--------------|
| `avoid_print` | ~600+ | `print()` Aufrufe in Produktionscode |
| `deprecated_member_use` | ~80+ | `withOpacity` → `withValues()`, `value` → `initialValue` |
| `use_build_context_synchronously` | ~30+ | BuildContext nach `await` verwendet |
| `unnecessary_brace_in_string_interps` | ~20+ | Unnoetige `${}` statt `$variable` |
| `prefer_const_constructors` | ~50+ | `const` moeglich aber nicht genutzt |

---

## 3. Architektur-Einschaetzung

### 3.1 Staerken

**Projektstruktur:**
- Saubere Trennung in Models, Services, Providers, Screens, Widgets
- Provider-basiertes State Management (solide und bewaehrte Wahl fuer diese App-Groesse)
- Plattform-Abstraktion ueber `PlatformUtils` fuer Web/Mobile/Desktop
- JSON-Serialisierung mit `json_serializable` + Code Generation
- Responsive Design mit `ResponsiveFramework` und `AdaptiveNavigation`
- Lokalisierung fuer Deutsch konfiguriert (Material, Cupertino, Widgets)

**Verschluesselungsarchitektur:**
- Envelope Encryption (DEK/MEK) architektonisch gut durchdacht
- AES-256-GCM mit authentifizierten Zusatzdaten (AAD)
- UUID-basierte Dateinamen verhindern PHI-Leaks in Metadaten
- Hierarchisches Schluesselmodell: K_org → K_team → DEK
- PBKDF2 (100k HMAC-SHA256 Runden) fuer MEK-Ableitung

**Developer-Mode-System:**
- Build-Parameter-gesteuert (`--dart-define=DEVELOPER_MODE=true`)
- Zentrale Konfiguration in `developer_mode.dart`
- Automatische Production-Readiness-Checkliste
- Visueller Warn-Banner bei aktivem Dev-Mode
- Separate Build-Skripte (`build_dev.sh` / `build_prod.sh`)

**Multi-App-Oekosystem:**
- Einheitliche HiDrive-Ordnerstruktur fuer Mobile-App und Personalverwaltung
- Team-Key-Provisionierung per QR-Code
- Bidirektionaler Sync ueber WebDAV

### 3.2 Schwaechen

**AppProvider als God-Object (~1220 Zeilen):**
```
Aktuell in AppProvider vereint:
- Authentifizierung (Biometrie, Web-Auth, Passcode)
- Klientenverwaltung (CRUD, Suche)
- Terminverwaltung (CRUD, Suche, Statistiken)
- Arbeitszeiterfassung (CRUD, Statistiken)
- Mitarbeiterverwaltung (CRUD, Suche, Mockup-Daten)
- Freizeit-Antraege (CRUD, Suche)
- Settings-Verwaltung
- Spracheingabe (Speech-to-Text)
- Nachrichten-System
- Export/Import
- Stundenverbrauch-Tracking
- Benutzerprofil
- E-Mail-Ziele
```

**Empfehlung:** Aufteilung in spezialisierte Provider:
- `AuthProvider` - Authentifizierung
- `ClientProvider` - Klientenverwaltung
- `AppointmentProvider` - Terminverwaltung
- `WorkTimeProvider` - Arbeitszeiterfassung
- `SettingsProvider` - Einstellungen
- `MessageProvider` - Nachrichten
- `SyncProvider` - Cloud-Synchronisation

**Mockup-Daten im Produktionscode:**
```dart
// app_provider.dart:382-465
List<Mitarbeiter> _createMockupMitarbeiter() {
  return [
    Mitarbeiter.create(name: 'Mueller', vorname: 'Anna', ...),
    Mitarbeiter.create(name: 'Schmidt', vorname: 'Thomas', ...),
    // ... 10 hart codierte Test-Mitarbeiter
  ];
}
```
Diese Mockup-Daten werden bei leerem Datensatz erstellt und gespeichert. Das gehoert nicht in Produktionscode und sollte entfernt oder hinter den Developer-Mode gestellt werden.

**BuildContext nach async gaps:**
```dart
// Beispiel aus settings_screen.dart
await someAsyncOperation();
Navigator.of(context).pop();  // GEFAEHRLICH: Widget koennte disposed sein
```
Kann zu Runtime-Crashes fuehren wenn der Widget-Tree sich waehrend des `await` aendert. Betroffen: `settings_screen.dart`, `export_screen.dart`, weitere Screens.

**deleteAllData() doppelt vorhanden:**
- `clearAllData()` (Zeile 1080): Funktional korrekt, loescht Storage + Memory
- `deleteAllData()` (Zeile 1197): Loescht nur Memory, nicht Storage - TODO-Kommentar vorhanden

---

## 4. Sicherheitseinschaetzung

### 4.1 Gut umgesetzt

| Feature | Status | Details |
|---------|--------|---------|
| AES-256-GCM Verschluesselung | Implementiert | Envelope Encryption mit DEK/MEK |
| Hardware Keychain Integration | Implementiert | Secure Storage, mit Dev-Mode Fallback |
| Root/Jailbreak-Erkennung | Implementiert | App wechselt in Read-Only Modus |
| Screenshot-Schutz | Implementiert | FLAG_SECURE (Android), Blur (iOS) |
| Crypto-Erasure | Implementiert | DSGVO Art. 17 konform |
| UUID-basierte Dateinamen | Implementiert | Keine PHI in Metadaten |
| Biometrische Authentifizierung | Implementiert | Mit plattformspezifischem Fallback |
| Production-Readiness-Checker | Implementiert | Automatische Sicherheits-Validierung |

### 4.2 Kritische offene Punkte

**1. allowDebugModeActivation (defaultValue: true):**
```dart
// developer_mode.dart:12
static const bool allowDebugModeActivation =
    bool.fromEnvironment('ALLOW_DEBUG_DEV_MODE', defaultValue: true);
```
Jeder Debug-Build aktiviert automatisch den Dev-Mode. Das ist fuer Entwicklung praktisch, aber es muss sichergestellt sein, dass nur Release-Builds ausgeliefert werden. Ein versehentlicher Debug-Build in Produktion wuerde alle Sicherheitsfeatures deaktivieren.

**2. TLS Certificate Pinning - Ungueltiger Emergency Pin:**
```dart
// hidrive_webdav_client.dart
'sha256/47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU='  // Emergency Backup Pin
```
Dieser Hash ist der SHA-256 eines **leeren Inputs** (`echo -n "" | sha256sum`). Das ist kein gueltiger Zertifikats-Pin und koennte als Sicherheitsluecke interpretiert werden. Sollte durch einen echten Backup-Pin ersetzt werden.

**3. HiDrive-Authentifizierung:**
```dart
// Aktuell: Basic Auth mit Base64
'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}'
```
Basic Auth ist funktional, aber fuer Produktion waere OAuth2 sicherer. Credentials werden bei jedem Request im Header mitgesendet.

**4. print()-Statements mit sensiblen Daten:**
Einige `print()`-Aufrufe koennten sensible Informationen in Logdateien schreiben. In Produktion sollten alle Debug-Prints entfernt oder durch den bestehenden `FileLogger` mit Log-Level-Steuerung ersetzt werden.

**5. `.dev_mek_UNSECURE` Fallback-Datei:**
Im Developer-Mode wird der MEK in einer lokalen Datei `.dev_mek_UNSECURE` gespeichert. Diese Datei darf niemals in Produktion existieren. Der Production-Readiness-Checker prueft dies, aber eine zusaetzliche Absicherung waere sinnvoll.

---

## 5. Dependency-Status

### 5.1 Kritische Befunde

| Paket | Installiert | Verfuegbar | Problem |
|-------|------------|-----------|---------|
| `flutter_adaptive_scaffold` | 0.1.12 | - | **DISCONTINUED** - Paket wird nicht mehr gepflegt |
| `mobile_scanner` | 3.5.7 | 7.2.0 | Major-Update, Breaking Changes wahrscheinlich |
| `flutter_secure_storage` | 9.2.4 | 10.0.0 | Security-relevantes Paket, Major-Update verfuegbar |
| `local_auth` | 2.3.0 | 3.0.0 | Authentifizierungs-Paket, Major-Update verfuegbar |
| `file_picker` | 8.3.7 | 10.3.10 | 2 Major-Versionen zurueck |
| `permission_handler` | 11.4.0 | 12.0.1 | Major-Update verfuegbar |

### 5.2 Gesamt-Statistik

- **1 Paket discontinued** (`flutter_adaptive_scaffold`)
- **69 Pakete mit neueren, inkompatiblen Versionen**
- Flutter SDK Constraint: `^3.9.2` (aktuell, aber neue Flutter-Version verfuegbar)
- `pubspec.lock` ist vorhanden (Dependency-Pinning funktioniert)

### 5.3 Empfehlungen

1. `flutter_adaptive_scaffold` durch offizielle Alternative ersetzen (z.B. eigene adaptive Layout-Loesung oder `flutter_adaptive_navigation`)
2. Security-relevante Pakete priorisiert updaten: `flutter_secure_storage`, `local_auth`, `crypto`
3. `mobile_scanner` Update planen (QR-Scanner fuer Team-Key-Provisionierung)
4. Flutter SDK selbst updaten (`flutter upgrade`)

---

## 6. Entwicklungsstand

### 6.1 Feature-Reifegrad

| Bereich | Reifegrad | Status | Anmerkungen |
|---------|-----------|--------|-------------|
| Klientenverwaltung | 90% | Funktional | CRUD komplett, Suche, alphabetische Sortierung |
| Terminverwaltung | 85% | Funktional | Kalender, Wochenansicht, Ueberschneidungen |
| Arbeitszeiterfassung | 80% | Funktional | Automatische Erstellung aus Terminen |
| Stundenverbrauch-Tracking | 85% | Funktional | Ampelsystem (gruen/gelb/rot) |
| Backup/Restore | 75% | Funktional | Export, Import, Teilen implementiert |
| PDF-Export | 75% | Funktional | Verschiedene Exportformate |
| Verschluesselung | 75% | Basis steht | E2E-Tests fehlen, Key-Rotation Basis vorhanden |
| HiDrive Cloud-Sync | 60% | In Entwicklung | WebDAV-Client da, echte Tests ausstehend |
| Nachrichten-System | 40% | Teils Stub | UI vorhanden, E2E-Verschluesselung nur Fallback |
| RBAC/Rollensystem | 30% | Konzeptphase | Roadmap steht, wenig implementiert |
| QR-Provisionierung | 70% | Funktional | Scan und Import funktioniert |
| DSGVO-Compliance | 65% | Teilweise | Export/Loeschung implementiert, Audit-Trail Basis |
| Personalverwaltung | 65% | In Entwicklung | Viel UI, Shift-Modul defekt |
| Automatisierte Tests | 5% | Kaum vorhanden | Nahezu keine Unit-/Widget-Tests |
| Produktionsreife | 40% | In Arbeit | Checkliste existiert, vieles offen |

### 6.2 Plattform-Unterstuetzung

| Plattform | Build | Getestet | Status |
|-----------|-------|----------|--------|
| Android | Kompiliert | Unbekannt | Bereit fuer Tests |
| iOS | Kompiliert | Unbekannt | Codesigning noetig fuer Device |
| macOS | Kompiliert (lt. Doku) | Ja (Entwicklung) | Hauptentwicklungsplattform |
| Web | Konfiguriert | Teilweise | Web-Auth-Service vorhanden |
| Windows | Konfiguriert | Unbekannt | Plattform-Ordner vorhanden |
| Linux | Konfiguriert | Unbekannt | Plattform-Ordner vorhanden |

### 6.3 Dokumentation

Die Dokumentation ist umfangreich (31 MD-Dateien) und deckt ab:
- Architektur und Verschluesselungskonzept
- DSGVO/GDPR-Implementierungsstatus
- HiDrive-Integration und Ordnerstruktur
- Multi-User/Multi-Team-Architektur
- Roadmap und naechste Schritte
- Produktionsreife-Checkliste
- Entwicklermodus-Dokumentation
- QR-Provisionierung
- Incident-Runbook

**Anmerkung:** Einige Dokumente widersprechen sich in Fortschrittsindikatoren (z.B. Phase 1 gleichzeitig als "0%" und "ABGESCHLOSSEN" markiert in `PRODUKTIONSREIFE_PHASE1_FORTSCHRITT.md`). Eine Bereinigung der Dokumentation waere hilfreich.

---

## 7. Top-Verbesserungsvorschlaege (priorisiert)

### Prioritaet: KRITISCH (sofort beheben)

| # | Massnahme | Aufwand | Auswirkung |
|---|-----------|---------|------------|
| 1 | `calendar_screen_simple.dart` loeschen | 1 Min | Entfernt 3 Compile-Errors |
| 2 | Shift-Model/Widgets in Personalverwaltung synchronisieren | 2-4h | Entfernt 35 Compile-Errors |
| 3 | `use_build_context_synchronously` fixen | 2-3h | Verhindert potenzielle Runtime-Crashes |
| 4 | Emergency Backup Pin im TLS-Pinning korrigieren | 30 Min | Schliesst Sicherheitsluecke |

### Prioritaet: HOCH (vor Produktion)

| # | Massnahme | Aufwand | Auswirkung |
|---|-----------|---------|------------|
| 5 | Mockup-Daten entfernen/hinter Dev-Mode stellen | 30 Min | Keine Fake-Daten in Produktion |
| 6 | AppProvider aufteilen (God-Object) | 4-8h | Bessere Wartbarkeit, weniger Bugs |
| 7 | `flutter_adaptive_scaffold` ersetzen | 2-3h | Discontinued Package entfernen |
| 8 | Ungenutzten Code aufraeumen (~15 Methoden) | 1-2h | Sauberere Codebasis |
| 9 | `deleteAllData()` Duplikat bereinigen | 30 Min | Konsistentes Verhalten |
| 10 | Security-Dependencies updaten | 2-4h | Aktuelle Sicherheits-Patches |

### Prioritaet: MITTEL (fuer Qualitaet)

| # | Massnahme | Aufwand | Auswirkung |
|---|-----------|---------|------------|
| 11 | `print()` durch FileLogger ersetzen | 4-8h | Strukturiertes Logging, keine PHI in Logs |
| 12 | `withOpacity` → `withValues()` migrieren | 1-2h | Deprecation-Warnings entfernen |
| 13 | Automatisierte Tests schreiben | 20-40h | Regressionssicherheit |
| 14 | Flutter-Version aktualisieren | 1-2h | Neueste Bugfixes und Features |
| 15 | Alle Dependencies aktualisieren | 4-8h | Sicherheit und Kompatibilitaet |
| 16 | Dokumentation bereinigen (Widersprueche) | 2-3h | Klarheit ueber aktuellen Stand |

### Prioritaet: NIEDRIG (Nice-to-have)

| # | Massnahme | Aufwand | Auswirkung |
|---|-----------|---------|------------|
| 17 | `const` Constructors hinzufuegen | 1-2h | Minimale Performance-Verbesserung |
| 18 | Unnoetige String-Interpolation bereinigen | 30 Min | Code-Sauberkeit |
| 19 | Unused Imports entfernen | 30 Min | Code-Sauberkeit |
| 20 | Bundle-Identifier von `com.example` aendern | 30 Min | Noetig fuer App-Store-Release |

---

## Gesamtfazit

Die Eingliederungshilfe Flutter App hat eine **solide Grundarchitektur** und zeigt einen durchdachten Ansatz bei Verschluesselung und Datenschutz. Die App kompiliert fehlerfrei fuer iOS und Android. Das Verschluesselungskonzept (Envelope Encryption, hierarchische Schluessel, Crypto-Erasure) ist professionell konzipiert.

**Staerken:**
- Durchdachte Sicherheitsarchitektur
- Saubere Projektstruktur
- Umfangreiche Dokumentation und klare Roadmap
- Funktionale Kernfeatures (Klienten, Termine, Arbeitszeit)
- Cross-Platform Build funktioniert

**Hauptrisiken fuer Produktion:**
- Fehlende automatisierte Tests
- AppProvider als God-Object (Wartbarkeitsrisiko)
- Veraltete Dependencies (insbesondere Security-Pakete)
- HiDrive-Integration noch nicht mit echten Credentials getestet
- Personalverwaltung Shift-Modul nicht kompilierbar

**Empfohlene naechste Schritte:**
1. Die 4 kritischen Punkte sofort beheben (< 1 Tag Aufwand)
2. Die 6 hohen Prioritaeten vor einem Beta-Release angehen
3. Testabdeckung schrittweise aufbauen
4. HiDrive-Integration mit echten Credentials validieren
