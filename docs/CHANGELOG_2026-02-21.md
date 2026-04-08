# Changelog 21.02.2026

## Neues Feature: Berichte-Tab mit Informationsbericht

### Navigation
- **Berichte-Tab** in Navigation eingebaut (Index 6)
- Sichtbar in Navigation Rail (Desktop), Drawer und "Mehr"-Menu (Mobile)
- Export, Hilfe, Einstellungen Indizes entsprechend verschoben (7, 8, 9)

**Geaenderte Dateien:**
- `lib/widgets/adaptive_navigation.dart` — NavigationDestination, NavigationRailDestination, Mehr-Menu
- `lib/screens/home_screen.dart` — Import + BerichteScreen im IndexedStack

---

### Berichte-Screen (`lib/screens/berichte_screen.dart`)
- Uebersicht mit Berichtsvorlagen-Karten ("Informationsbericht v1.01")
- "Neu erstellen" Button mit Klient-Auswahl-Dialog
- Gespeicherte Entwuerfe-Liste mit Klientenname, Datum, Loeschen-Funktion
- Entwuerfe werden beim Oeffnen/Zurueckkehren automatisch aktualisiert

---

### Informationsbericht-Formular (`lib/screens/informationsbericht_screen.dart`)
- **Split-Screen:** Desktop (>900px) zeigt Formular (60%) + Dokumentation (40%) nebeneinander
- **Mobile:** Toggle-Button in AppBar wechselt zwischen Formular und Dokumentation
- **Alle 6 Sektionen** des PDF-Formulars als Flutter-Form:
  - Kopfdaten (Teilhabefachdienst, ID Kostenuebernahme, Berichtszeitraum, Leistungstyp, Adresse)
  - 1. Persoenliche Daten (Anrede, Name, Geburtsdatum, Geschlecht, Kontakt)
  - 2. Allgemeine Informationen (Freitext)
  - 3. Teilhabeziele (dynamisch hinzufuegen/entfernen, Zielerreichung, Erlaeuterung)
  - 4. Zusammenfassung / Ausblick
  - 5. Unterschriften
  - 6. Eintragungen der leistungsberechtigten Person
- **Auto-Fill** aus Client-Daten (Nachname, Vorname, Geburtsdatum, TIB-Ziele)
- **Entwurf speichern** (Disketten-Icon) — persistiert als JSON
- **PDF-Export** (PDF-Icon):
  - Desktop: Speichert PDF in Dokumente-Ordner und oeffnet mit Standard-Viewer
  - Mobile: Share-Dialog (teilen, AirDrop, in Dateien speichern)

---

### Klienten-Akte Widget (`lib/widgets/klienten_akte_widget.dart`)
- Chronologische Volltext-Ansicht aller Termine eines Klienten
- Suchfunktion (filtert Notizen, Sprachaufzeichnungen, Klientenname)
- Kopieren-Button pro Eintrag (gesamter Text in Zwischenablage)
- SelectableText fuer manuelles Markieren und Kopieren
- Anzeige: Datum, Uhrzeit, Notizen, Sprachaufzeichnungs-Text, ICF-Bereiche als Chips

---

### Datenmodell (`lib/models/informationsbericht.dart`)
- **Informationsbericht** Klasse mit allen Feldern des PDF-Formulars
- **Teilhabeziel** Sub-Modell (Leitziel, Teilhabeziel, Indikator, Zielerreichung, Erlaeuterung)
- **ZielerreichungStatus** Enum (vollErreicht, teilweiseErreicht, nichtErreicht, nichtBeurteilbar)
- JSON-Serialisierung mit `@JsonSerializable()`, `copyWith()`, `create()` Factory
- Generierte Datei: `informationsbericht.g.dart`

---

### Persistenz (`lib/services/file_storage_service.dart`)
- `loadBerichte()` / `saveBerichte()` — Laedt/speichert Informationsberichte als `berichte.json`
- In `clearAllData()` eingebunden

---

### PDF-Export (`lib/services/pdf_generator_service.dart`)
- `generateInformationsberichtPDF()` — Mehrseitiges A4-PDF mit allen Sektionen
- Kopfdaten-Tabelle, Persoenliche Daten, Freitext-Bloecke, Teilhabeziele mit Zielerreichung
- Unterschriftslinien, Eintragungen-Block
- Nutzt bestehende Helper (_buildHeader, _buildFooter) fuer konsistentes Layout

---

### Bugfixes
- Null-Safety Warnings in `klienten_akte_widget.dart` behoben (`recordedText`, `icfBereiche` sind nicht nullable)
- Unused Imports in `berichte_screen.dart` und `informationsbericht_screen.dart` entfernt
