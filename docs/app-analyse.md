# App-Analyse: Eingliederungshilfe Flutter

*Erstellt: 2026-02-21*

## Gesamteindruck

Funktional umfangreiche Fach-App (20 Screens, 18 Services, 15 Models) mit professioneller Sicherheitsarchitektur (AES-256-GCM Envelope Encryption, TLS-Pinning, Jailbreak Detection, DSGVO-Compliance). HiDrive-WebDAV-Sync mit UUID-Dateinamen und verschluesseltem Manifest ist durchdacht.

---

## Staerken

1. **Sicherheit**: Mehrschichtige Verschluesselung, biometrische Auth, DSGVO-Compliance
2. **Plattform-Abdeckung**: Mobile, Tablet, Desktop, Web mit adaptiver Navigation
3. **Fachliche Tiefe**: TIB-Ziele, ICF-Bereiche, Informationsbericht (137 Berliner Amtsformular-Felder)
4. **Dokumentation**: Architektur, DSGVO, Deployment, Entwicklermodus

---

## Probleme & Massnahmen

### 1. KRITISCH: God-Provider (AppProvider = 1242 Zeilen)

AppProvider verwaltet alles: Auth, Clients, Appointments, Arbeitszeiten, Mitarbeiter, FreizeitAntraege, Settings, Speech, Messages. Jeder notifyListeners() rebuildet die gesamte App.

**Massnahme**: Provider aufteilen:
- `AuthProvider`
- `ClientProvider`
- `AppointmentProvider`
- `SettingsProvider`

**Status**: [ ] Offen

### 2. KRITISCH: Kaum Tests (3 Dateien, nur Smoke-Tests)

Kein Test fuer Encryption/Decryption, Backup-Restore, GDPR-Loeschung.

**Mindest-Tests**:
- CryptoStorage: Encrypt → Decrypt Roundtrip
- SecureStorageService: CRUD-Operationen
- AppSettings: Serialisierung nach neuen Feldern
- Backup: Export → Import Integritaet

**Status**: [ ] Offen

### 3. KRITISCH: TODO in sicherheitskritischem Code

- `crypto_storage.dart:133` - "VOR PRODUKTIONS-RELEASE ENTFERNEN!" (Dev-MEK-Fallback)
- `message_service.dart` - E2E-Verschluesselung nicht implementiert
- `settings_screen.dart` - Passwort-Aenderung + Backup-Restore fehlen
- `appointment_detail_screen.dart` - Export nicht implementiert

**Status**: [ ] Offen

### 4. HOCH: Keine Navigation-Struktur

Alle Uebergaenge per direktem Navigator.push(MaterialPageRoute(...)). Kein Deep-Linking, erschwert Testing.

**Massnahme**: GoRouter oder Named Routes einfuehren.

**Status**: [ ] Offen

### 5. HOCH: Riesen-Dateien

| Datei | Groesse |
|-------|---------|
| pdf_generator_service.dart | 75KB |
| settings_screen.dart | 60KB |
| work_time_screen.dart | 53KB |
| informationsbericht_screen.dart | 42KB |
| hidrive_webdav_client.dart | 40KB |
| create_appointment_screen.dart | 39KB |

**Massnahme**: In kleinere Widgets/Klassen aufteilen.

**Status**: [ ] Offen

### 6. MITTEL: Inkonsistente Fehlerbehandlung

Manche Fehler print()-geloggt und verschluckt, manche SnackBar, manche in _error. Kein zentraler Error-Handler.

**Status**: [ ] Offen

### 7. MITTEL: Dead Code & Unused Imports

- `_saveMitarbeiter()` nie aufgerufen
- `_saveFreizeitAntraege()` nie aufgerufen
- `_showBackupDialog()`, `_showRestoreDialog()`, `_handleBackupAction()` in settings_screen
- Unused import in messages_screen

**Status**: [ ] Offen

### 8. MITTEL: Deprecated APIs

- `withOpacity()` → `withValues(alpha: ...)`
- Radio groupValue/onChanged → RadioGroup

**Status**: [ ] Offen

### 9. NIEDRIG: Dokumentation veraltet

- GDPR_IMPLEMENTATION_STATUS.md - Letzte Aktualisierung 2025-09-16
- Checklisten fast komplett unchecked
- TLS-Pinning als "geplant" markiert, obwohl implementiert

**Status**: [ ] Offen

---

## Fehlende Features

| Feature | Prioritaet |
|---------|------------|
| Unit/Widget Tests | Kritisch |
| Zentraler Error Logging Service | Hoch |
| Offline-Sync-Konflikterkennung | Hoch |
| Passwort aendern (Web) | Hoch |
| Backup Restore (lokal) | Hoch |
| Periodische Sync | Mittel |
| In-App-Hilfe-Tooltips | Mittel |
| CI/CD Pipeline | Mittel |
| Automatischer Backup-Zeitplan | Mittel |
| Globale Suche ueber alle Entitaeten | Niedrig |
| Pagination fuer grosse Listen | Niedrig |

---

## Performance (siehe docs/performance-optimierungen.md)

1. Debouncing (schnellster Effekt)
2. Optimistisches UI-Update
3. Selectors statt Consumer
4. Provider aufteilen
