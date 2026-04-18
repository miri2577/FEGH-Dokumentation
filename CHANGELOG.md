# CHANGELOG

Dieses Changelog folgt [Keep a Changelog](https://keepachangelog.com/de/1.1.0/)
und nutzt [Semantic Versioning](https://semver.org/lang/de/).

## [1.0.0-beta.1] - 2026-04-18

Erster Beta-Release mit vollstaendiger Rechnungs-Compliance fuer
Berliner Eingliederungshilfe-Traeger.

### Hinzugefuegt

- **Rechnungsmodul (§14 UStG + XRechnung 3.0)**: UBL-2.1-XML mit
  Leitweg-ID, VATEX-DE-Codes, Einrichtungs-IK, Steuerbefreiung nach
  §4 Nr. 16h/25/18 UStG waehlbar
- **Monatslauf-Automatik**: Ein-Klick-Rechnungserstellung fuer alle
  Kostentraeger im letzten Monat mit Review-Dialog
- **Storno-Rechnung**: negative Positionen, -ST-Suffix, automatischer
  Status-Wechsel
- **Rechnungssteller-Settings**: 12 Pflichtfelder fuer §14 UStG mit
  Status-Badge
- **Fallnummer-Liste**: pro Klient individuelle Aktenzeichen pro
  Kostentraeger (Multi-Kostentraeger-Szenario)
- **Bewilligungsbescheid- und Leistungstyp-Referenzen** in Klienten-
  Stammdaten
- **Audit-Log-Eintraege** fuer Rechnungen (Create, Status, Storno,
  XML-Export) nach DSGVO Art. 5 Abs. 2
- **OZG-RE-Einreichungs-Hinweis** nach XML-Export
- **Plausi-Check** vor Rechnungserstellung (hart: Leitweg-ID,
  Aktenzeichen; weich: Geburtsdatum, Leistungstyp, Bewilligungsref,
  Budget)
- **Budget-Warnung** beim Termin-Speichern (>=90% Gelb, >=100% Rot)
- **FLS-Intervall-Budget**: Verbrauch pro aktuellem Zeitraum statt
  kumulativ
- **Informationsbericht**: Formular 101 Berlin mit 10 Teilhabeziel-
  Slots, "Aus Wirkungsmessung uebernehmen" (GAS->Zielerreichung)
- **Wiki-Erweiterungen**: Fachleistungsstunden-Guide,
  Rechnungssteller-Settings, Fallnummer-Liste, Monatslauf, Audit-Log
- **Hilfe-Screen**: 12 neue Feature-Items im FLS-Bereich

### Geaendert

- **Kalkulationsfaktor** explizit als "nur informativ" markiert
  (Doppelberechnung-Schutz); Methode in
  `getGesamtarbeitsstundenInformativ` umbenannt
- **XRechnung-Tax-Category** von "Z" (Zero) auf "E" (Exempt) fuer
  §4-UStG-Befreiung
- **TerminArten** klassifiziert nach `istAbrechenbar` (Kliententermin/
  Buero/Dokumentation = ja; Supervision/Teamsitzung/Fortbildung/
  Fahrtzeit/Sonstige = nein)

### Behoben

- **BuildContext-Async-Gap** in `rechnungen_screen._storno`
- **Fehlende Imports** `appointment.dart` / `client.dart` in
  `rechnungen_screen.dart`

### Codebase

- Lint-Cleanup projektweit: 312 -> 246 Issues, 63 -> 4 Warnings
  (-60%)
- 23 unused imports entfernt
- 11 unused local variables entfernt
- 5 unused private fields entfernt
- Dead-Code-Block in `clients_screen.dart` entfernt
- RadioListTile-Deprecations in `export_service.dart` auf
  `RadioGroup`-Ancestor umgestellt
- Debug-Test-Datei `test/docx_minimal_test.dart` entfernt
- Debug-Sample `test/pdf_stil_beispiele.dart` nach `docs/samples/`
  verschoben

---

## [0.2.0-beta.1] - 2026-04 (vorheriger Stand)

- Alle 16 Bundeslaender mit passendem Bedarfsinstrument
- PDF + CSV + DOCX Export mit Hybrid-Design
- Wirkungsmessung (GAS + POS) nach §128 SGB IX
- Formular 101 Berlin (Syncfusion-Fill, 406 Felder)
- XRechnung-Export (UBL 2.1, EN 16931) - erste Iteration
- DSGVO-Modul (Einwilligung, Audit-Log, GDPR-Delete, Retention)
- Matrix-Chat mit E2E-Verschluesselung
- Cloud-Sync (HiDrive, Nextcloud, WebDAV) mit AES-256-GCM
- TOTP-2FA, Biometrie, PBKDF2, Recovery-Key
- Admin-Bereich (Teams, Rollen, Einladung per QR-Provisioning)
- Setup-Wizard (Admin + Einladungs-Pfad)
- Hilfe-Bereich + MkDocs-Wiki
