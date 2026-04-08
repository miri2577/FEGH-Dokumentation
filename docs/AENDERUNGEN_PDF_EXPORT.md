# PDF-Export: Drei Versionen zum Vergleich

## Uebersicht

Der PDF-Export des Informationsberichts bietet jetzt drei Varianten an, die ueber ein BottomSheet beim Klick auf den PDF-Button ausgewaehlt werden koennen.

---

## Geaenderte Dateien

### 1. `pubspec.yaml`
- **Neue Dependency:** `syncfusion_flutter_pdf: ^32.2.5` (fuer Template-Befuellung)
- **Neues Asset:** `assets/informationsbericht_101.pdf` (Original-Berliner-Formular als Template)

### 2. `lib/services/pdf_generator_service.dart`
- **Neuer Import:** `syncfusion_flutter_pdf`, `flutter/services.dart` (rootBundle), `flutter/foundation.dart`
- **Neue Methode:** `generateInformationsberichtSyncfusion(Informationsbericht bericht)`
  - Laedt das Original-PDF aus den Assets
  - Befuellt alle Formularfelder (Textfelder, ComboBoxen, Checkboxen)
  - Debug-Logging aller Feldnamen beim ersten Aufruf (Konsole pruefen fuer exaktes Mapping)
  - Flattened das Formular am Ende
- **Neue Methode:** `generateInformationsberichtOriginalLayout(Informationsbericht bericht)`
  - Nachbau des Berliner Amtsformulars mit dem `pdf` Package
  - Schlichtes Design: dunkelblaue Ueberschriften, umrandete Kaestchen, Unicode-Checkboxen
  - Seiten-Header ab Seite 2: "Informationsbericht zu den Leistungen [Vorname], [Name]"
  - Footer: "Informationsbericht V1.01" + Seitenzahl
  - Alle 6 Sektionen des Originals nachgebaut
- **Neue Hilfs-Widgets:** `_origSectionHeader`, `_origFormRow`, `_origFieldBox`, `_origTextArea`, `_origCheckboxRow`
- **Neue Konstanten:** `_darkBlue`, `_borderGray`
- **Bestehende Methode** `generateInformationsberichtPDF` bleibt unveraendert (App-Layout)

### 3. `lib/screens/informationsbericht_screen.dart`
- **Geaenderte Methode:** `_exportPdf()` zeigt jetzt ein BottomSheet mit drei Optionen
- **Neue Methode:** `_generateAndExportPdf(String variant)` — zentrale Export-Logik fuer alle drei Varianten

### 4. `assets/informationsbericht_101.pdf` (neu)
- Kopie des Original-Berliner-Formulars als Template fuer die Syncfusion-Variante

---

## Die drei PDF-Varianten

| Variante | Methode | Beschreibung |
|---|---|---|
| Original-Layout (Template) | `generateInformationsberichtSyncfusion` | Fuellt das echte Berliner PDF-Formular mit Syncfusion aus |
| Original-Layout (Nachbau) | `generateInformationsberichtOriginalLayout` | Nachbau des Amtsformulars mit dem `pdf` Package |
| App-Layout | `generateInformationsberichtPDF` | Bisheriges Design mit blauen Balken (unveraendert) |

---

## Hinweise

- **Syncfusion-Feldnamen:** Beim ersten Aufruf der Template-Variante werden alle Feldnamen in die Debug-Konsole geschrieben. Falls Felder nicht korrekt befuellt werden, koennen die Namen dort abgelesen und das Mapping in `generateInformationsberichtSyncfusion` angepasst werden.
- **Teilhabeziele im Template:** Das Original-PDF hat nur Platz fuer ein Teilhabeziel. Bei mehreren Zielen wird nur das erste ins Template eingetragen. Die Nachbau-Variante unterstuetzt beliebig viele Ziele.
- **Keine Breaking Changes:** Die bestehende App-Layout-Variante bleibt vollstaendig erhalten.
