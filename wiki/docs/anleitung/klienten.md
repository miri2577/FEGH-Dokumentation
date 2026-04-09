# Klienten verwalten

## Uebersicht

Der Klienten-Tab zeigt alle Klienten als durchsuchbare Liste mit Filteroptionen. Klienten sind farbkodiert und koennen nach verschiedenen Kriterien sortiert werden.

## Klient anlegen

!!! note "Berechtigung"
    Klienten anlegen koennen nur **Teamleitungen** und **Admins**. Mitarbeiter sehen den "Neuer Klient"-Button nicht.

Ein Klienten-Datensatz umfasst:

### Stammdaten

| Feld | Beschreibung |
|------|-------------|
| Name / Vorname / Nachname | Vollstaendiger Name des Klienten |
| Klienten-ID | Externe Identifikationsnummer |
| Geburtsdatum | Fuer Altersberechnung und Berichte |
| Betreuung seit | Beginn der Betreuung |

### Kostenuebernahme

| Feld | Beschreibung |
|------|-------------|
| Kostenuebernahme | Name des Kostentraegers |
| Kostenuebernahme von/bis | Gueltigkeitszeitraum |
| Fachleistungsstunden | Bewilligte Stunden |
| Fachleistungsintervall | Woechentlich, monatlich oder jaehrlich |
| Verbrauchte Stunden | Bereits geleistete Stunden |

### FLS-Kalkulation (Fachleistungsstunden)

Fuer jeden Klienten wird automatisch berechnet:

- **Verfuegbare Stunden** = Bewilligte - Verbrauchte Stunden
- **Gesamtarbeitszeit** = Verbrauchte Stunden x Kalkulationsfaktor (Standard: 1,33)
- **Abrechnungsbetrag** = min(Verbraucht, Bewilligt) x Stundensatz (Standard: 40 EUR)

Der Kalkulationsfaktor und Stundensatz koennen pro Klient ueberschrieben werden (Felder `kalkulationsfaktorOverride` und `stundensatzOverride`).

### Ziele und Klassifikation

| Feld | Beschreibung |
|------|-------------|
| TIB-Ziele | Teilhabeziele nach Berliner Teilhabeinstrument |
| Individuelle TIB-Ziele | Eigene Zieldefinitionen |
| ICF-Bereiche | Klassifikation nach ICF-Standard |
| Rechtsgrundlage | Rechtliche Basis der Leistung |
| Hilfe-Typ | Eingliederungshilfe oder Familienhilfe |

### Delegation

| Feld | Beschreibung |
|------|-------------|
| Vertreter 1 | Erste Vertretungsperson (Mitarbeiter-ID) |
| Vertreter 2 | Zweite Vertretungsperson (Mitarbeiter-ID) |

### Darstellung

Jeder Klient kann eine individuelle Farbe zugewiesen bekommen (`customColor` als Hex-Wert), die im Kalender und in Listen angezeigt wird. Es stehen 24 vordefinierte Farben zur Verfuegung.

## Klient bearbeiten

!!! note "Berechtigung"
    **Stammdaten** aendern koennen nur Teamleitungen und Admins. **Dokumentation** (Termine, Berichte) kann jeder Mitarbeiter bearbeiten.

## Klient loeschen

!!! warning "Berechtigung"
    Klienten loeschen koennen nur **Admins**. Die Loeschung ist unwiderruflich.

## Klient einem Team zuweisen

Admins koennen Klienten ueber den Verwaltung-Tab einem bestimmten Team zuweisen. Die Klientendaten werden verschluesselt im Team-Verzeichnis auf HiDrive abgelegt.
