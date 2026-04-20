# Arbeitszeit erfassen

## Uebersicht

Die Arbeitszeiterfassung ermoeglicht die taetigkeitsbasierte Zeiterfassung mit automatischer Berechnung der geleisteten Stunden.

!!! note "Berechtigung"
    Eigene Arbeitszeit erfassen koennen alle Mitarbeiter. Arbeitszeit anderer Mitarbeiter einsehen koennen nur Teamleitungen und Admins.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Ein Betreuer in der Eingliederungshilfe muss Arbeitszeit aus **drei
Perspektiven** dokumentieren:

1. **Arbeitsrechtlich** (ArbZG) — Beginn/Ende/Pause, Einhaltung der
   10h-Obergrenze und 11h-Ruhezeit.
2. **Abrechnungsrechtlich** (FLS gegenueber Traeger) — nur bestimmte
   Kategorien sind abrechnungsfaehig; Dokumentationszeiten werden
   pro Klient aufgeteilt.
3. **Organisatorisch** (Lohnbuchhaltung, Urlaubs-/Krankheitssalden,
   Schichtabgleich) — wer war wann wo.

Ohne strukturierte Zeiterfassung werden alle drei entweder vergessen
oder inkonsistent gefuehrt (Excel fuer Lohn, Word-Dokumentation fuer
FLS, Papier fuer Arbeitszeit). Die App buendelt alles in **einer
Eingabe** — der Mitarbeiter macht einen Eintrag mit Taetigkeitstyp,
Start/Ende und optionaler Klientenzuordnung; das System leitet alle
drei Sichten automatisch ab.

### Konkretes Szenario: Ein normaler Arbeitstag von Mitarbeiter Tom

**07:55 Uhr.** Tom betritt die Einrichtung, tippt in der App
`Arbeitszeit → Start`:

- Taetigkeit: **Betreuung**
- Klient: Herr K.
- (Startzeit wird automatisch gesetzt)

**09:30 Uhr.** Herr K. hat seinen Termin beim Arzt. Tom beendet
den Klienten-Eintrag (`Stop`). System speichert: **1h 35min
Betreuung bei Herrn K.**

Tom startet sofort einen neuen Eintrag:

- Taetigkeit: **Dokumentation**
- Klient-Aufteilung: Herr K. 70 %, Frau L. 30 % (Tom hat
  Verlaufsbericht beider Klienten zu aktualisieren)

**11:00 Uhr.** Teamsitzung:

- Taetigkeit: **Teamsitzung**
- Kein Klient (organisationsbezogen)

**12:00 Uhr — 12:30 Uhr.** Mittagspause. Tom klickt `Pause` → System
unterbricht die Zeiterfassung.

**12:30 Uhr.** Weiter mit Klienten: **Betreuung** bei Frau L.

**15:15 Uhr.** Fahrt zu Herrn K.s Zahnarzt:

- Taetigkeit: **Fahrt**
- Klient: Herr K.

**15:45 Uhr.** Ankunft, Termin:

- Taetigkeit: **Betreuung**

**16:30 Uhr.** Feierabend. `Stop`.

**Was die App im Hintergrund berechnet:**

| Abrechnungs-Sicht | Stunden |
|-------------------|---------|
| Arbeitszeit heute (brutto) | 8,5 h |
| Minus Pause | 0,5 h |
| Ist-Zeit gesamt | 8,0 h |
| Davon FLS-relevant: Betreuung + Dokumentation + Fahrt | 6,25 h |
| Davon nicht FLS: Teamsitzung | 1,75 h |
| Anteil Herr K. (aus Kategorien + Aufteilungen) | 4,1 h |
| Anteil Frau L. | 2,15 h |

Am Monatsende wandert 4,1 h × FLS-Satz in die Rechnung fuer Herrn K.,
2,15 h × FLS-Satz fuer Frau L. Die 1,75 h Teamsitzung werden nicht
abgerechnet — sie sind im Stundensatz eingepreist. Aber sie stehen
auf Toms Lohnnachweis.

### Taetigkeitstypen im Detail

Die Kategorisierung ist nicht kosmetisch — sie ist **abrechnungs-
entscheidend**:

| Typ | FLS-relevant | Klient-Pflicht | Typisch wann |
|-----|--------------|----------------|--------------|
| **Betreuung** | ja | ja | Direkter Klientenkontakt |
| **Buero (mit Fallbezug)** | ja | ja (ggf. Aufteilung) | Email an Sozialamt, Telefonat |
| **Dokumentation** | ja | ja (ggf. Aufteilung) | Verlaufsbericht, Pflegedoku |
| **Fahrt** | bundeslaender-spezifisch | ja | Klient-bezogene Fahrt |
| **Verwaltung** | nein | nein | Buero ohne Fallbezug |
| **Fortbildung** | nein | nein | Schulung, Weiterbildung |
| **Teamsitzung** | nein | nein | Interne Besprechung |
| **Sonstige** | nein | Freitext | Alles andere |

### ArbZG-Konflikt-Check automatisch

Beim Speichern eines Eintrags prueft die App gegen die relevanten
Paragraphen:

| Regel | Was geprueft wird | Wirkung |
|-------|-------------------|---------|
| **§3 ArbZG** (taegliche Hoechstzeit) | Eintrag + bestehende Zeiten dieses Tages > 10 h? | Warnung |
| **§5 ArbZG** (Ruhezeit) | Weniger als 11 h zwischen Ende gestern und Beginn heute? | Warnung |
| **§4 ArbZG** (Pausen) | Mehr als 6 h ohne dokumentierte Pause? | Warnung |
| Doppelbelegung | Zeitueberschneidung mit bestehender Zeit? | Blockiert |

Teamleitung sieht im Dashboard bundeslaenderweit die Mitarbeiter,
die diese Warnungen produzieren — als Grundlage fuer
Dienstplananpassungen.

### Automatische Berechnung der Kennzahlen

Die App berechnet aus dem Roh-Log:

- **Arbeitszeit-Dauer**: Ende - Start (Brutto).
- **Pause** eines Tages: Summe der Pausen-Segmente.
- **Netto-Arbeitszeit**: Brutto − Pause (Dezimal).
- **Monats-Soll** aus Wochenarbeitszeit × Arbeitstage.
- **Saldo**: Ist − Soll (Plusstunden-Konto).
- **FLS-Summe pro Klient**: aus abrechnungsfaehigen Kategorien +
  Klient-Aufteilungen.
- **Ueberstunden**: Ist > Soll mit Zuschlagsfaktor (je nach
  Schichttyp, siehe Dienstplan).

### Rechtlicher Hintergrund

- **§3 ArbZG** — Arbeitszeit max. 8 h werktaeglich, ausnahmsweise
  10 h, mit Ausgleich binnen 6 Monaten.
- **§4 ArbZG** — mindestens 30 min Pause bei > 6 h, 45 min bei > 9 h.
- **§5 ArbZG** — mind. 11 h ununterbrochene Ruhezeit zwischen zwei
  Arbeitsschichten.
- **§16 ArbZG** — Aufzeichnungspflicht: Arbeitszeit muss
  dokumentiert werden und mindestens 2 Jahre aufbewahrt.
- **§87 Abs. 1 Nr. 2 BetrVG** — Betriebsrat hat Mitbestimmungsrecht
  bei Zeiterfassungssystemen; die Einrichtungs-Einstellung muss
  entsprechend abgestimmt sein.
- **EuGH-Urteil C-55/18 (2019)** — Arbeitgeber sind zur
  objektiven, verlaesslichen und zugaenglichen Zeiterfassung aller
  Mitarbeiter verpflichtet.

## Arbeitszeit-Eintrag

| Feld | Beschreibung |
|------|-------------|
| Datum | Tag der Arbeitszeit |
| Startzeit | Beginn der Taetigkeit |
| Endzeit | Ende der Taetigkeit |
| Taetigkeit | Art der Taetigkeit (siehe unten) |
| Notizen | Optionale Anmerkungen |
| Klient | Optionale Klienten-Verknuepfung |
| Termin | Optionale Termin-Verknuepfung |

## Taetigkeitstypen

| Typ | Beschreibung |
|-----|-------------|
| Betreuung | Direkte Betreuungsarbeit |
| Buero | Bueroarbeit und Verwaltung |
| Fahrt | Fahrzeit zwischen Standorten |
| Dokumentation | Dokumentationsarbeit |
| Verwaltung | Administrative Taetigkeiten |
| Fortbildung | Weiterbildung |
| Teamsitzung | Teambesprechungen |
| Sonstige | Andere Taetigkeiten |

Zusaetzlich gibt es vordefinierte Taetigkeitsbezeichnungen fuer Eingliederungshilfe und Familienhilfe.

## Automatische Berechnung

- **Arbeitszeit** (Dauer): Differenz zwischen Start- und Endzeit
- **Arbeitsstunden** (Dezimal): Dauer als Dezimalzahl fuer Berichte

## Statistiken

Der Arbeitszeit-Tab zeigt:

- Geleistete Stunden pro Zeitraum
- Verteilung nach Taetigkeitstyp
- Soll/Ist-Vergleich basierend auf der eingestellten Wochenarbeitszeit (Standard: 40 Stunden)

## Export

Arbeitszeitdaten koennen als CSV oder JSON exportiert werden. Der Export enthaelt alle erfassten Felder inklusive verknuepfter Klienten und Termine.
