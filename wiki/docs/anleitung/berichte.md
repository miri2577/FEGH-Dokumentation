# Berichte und Export

## Funktionsweise im Detail

### Das Problem, das wir loesen

Ein Sozialarbeiter in der EGH produziert im Jahresverlauf **mindestens
vier grundverschiedene Arten von Berichten**:

- **Informationsbericht** an den Kostentraeger (Formular 101 in Berlin,
  je Bundesland anderes Formular) — strukturiert, mit festgelegten
  Abschnitten und amtlichem Layout.
- **Wirksamkeitsbericht** fuer §128-SGB-IX-Nachweis — mit Zielen,
  Messungen, POS-Vergleichen.
- **XRechnung** an das Finanzamt/Behoerden — UBL-XML, KoSIT-validiert.
- **Interne Kurzberichte** fuer Schichtuebergabe und Fallkonferenzen.

Ohne Automatisierung heisst das: fuer jeden Bericht erneut Daten aus
der Akte kopieren, in ein Word-Template einfuegen, formatieren,
ausdrucken. Fehlerquelle + Zeitfresser. Die App erzeugt alle vier auf
Knopfdruck aus den **gleichen gepflegten Datenbestaenden** — und
garantiert damit, dass Information nie widerspruechlich zwischen
zwei Dokumenten steht.

### Konkretes Szenario: Quartalsbericht fuer Frau O.

Fachliche Leitung Sabine muss fuer den 31. Maerz 2026 einen
**Informationsbericht** an das Sozialamt einreichen — Stichtag fuer
die Bedarfsfortschreibung.

**31. Maerz, 09:00 Uhr — Sabine startet den Export.**

1. `Klient → Frau O. → Berichte → Informationsbericht (Formular 101)`
2. Auswahl Zeitraum: 01.01.2026 - 31.03.2026
3. Die App aggregiert **aus den vorhandenen Daten**:
   - **Stammdaten** (Abschnitt 2): direkt aus der Klient-Akte
   - **Teilhabeziele** (Abschnitt 4): aus dem Ziele-Modul inkl.
     aller Messungen im Zeitraum
   - **Fachleistungsstunden** (Abschnitt 5): aus den Terminen und
     Arbeitszeit-Eintraegen
   - **Freitexte**: Sabine ergaenzt die "Allgemeine Informationen"
     individuell
4. Vorschau erscheint: 14 Seiten PDF mit korrektem Layout,
   Berliner Logo oben, Formular-101-Feldern ausgefuellt
5. Sabine prueft, passt drei Freitextformulierungen an, und exportiert
   als **PDF + CSV** (das Sozialamt akzeptiert beides)

**09:25 Uhr — Einreichung ueber beA.**

Sabine laedt die PDF ins besondere elektronische Anwaltspostfach
(beA) hoch, schickt sie an das Sozialamt.

### Welche Export-Formate fuer welchen Zweck?

| Ziel | Format | Warum |
|------|--------|-------|
| Traeger-Bericht Berlin | Formular 101 PDF | amtliche Vorgabe, Behoerde akzeptiert nichts anderes |
| Traeger-Bericht andere Laender | PDF (aus Wirkungsbericht) | meist kein amtliches Pflichtformular |
| Abrechnung an Bezirk | XRechnung UBL-XML | §14a UStG — elektronische Rechnung seit 2020 Pflicht |
| Wirksamkeitsbericht §128 | PDF mit GAS/POS-Chart | Audit-sicher, druckbar, unterzeichnebar |
| Jahresbilanz fuer Leitung | PDF | Kennzahlen-Uebersicht |
| Daten-Export DSGVO Art. 20 | JSON | strukturiert, maschinenlesbar |
| Portabler Export DSGVO | PDF + JSON | Klient nimmt Akte mit zum neuen Traeger |

### PDF-Design-System

Alle PDFs nutzen das gemeinsame `fegh_pdf_kit`-Paket:

- **Design-Tokens** (primary/accent/warn/muted) — einheitliche Farbpalette
- **Header-Baustein** (Logo, Titel, Aktenzeichen, Berichtszeitraum)
- **KPI-Kacheln** (bunte Zahlen-Boxen fuer Kennzahlen)
- **Tabellenstil** mit Zebra-Zeilen, rechtsbuendigen Betraegen
- **Footer** mit Erstellungszeitpunkt und Pagination
- **Signatur-Zeile** am Ende
- **Roboto-Schrift** (embedded, auch auf Behoerdenrechnern sichtbar)

Das hat zwei Vorteile: (1) **Konsistenz** ueber alle Berichte — die
Farben einer Monatsabrechnung sind identisch zu denen eines
Wirksamkeitsberichts; (2) **Einheitliche Fehlerkorrektur** — wenn
die Kopfzeile einen Bug hat, betrifft der Fix alle Reports
gleichzeitig.

### XRechnung-Export im Detail

Die elektronische Rechnung laeuft ueber den `XRechnungService` im
Paket `fegh_billing`:

1. Der Service erzeugt **UBL 2.1 XML** nach XRechnung-3.0.2-Spezifikation.
2. Pflichtfelder werden **hart validiert**: fehlende Leitweg-ID,
   fehlender Telefonkontakt, fehlende Email → `ArgumentError`, bevor
   die XML ueberhaupt geschrieben wird. Damit verhindern wir, dass
   eine unvollstaendige Rechnung das Haus verlaesst und vom
   Sozialamt kommentarlos abgelehnt wird.
3. Die Struktur folgt dem UBL-Schema **strikt** (Element-Reihenfolge,
   Namespaces, Code-Listen) — gegen KoSIT-Validator getestet.
4. **VATEX-Codes** fuer Steuerbefreiungen werden aus dem
   §4-UStG-Befreiungsgrund abgeleitet:
   - `§4 Nr. 16 Buchst. h UStG` (EGH) → `VATEX-EU-132-1G`
   - `§4 Nr. 18 UStG` (freie Wohlfahrt) → `VATEX-EU-132-1G`
   - `§4 Nr. 25 UStG` (Jugendhilfe) → `VATEX-EU-132-1H`

Die generierte XML kann direkt ins OZG-RE-Portal hochgeladen werden
(kein weiterer Konverter noetig).

### Rechtlicher Hintergrund

- **§128 SGB IX** — Wirksamkeitsnachweis, der den Bericht struktu-
  rell vorschreibt.
- **§131 SGB IX** — Landesrahmenvertraege regeln das konkrete
  Formular (z. B. Berliner Formular 101 im LRV fixiert).
- **§14a UStG** — elektronische Rechnung an oeffentliche
  Auftraggeber verpflichtend (Bundesebene seit 27.11.2020, Berlin
  seit 18.04.2020).
- **EN 16931** — europaeische Norm fuer elektronische Rechnung, auf
  der XRechnung aufbaut.
- **Art. 20 DSGVO** — Recht auf Datenuebertragbarkeit: strukturierter
  Export ist Pflicht, wenn Klient das verlangt.
- **HGB §257 + AO §147** — Rechnungen 10 Jahre aufbewahren; Back-up
  und Restore decken das ab.

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
