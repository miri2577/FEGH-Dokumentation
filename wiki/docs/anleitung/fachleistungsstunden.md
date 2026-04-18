# Fachleistungsstunden (FLS) und Abrechnung

Die Fachleistungsstunden-Verwaltung ist das Herzstueck der Rechnungsstellung
in der Eingliederungshilfe. FEGH-Dokumentation sorgt dafuer, dass die
Abrechnung gegenueber dem Sozialamt rechtssicher und mit vollstaendigen
Pflichtangaben erfolgt.

## Was ist eine Fachleistungsstunde?

Die FLS ist die **Brutto-Abrechnungseinheit** der Eingliederungshilfe.
Sie umfasst in Berlin (BRV) und in den meisten Landesrahmenvertraegen:

- Klient-Kontakt (direkt)
- Vor- und Nachbereitung
- Dokumentation
- Kollegiale Fallberatung mit Fallbezug
- Ausfallzeiten (Urlaub, Krankheit, Fortbildung) - eingepreist
- Sachkosten (Buero, Telefon, Material) - eingepreist
- Fahrzeiten - je nach Landesrahmenvertrag eingepreist oder gesondert

Abgerechnet wird die **tatsaechlich erbrachte direkt zurechenbare FLS**
mit dem **vereinbarten Stundensatz** aus der Verguetungsvereinbarung
nach §125 SGB IX.

## Kalkulationsfaktor

Der Kalkulationsfaktor (z.B. 1,33) ist **nur informativ** zur internen
Personalplanung. Er beschreibt das Verhaeltnis Gesamtarbeitszeit zur
abrechnungsfaehigen Kontaktzeit. Der Faktor ist **bereits im vereinbarten
Stundensatz eingepreist** - er darf nicht zusaetzlich auf die Rechnung
angewendet werden!

!!! warning "Doppelberechnung vermeiden"
    Wenn die Kalkulationsfaktor noch einmal auf die Rechnungs-Betraege
    angewendet wird (verbraucht x stundensatz x faktor), entsteht
    eine Doppelabrechnung. Das fuehrt zu Regressforderungen und kann
    bei Wiederholung als Betrug gewertet werden.

In FEGH-Dokumentation wird der Faktor nur fuer die Kennzahl
"Gesamtarbeitszeit (mit KLE)" in der Klienten-Detailansicht genutzt.

## Bewilligungsumfang und Intervall

Pro Klient werden in den Stammdaten erfasst:
- **Fachleistungsstunden** (bewilligt, aus Kostenuebernahme)
- **Fachleistungsintervall**: woechentlich / monatlich / jaehrlich

Wird ein Klient mit 10 FLS/Woche bewilligt, berechnet FEGH den Verbrauch
**ausschliesslich im aktuellen Wochenzeitraum** (Montag 00:00 - Sonntag 23:59).
Ueberlaufende Termine in der Folgewoche werden dem neuen Zeitraum zugerechnet.

## Budget-Warnung

Beim Speichern eines Termins prueft FEGH automatisch den FLS-Verbrauch
im aktuellen Abrechnungszeitraum:

- **>= 90 %**: gelber Warndialog "Budget nahezu erreicht"
- **>= 100 %**: roter Warndialog "Bewilligtes Kontingent ueberschritten"

Der Nutzer kann jeweils abbrechen oder trotzdem speichern. Bei
Ueberschreitung ohne Fortschreibung des Bewilligungsbescheids traegt
das Risiko vollstaendig der Leistungserbringer - der Kostentraeger
kuerzt auf das bewilligte Mass.

## Abrechenbare vs. nicht abrechenbare TerminArten

| TerminArt | In Rechnung? |
|-----------|-------------|
| Kliententermin | ja |
| Buero (mit Fallbezug) | ja |
| Dokumentation | ja |
| Supervision | nein (im Stundensatz eingepreist) |
| Teamsitzung | nein |
| Fortbildung | nein |
| Fahrtzeit | nein (Berlin: eingepreist) |
| Sonstige | nein |

Die Rechnungs-Aggregation nutzt nur abrechenbare Termine. Supervision
und Fortbildung werden dokumentiert, erscheinen aber nicht auf der
Rechnung.

## Rechnungsstellung Schritt fuer Schritt

### 1. Empfaenger pflegen

Berichte > Rechnungen > Button **Empfaenger**.

Pflichtfelder pro Kostentraeger:
- Name (Bezirksamt / Behoerde)
- **Leitweg-ID** (format NNNNN-xxxxxxxxxxx-NN, erforderlich fuer
  XRechnung nach §14a UStG / ERechVBln)
- Strasse, PLZ, Ort

Optional: Abteilung, Ansprechpartner, E-Mail, Telefon, USt-ID.

### 2. Klient-Stammdaten pflegen

Pro Klient, der beim Kostentraeger abgerechnet wird:
- **Aktenzeichen / Fallnummer** (pro Kostentraeger eindeutig)
- **Bewilligungsbescheid-Referenz** (Geschaeftszeichen)
- **Leistungstyp-Schluessel** nach Rahmenvertrag (z.B. "B5.01 ABW Erwachsene")
- **Stundensatz** (individuell aus §125-Vereinbarung; NICHT den App-Default nutzen!)

### 3. Rechnung erstellen

Berichte > Rechnungen > FAB **Neue Rechnung**.

- Leistungszeitraum waehlen (meist Kalendermonat)
- Empfaenger waehlen (z.B. Sozialamt Friedrichshain-Kreuzberg)
- Bestellnummer / Aktenzeichen fuer diese Rechnung (optional)
- Bemerkung (optional, z.B. "Abrechnung Maerz 2026")

FEGH aggregiert automatisch alle abrechenbaren Termine im Zeitraum pro
Klient, rechnet Stunden zusammen und ermittelt den Einzelpreis aus
`client.stundensatzOverride` oder den App-Settings.

### 4. Plausi-Check

Vor dem Speichern prueft FEGH:

**Hart (blockierend):**
- Leitweg-ID des Empfaengers formal gueltig
- Aktenzeichen pro Klient beim aktuellen Kostentraeger vorhanden

**Weich (Hinweis):**
- Geburtsdatum der Klienten
- Leistungstyp-Schluessel
- Bewilligungsbescheid-Referenz
- Budget-Ueberschreitung im aktuellen Zeitraum

Der Nutzer kann bei weichen Warnungen trotzdem weitermachen,
harte Fehler sollten vor Erstellung behoben werden.

### 5. XRechnung-XML exportieren

In der Rechnungsliste: **XML herunterladen**. FEGH erzeugt UBL-2.1-XML
nach XRechnung-3.0-Spezifikation mit:

- Leitweg-ID als BuyerReference
- Steuerbefreiungsgrund nach §4 UStG (waehlbar zwischen Nr. 16 h / 25 / 18)
- Einrichtungs-IK (wenn konfiguriert)
- Pro Position: Aktenzeichen, Geburtsdatum, Leistungstyp, Bewilligungs-Ref
- IBAN / BIC / Kontoinhaber aus Rechnungssteller-Daten

### 6. Einreichung bei der Behoerde

Nach dem Export zeigt FEGH die Einreichungsoptionen:

1. **OZG-RE** (https://xrechnung.bund.de) - zentrale Rechnungsplattform
2. **PEPPOL-Netzwerk** (falls Ihr System angebunden ist)
3. **DE-Mail / beA** als Fallback-Weg (weniger bevorzugt)

### 7. Statusverfolgung

Pro Rechnung: Entwurf -> Versendet -> Bezahlt.

- **Versendet**: Nach Einreichung markieren (Kontextmenue)
- **Bezahlt**: Nach Zahlungseingang markieren
- **Storniert**: Storno-Rechnung erzeugen (siehe unten)

## Monatslauf (Automatik)

Fuer wiederkehrende Monatsabrechnungen: Berichte > Rechnungen > FAB
**Monatslauf** (teal-farbig, oberer FAB).

FEGH erzeugt in einem Durchgang pro Kostentraeger eine Rechnung fuer den
**letzten abgeschlossenen Kalendermonat** und verwendet dabei:

- Nur Klienten mit hinterlegter Fallnummer beim jeweiligen Empfaenger
- Nur abrechenbare TerminArten (siehe Tabelle oben)
- Indirekte Dokumentations-/Buero-Termine mit Fallbezug aus der
  `clientAllocations`-Aufteilung
- Stundensatz pro Klient (individuell oder Default)

Vor dem Speichern zeigt FEGH einen **Review-Dialog** mit Breakdown pro
Empfaenger, Klient, Stunden und Betrag. Der Nutzer bestaetigt oder bricht
ab. Jede erzeugte Rechnung wird im Audit-Log erfasst.

Empfehlung: Monatslauf am 1. des Folgemonats ausfuehren, Rechnungen
anschliessend pruefen und per XRechnung / OZG-RE einreichen.

## Audit-Log

Alle abrechnungsrelevanten Aktionen werden verschluesselt im DSGVO-Audit-Log
persistiert:

| Aktion | Kontext |
|--------|---------|
| `rechnung.create` | Rechnungsnr., Bruttobetrag |
| `rechnung.status` | Rechnungsnr., alter/neuer Status |
| `rechnung.storno` | Original-Nr., Storno-Nr. |
| `rechnung.xml_export` | Rechnungsnr. |

Das Log dient der **Rechenschaftspflicht nach DSGVO Art. 5 Abs. 2** und
der Dokumentation fuer Wirtschaftspruefungen / Betriebspruefungen.
Aufbewahrung: 3 Jahre (automatische Rotation), Rechnungsdaten selbst
10 Jahre nach HGB/AO.

## Storno-Rechnung

Bei Fehler oder Rueckgabe einer bereits versendeten Rechnung:
Kontextmenue > **Stornieren**.

FEGH erzeugt eine neue Rechnung mit:
- Negativen Mengen (die Betraege werden also negativ)
- Neuer Rechnungsnummer mit `-ST`-Suffix
- Bemerkung "Storno zu Rechnung X"
- Verweis auf Original via `stornoFuerRechnungId`

Die Original-Rechnung wird automatisch auf "Storniert" gesetzt.

## Steuerbefreiung

Die App erzeugt Rechnungen als **steuerfrei** (§4 UStG). Waehlbar ist:

| Option | Anwendungsfall |
|--------|----------------|
| §4 Nr. 16 h UStG | EGH durch anerkannten Traeger (Standard) |
| §4 Nr. 25 UStG | Jugendhilfe (SGB VIII) |
| §4 Nr. 18 UStG | Freie Wohlfahrtspflege |

Der korrekte Paragraph haengt vom Leistungstyp und der Anerkennung
des Leistungserbringers ab. Im Zweifel den Steuerberater fragen.

## Aufbewahrungsfristen

Rechnungsunterlagen muessen nach HGB §257 und AO §147 **10 Jahre**
aufbewahrt werden. FEGH speichert alle Rechnungen verschluesselt und
haelt sie ueber Backup/Restore-Funktion auch ueber App-Deinstallation
hinaus.

## Checkliste: Rechtssicher abrechnen

- [x] Verguetungsvereinbarung nach §125 SGB IX aktuell
- [x] Stundensatz aus Vereinbarung pro Klient (oder Default) gepflegt
- [x] Empfaenger mit korrekter Leitweg-ID angelegt
- [x] Aktenzeichen pro Klient beim Kostentraeger hinterlegt
- [x] Leistungstyp-Schluessel gemaess Rahmenvertrag gesetzt
- [x] Bewilligungsbescheid-Referenz dokumentiert
- [x] Bewilligtes Kontingent (FLS + Intervall) aktuell
- [x] XRechnung-Export ueber OZG-RE einreichen
- [x] Status pflegen (Versendet / Bezahlt / Storniert)
