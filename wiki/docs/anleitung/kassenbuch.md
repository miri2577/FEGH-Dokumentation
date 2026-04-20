# Kassenbuch

## Ueberblick

Das Kassenbuch dokumentiert Einzahlungen und Auszahlungen, die Mitarbeiter im Rahmen der Klienten-Betreuung taetigen: Taschengeld, Haushaltsgeld, Freizeitausgaben und Belege. Pro Klient wird ein eigenes Kassenbuch gefuehrt, das als monatlicher Auszug (PDF) exportierbar ist.

!!! note "Berechtigung"
    Lesen duerfen alle Teammitglieder des Klienten. Buchen und freigeben duerfen alle Mitarbeiter; Stornieren nur Admin und Teamleitung.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Frau L. lebt in einer Wohngruppe. Sie bekommt monatlich 180 € Taschengeld,
ihr Betreuer hebt das in bar fuer sie ab und verwaltet es treuhaenderisch.
Im Laufe des Monats:

- 40 € Kinokarten + Popcorn (Freizeit)
- 25 € Medikamenten-Zuzahlungen (Gesundheit)
- 60 € Taschengeld ausgezahlt an Frau L.
- 12 € Schuhe repariert (Bekleidung)
- 20 € Nachzahlung Stromkosten (Nebenkostenabrechnung)

Am Monatsende muss die Einrichtung:

- **gegenueber Frau L.** Rechenschaft ablegen (Art. 90 SGB IX —
  Mittelverwaltung fuer Leistungsberechtigte)
- **gegenueber ihrem Betreuer** belegen, dass kein Geld "weggekommen" ist
- **gegenueber dem Finanzamt** dokumentieren, dass keine steuerbaren
  Zuwendungen stattfanden
- **intern** nachweisen, dass Mitarbeiterinnen nicht unbelegte Ausgaben
  getaetigt haben

Das Kassenbuch macht aus der Schuhkarton-mit-Kassenzetteln-Loesung ein
auditierbares System: jede Buchung mit Zeitstempel, Mitarbeiter,
optional Beleg-Foto, optional Canvas-Unterschrift des Freigebenden.

### Konkretes Szenario: Ein Monat im Kassenbuch von Frau L.

**01. Maerz, 09:12 Uhr.** Sozialarbeiter Daniel bucht die
Taschengeld-Auszahlung der Einrichtung an die Kasse Frau L.:

- Kategorie: **Eingang**
- Betrag: **+180,00 EUR**
- Beschreibung: "Taschengeld Maerz 2026"
- Belegnummer: "TG-2026-03-012"
- Freigabe: nein (noch offen, falls Korrektur noetig)

Saldo: +180,00 EUR.

**05. Maerz.** Daniel geht mit Frau L. ins Kino. Er bucht:

- Kategorie: **Freizeit**
- Betrag: **-40,00 EUR**
- Beschreibung: "Kino Film 'Die Wolke', zwei Karten + Getraenk"
- Beleg: Foto des Kassenzettels (wird als Base64-PDF an der Buchung gespeichert)
- Freigabe: ja → Canvas-Unterschrift mit dem Daumen auf dem Tablet

Saldo nach Buchung: +140,00 EUR.

**12. Maerz.** In der Apotheke: Rezept-Zuzahlung. Daniel bucht:

- Kategorie: **Gesundheit**
- Betrag: **-25,00 EUR**
- Beschreibung: "Apothekenzuzahlung" — **ohne** Medikamentennamen oder
  Diagnose (Art. 9 DSGVO)
- Beleg: Foto der Apothekenquittung

Saldo: +115,00 EUR.

**22. Maerz, 14:05 Uhr — Stornofall.** Beim Durchsehen merkt Anja
(Teamleitung), dass der 12.-Maerz-Eintrag versehentlich 25 EUR statt
der tatsaechlichen 2,50 EUR gebucht wurde. Der Eintrag ist bereits
freigegeben — **nicht mehr aenderbar**. Anja loest den Storno:

1. Eintrag lange druecken → Menue "Stornieren"
2. Dialog verlangt **Grund** ("Betragsfehler: 25,00 statt 2,50 gebucht,
   Originalbeleg pruefen") und **Unterschrift**
3. System erzeugt eine *Gegenbuchung* mit +25,00 EUR vom heutigen Datum,
   kategorisiert identisch (Gesundheit), mit Bezug
   `stornoOfEntryId` auf den Originalbeleg. Original bleibt **unveraendert**
   im Buch, bekommt visuell ein "STORNIERT"-Badge.

Danach bucht Daniel den korrekten Betrag neu:

- Kategorie: Gesundheit, Betrag **-2,50 EUR**, Beschreibung mit Hinweis
  auf Storno-ID, freigegeben.

Saldo am Monatsende steht damit richtig — und die Historie zeigt alle
drei Buchungen (Original, Storno, Korrektur) transparent.

**31. Maerz, 18:30 Uhr — Monatsabschluss.** Anja oeffnet die Funktion
"Monat abschliessen":

1. Dialog waehlt Monat (Maerz 2026), zeigt aktuellen Endsaldo (+85,00 EUR)
2. System prueft: Sind alle Eintraege im Maerz freigegeben? Ja.
3. Unterschriftsfeld (Anja zeichnet mit dem Stift)
4. **Abschluss** → Maerz ist eingefroren. Weitere Buchungen in diesem
   Monat werden vom System verweigert (`add` gibt `false` zurueck mit
   Audit-Event `kassenbuch.month.closed`).

Ab 01. April sieht Daniel nur noch **Saldo-Rollover +85,00 EUR**; die
neuen Buchungen starten darauf. Wenn Frau L. Ende Juni fragt "was ist
im Maerz passiert?" — Anja kann den Monatsauszug als PDF generieren
(Saldo-Anfang, alle Einzelbuchungen, Endsaldo, Unterschriften der
freigegebenen Eintraege, separater Block fuer Stornos).

### Was die Canvas-Unterschrift konkret macht

- Wenn Daniel eine Buchung freigeben will, erscheint das
  `SignaturePad` — ein weisses Feld, auf dem er mit Finger oder
  Stylus unterzeichnet.
- Die Unterschrift wird als PNG (meist 8-20 KB) in Base64 kodiert und
  am Eintrag persistiert (`signaturePngB64`).
- Im Monatsauszug-PDF wird sie unter der jeweiligen Buchung
  eingebettet.
- Ohne Unterschrift laesst sich "Direkt freigeben" nicht
  abschicken — UI prueft vor dem Submit.

### Sicherheitsschichten im Ueberblick

| Schicht | Was sie leistet |
|---------|-----------------|
| **Freigabe-Flag** (`confirmed`) | Nicht-freigegebene Eintraege sind editierbar; freigegebene sind final |
| **Canvas-Unterschrift** | Ein Mensch hat bewusst quittiert — nicht ein Klick |
| **Storno-Workflow** | Keine Loeschung; stattdessen Gegenbuchung mit Pflicht-Grund + Unterschrift, Audit-Event `kassenbuch.entry.storno` |
| **Monatsabschluss-Sperre** | Abgeschlossene Monate sind unaenderlich; Korrekturen nur ueber Storno im Folgemonat |
| **Beleg-Upload** | PNG/JPG/PDF (max. 5 MB) direkt am Eintrag; keine externe Belegablage mehr |
| **Art.-9-DSGVO-Hinweis** | UI warnt, wenn Gesundheit als Kategorie gewaehlt ist: "Keine Diagnosen in die Beschreibung" |
| **Audit-Log** | Jede Aktion als eigener Event (`kassenbuch.entry.created`, `.confirmed`, `.storno`, `.month.closed`) |

### Was bei der Persistenz passiert

Ein neu angelegter Eintrag erzeugt drei Schreibvorgaenge:

1. **`KassenbuchEintrag`-Record** in SharedPreferences
   (`kassenbuch_eintraege_v1`) — mit Datum, Betrag, Kategorie,
   Beschreibung, Belegnummer, Mitarbeiter-ID, optional
   `signaturePngB64`, optional `belegBytesB64`, optional
   `stornoOfEntryId`.
2. **Audit-Event** in `audit.log`.
3. Bei **Monatsabschluss**: zusaetzlich
   `KassenbuchMonatsabschluss`-Record in
   `kassenbuch_monatsabschluesse_v1` mit `saldoStart`, `saldoEnde`,
   Unterschrift.

Beim Cloud-Sync landen Eintraege und Abschluss auf HiDrive unter
`teams/<teamId>/clients/<clientId>/kassenbuch/`.

### Saldo-Berechnung mit Rollover

Der Saldo zum Monatsanfang wird nicht jedes Mal neu aus Tag 0
berechnet (das waere nach zwei Jahren sehr langsam). Stattdessen:

1. System sucht den **letzten Monatsabschluss vor dem Zielmonat**
2. Nimmt dessen `saldoEnde` als Ausgangspunkt
3. Addiert alle Buchungen **nach dem Abschluss bis zum
   Zielmonatsanfang**

Wenn noch kein Abschluss existiert (frischer Klient), wird linear
von Tag 0 gerechnet. Das skaliert auch bei jahrelangen Historien.

### Rechtlicher Hintergrund kurz zusammengefasst

- **§90 SGB IX** / **§§1901/1908 BGB (Betreuung)**: Pflicht zur
  ordnungsgemaessen Verwaltung fremden Vermoegens durch Einrichtung
  bzw. Betreuer. Das Kassenbuch dokumentiert diese Verwaltung.
- **GoBD (Grundsaetze ordnungsmaessiger Buchfuehrung)**: Aenderungen
  muessen nachvollziehbar bleiben — deshalb Storno statt Edit.
- **Art. 9 DSGVO**: Gesundheits-**Details** (Diagnose, Medikamenten-
  name) duerfen nicht in der Kassen-Beschreibung stehen, da das
  Kassenbuch vom gesamten Team lesbar ist. Nur neutrale Bezeichnungen
  ("Apothekenzuzahlung", "Rezept") sind zulaessig.

## Buchungstypen

| Kategorie | Beschreibung |
|-----------|-------------|
| Eingang | Zufluss (Taschengeldauszahlung, Rueckerstattung, Zuwendung) |
| Taschengeld | Ausgabe an Klient fuer persoenlichen Gebrauch |
| Haushaltsgeld | Kuechenkasse, gemeinschaftliche Anschaffungen |
| Gesundheit | Apotheke, Zuzahlung |
| Freizeit | Kino, Ausflug, Hobby |
| Bekleidung | Kleidung, Schuhe |
| Verpflegung | Lebensmittel ausserhalb der WG-Kueche |
| Sonstiges | Alles andere, mit klarer Beschreibung |

Das Vorzeichen liegt am Betrag (positiv = Eingang, negativ = Ausgang), nicht an der Kategorie. So kann auch innerhalb einer Kategorie ein Storno-Eingang gebucht werden.

!!! danger "Kein Detailzustand bei Gesundheitsausgaben"
    Art. 9 DSGVO — keine Diagnosen, Medikamentennamen oder Therapieziele in die Beschreibung eines Kassenbucheintrags. Stattdessen nur "Apothekenkosten" oder "Zuzahlung". Details gehoeren in die geschuetzte Akte.

## Buchung erfassen

1. Im Klienten-Menue **Kassenbuch** oeffnen
2. **+ Neuer Eintrag**
3. Datum, Betrag, Kategorie, Beschreibung, ggf. Belegnummer ausfuellen
4. **Direkt freigeben** optional aktivieren, wenn die Buchung final ist
5. **Buchen**

## Freigabe und Unterschrift

Ein Eintrag ist **freigegeben**, sobald er unterzeichnet ist. Freigegebene Eintraege sind final — keine Aenderung mehr moeglich. Korrekturen erfolgen ausschliesslich ueber eine Stornobuchung (Kategorie *Eingang* oder entsprechender Ausgang mit umgekehrtem Vorzeichen, Beschreibung "Storno zu Beleg #...").

Beim Aktivieren von **Direkt freigeben** erscheint ein Unterschriftsfeld. Die Unterschrift wird als Bild gespeichert, im PDF-Monatsauszug an den freigegebenen Eintraegen gerendert und laesst sich bei einer Pruefung vorzeigen. Ohne Unterschrift laesst sich die Freigabe nicht abschicken.

## Monatsauszug als PDF

Im Kassenbuch-Screen **Monatsauszug exportieren** erzeugt eine PDF mit:

- Saldo Monatsanfang, Einzahlungen, Auszahlungen, Saldo Monatsende
- Einzelbuchungen tabellarisch mit fortlaufendem Saldo
- Unterschriftenblock der freigegebenen Eintraege
- Hinweis auf Freigabe-Charakter

Der Auszug eignet sich als monatlicher Kassennachweis gegenueber Klient, gesetzlicher Betreuung und Rechnungspruefung.

## Integration mit Rechnungswesen

Freigegebene Eintraege koennen in den XRechnung-Export uebernommen werden, sofern sie dem Klienten zuordenbar sind (z. B. Zuzahlungen). Details: [Berichte und Export](berichte.md).
