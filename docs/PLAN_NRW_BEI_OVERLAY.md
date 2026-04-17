# Plan: BEI_NRW-Formular per Koordinaten-Overlay ausfuellen

**Status:** Zurueckgestellt nach User-Wunsch am 17.04.2026.
**Motivation:** NRW ist mit ~25% der groesste EGH-Markt in DE, das Blanko-BEI_NRW-PDF hat keine AcroForm-Felder (bestaetigt), daher muss Text programmatisch als Overlay auf bestimmten Positionen gezeichnet werden.

## Ansatz

Das statische PDF `assets/formulare/nrw/bei_nrw_leer.pdf` (722 KB, LVR/LWL, Stand 11/2017) wird nicht mit Formularfeldern befuellt, sondern per PDF-Overlay mit Text und Kreuzen an vermessenen (x,y)-Koordinaten ueberzeichnet.

## Technik

- `syncfusion_flutter_pdf` (bereits im Projekt):
  - `PdfDocument(inputBytes: templateBytes)` laedt das Blanko
  - `pdfPage.graphics.drawString(text, font, bounds: Rect(x, y, w, h))`
  - `pdfPage.graphics.drawString('X', font, bounds: Rect(x, y, 10, 10))` fuer Checkboxen
- `pdfPage.size` liefert die Seitengroesse, A4 = 595.0 x 842.0 Punkte

## Vermessung der Feldpositionen

Einmaliger Aufwand. Vermessungs-Pipeline:

1. PDF oeffnen in Acrobat oder Xpdf
2. Pro Feld: linke obere Ecke in Punkten lesen (meist direkt per Lineal-Anzeige)
3. Koordinaten in Konstanten-Map hinterlegen:
```dart
class BeiNrwCoordinates {
  // Seite 1
  static const Rect klientName = Rect.fromLTWH(150, 120, 300, 12);
  static const Rect klientId = Rect.fromLTWH(460, 120, 100, 12);
  static const Rect geburtsdatum = Rect.fromLTWH(150, 140, 100, 12);
  // ... alle Felder
}
```
4. Pro Checkbox: kleiner Rect fuer das "X"

## Umfang

BEI_NRW hat (geschaetzt, laut Downloadversion 11/2017) ca. 60-100 relevante Felder verteilt auf 25-30 Seiten. Wichtigste:
- **Stammdaten**: Name, Adresse, Geburtsdatum, Geschlecht, Sorgerecht
- **Versicherungen**: Krankenkasse, Pflegekasse
- **Betreuung**: rechtliche Betreuung, Vollmachten
- **ICF-Lebensbereiche (d1-d9)**: jeweils mit Beobachtungsfeld + Aktivitaetsniveau-Kreuzen
- **Teilhabeziele**: Leit-, Teil-, Handlungsziele
- **Massnahmen**: beantragte Leistungen, Begruendung
- **Unterschriften**: Ort/Datum, Leistungserbringer, Klient

## Implementierungsplan

1. **Service anlegen**: `lib/services/pdf_overlay_service.dart`
   - Methode `fuelleBeiNrw(client, zeitraum, ziele) -> Uint8List`
2. **Koordinaten-Konstanten**: `lib/services/pdf_overlay/bei_nrw_coordinates.dart`
3. **Mapping**: Client-Daten -> Feldpositionen
4. **Unit-Test**: verifiziert dass Ausgabe ein valides PDF mit korrekter Seitenzahl ist
5. **UI-Integration**: bei Bundesland=NRW ein "BEI_NRW ausfuellen"-Button im Berichte-Screen
6. **Vermessungs-Helper** (optional): Debug-Modus zeigt Gitternetz ueber dem Blanko-PDF, damit man Koordinaten per Auge ablesen kann

## Aufwand

- Einmalige Vermessung aller Felder: 4-6 Stunden
- Implementation der Pipeline: 2-3 Stunden
- Test + UI: 1-2 Stunden
- **Gesamt: ~8-11 Stunden**

## Risiken

- LVR/LWL koennten das Formular veroeffentlichen als neue Version mit anderem Layout -> alle Koordinaten mueessen neu gemessen werden
- Koordinaten-Ungenauigkeit von +-2 Punkten ist sichtbar -> genaues Messen noetig
- Font-Rendering kann leicht abweichen (Helvetica vs. Arial etc.)

## Wenn spaeter umgesetzt

Diese Datei beim Start der Implementation konsultieren, um nicht wieder Grundlagen zu erarbeiten.

## Referenzen

- Syncfusion PDF-Drawing: https://help.syncfusion.com/flutter/pdf/working-with-graphics
- BEI_NRW-Leitfaden: https://www.lwl-inklusionsamt-soziale-teilhabe.de/media/filer_public/d5/a0/d5a005f2-a280-4aa1-a61d-10bc5ad7456e/leitfaden.pdf
- BEI_NRW-Blanko (722 KB): assets/formulare/nrw/bei_nrw_leer.pdf
