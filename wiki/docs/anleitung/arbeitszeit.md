# Arbeitszeit erfassen

## Uebersicht

Die Arbeitszeiterfassung ermoeglicht die taetigkeitsbasierte Zeiterfassung mit automatischer Berechnung der geleisteten Stunden.

!!! note "Berechtigung"
    Eigene Arbeitszeit erfassen koennen alle Mitarbeiter. Arbeitszeit anderer Mitarbeiter einsehen koennen nur Teamleitungen und Admins.

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
