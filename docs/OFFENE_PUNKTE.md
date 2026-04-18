# FEGH-Dokumentation - Offene Punkte

Stand: 18.04.2026

Dieses Dokument sammelt bewusst zurueckgestellte Vorhaben und kleinere
Polituren, damit sie in einer naechsten Runde nicht vergessen werden.

## Groessere Vorhaben (zurueckgestellt)

### 1. BEI_NRW per Koordinaten-Overlay ausfuellen
- **Plan**: `docs/PLAN_NRW_BEI_OVERLAY.md`
- **Motivation**: NRW = 25% EGH-Markt, BEI_NRW-PDF ist statisch ohne AcroForm
- **Loesung**: Blanko-PDF als Hintergrund, Text an vermessenen Koordinaten drueberzeichnen
- **Aufwand**: ~8-11 Std (einmalige Feld-Vermessung + Pipeline)
- **Risiko**: Fragil gegenueber Layout-Updates des Amtsformulars

### 2. "Copy-to-Portal"-Spickzettel
- **Plan**: `docs/PLAN_COPY_TO_PORTAL.md`
- **Motivation**: Portale (PerSEH, ANLEI, KVJS-BW, LS-EH-NI) brauchen manuelles Eintragen
- **Loesung**: Nutzer waehlt Portal, App zeigt Felder in Reihenfolge mit Tap-to-Copy
- **Prio**: PerSEH (NRW/Hessen) -> ANLEI (Bayern) -> KVJS -> LS-EH-NI -> NEO.connect (XML)
- **Aufwand**: ~16-18 Std fuer erste Version (PerSEH)

## Kleinere Polituren

### 3. RadioListTile-Deprecations
- **Wo**: `lib/services/export_service.dart` (Format-Dialog)
- **Warum**: Flutter 3.32+ bevorzugt RadioGroup-Ancestor
- **Aufwand**: 10-15 Min

### 4. Pre-existing Warnings aufraeumen
- `lib/screens/clients_screen.dart`: 2x unused imports, 1x dead code
- `lib/screens/create_client_screen.dart`: weitere unused imports
- `lib/screens/admin/*.dart`: vereinzelte Warnungen
- **Aufwand**: 30-60 Min

### 5. Debug-Test-Dateien
- `test/pdf_stil_beispiele.dart` (Stil A/B/C Beispiele) - kann in `docs/samples/` archiviert werden
- `test/docx_minimal_test.dart` - einmaliger LibreOffice-Debug-Test, kann geloescht werden
- **Aufwand**: 5 Min

## Feature-Erweiterungen (Nice-to-Have)

### 6. Wirksamkeitsbericht mit Mini-Diagrammen
- GAS-Verlaufs-Linie als kleine Grafik pro Ziel
- POS-Netzdiagramm als SVG-Vektor im PDF
- Erfordert eigenes Canvas-Zeichnen im pdf-Paket
- **Aufwand**: 4-6 Std

### 7. Tests auf anderen Plattformen
- Bisher nur Windows-Desktop getestet
- Android/iOS-Flows: Share-Dialog, Biometrie, Kamera
- **Aufwand**: variable (abhaengig von gefundenen Problemen)

### 8. Screenshots/Marketing
- Screenshot-Serie fuer Wiki und Vertriebsunterlagen
- Video-Walkthrough der Hauptfunktionen
- **Aufwand**: 1-2 Std

### 9. Oesterreich/Schweiz-Anpassung
- Andere Rahmenvertraege, andere Formulare
- Bei bundesweiter Marktbearbeitung DACH-Expansion denkbar
- **Aufwand**: gross, nur bei Bedarf

## Release-Vorbereitung

### 10. Version-Bump + Changelog
- `pubspec.yaml`: 0.2.0-beta.1 -> 0.3.0 (oder 1.0.0-beta.1)
- `CHANGELOG.md` pflegen
- **Aufwand**: 20 Min

### 11. Beta-Testing
- 2-3 Traeger fuer Pilot-Tests anfragen
- Feedback-Kanal einrichten
- **Aufwand**: organisatorisch

### 12. Server-Produktivbetrieb
- Wenn Multi-Team geplant: Matrix-Server und HiDrive-Storage produktiv aufsetzen
- Monitoring einrichten
- **Aufwand**: organisatorisch

## Was bereits produktionsreif ist

- Alle 16 Bundeslaender mit passendem Bedarfsinstrument
- PDF + CSV + DOCX Export (Hybrid-Design, Unicode, professionell)
- Wirkungsmessung (GAS + POS + Wirksamkeitsbericht nach §128 SGB IX)
- Formular 101 (Berlin, Syncfusion-Fill mit 406 Feldern)
- XRechnung-Export (UBL 2.1, EN 16931)
- DSGVO-konform (Einwilligung, Audit-Log, GDPR-Delete, Retention)
- Matrix-Chat mit E2E-Verschluesselung
- Cloud-Sync (HiDrive, Nextcloud, beliebige WebDAV)
- TOTP-2FA, Biometrie, PBKDF2
- Admin-Bereich (Teams, Mitarbeiter-Einladung, Rollen)
- Setup-Wizard (Admin + Einladungs-Pfad)
- Hilfe-Bereich + umfangreiches Wiki

## Empfohlene naechste Schritte

1. **Option A (Markt-Ausbau)**: NRW-Overlay umsetzen -> 25% zusaetzlicher Markt
2. **Option B (Feinschliff)**: Polituren 3-5 -> sauberes Projekt fuer Release
3. **Option C (Release)**: Version-Bump, Beta-Testing, Pilotkunden

Empfehlung: **B -> C -> A** - erst Release-Stabilitaet, dann Markterschliessung.
