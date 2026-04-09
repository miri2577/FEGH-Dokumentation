# Berichte und Export

## Informationsbericht (Berlin)

Der Informationsbericht basiert auf dem **Berliner Formular 101** mit 137 Formularfeldern. Er ist in 6 Abschnitte gegliedert:

### Abschnitt 1: Kopfdaten
- Teilhabefachdienst, ID Kostenuebernahme
- Berichtszeitraum (Von/Bis)
- Leistungstyp

### Abschnitt 2: Persoenliche Daten
- Anrede, Familienname, Vorname, Geburtsdatum, Geschlecht
- Familienstand, Staatsangehoerigkeit
- Adresse, Kontaktdaten

### Abschnitt 3: Allgemeine Informationen
- Freitextfeld fuer allgemeine Informationen zur Betreuungssituation

### Abschnitt 4: Teilhabeziele
Liste von Teilhabezielen mit jeweils:

| Feld | Beschreibung |
|------|-------------|
| Leitziel-Nr. und Text | Uebergeordnetes Ziel |
| Teilhabeziel-Nr. und Text | Konkretes Ziel |
| Indikator | Messbarer Indikator |
| Zielerreichung | voll erreicht / teilweise erreicht / nicht erreicht / nicht beurteilbar |
| Abweichende Einschaetzung | Bei unterschiedlicher Bewertung |
| Erlaeuterung | Detaillierte Beschreibung |

### Abschnitt 5: Zusammenfassung
- Zusammenfassender Text
- Nacht-Assistenz (Ja/Nein)
- Weitere Anmerkungen

### Abschnitt 6: Unterschriften
- Ort und Datum
- Unterschrift Leistungserbringer
- Eintragung Klient

### PDF-Export Varianten

Der Informationsbericht kann in **drei Varianten** exportiert werden:

1. **Original-Layout (Syncfusion)**: Fuellt die Original-PDF-Vorlage (`informationsbericht_101.pdf`) mit Syncfusion PDF aus
2. **Original-Layout (PDF-Paket)**: Erstellt das Formular neu mit dem `pdf`-Paket
3. **App-Layout**: Eigenes Design, optimiert fuer Bildschirmdarstellung

Entwuerfe koennen gespeichert und spaeter weiterbearbeitet werden.

## FLS-Bericht (Fachleistungsstunden)

Automatisch berechneter Bericht ueber Fachleistungsstunden pro Klient:

- Bewilligte vs. verbrauchte Stunden
- Kalkulationsfaktor-Anwendung (Standard: 1,33)
- Stundensatz-Berechnung (Standard: 40 EUR)
- Ampel-System: Gruen (<75%), Gelb (75-90%), Rot (>90%)

## Arbeitszeit-Bericht

Export der Arbeitszeitdaten mit Statistiken und Verteilung nach Taetigkeitstyp.

## Export-Formate

| Format | Beschreibung |
|--------|-------------|
| PDF | Druckfertiger Bericht |
| CSV | Tabellendaten fuer Excel/Calc |
| JSON | Strukturierte Daten fuer Weiterverarbeitung |

## DSGVO-Export

Unter Einstellungen → Datenverwaltung steht ein **DSGVO-konformer Datenexport** (Art. 20 DSGVO) zur Verfuegung. Dieser Export kann optional mit einem Passwort verschluesselt werden.
