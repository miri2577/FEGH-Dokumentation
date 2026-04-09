# Termine und Kalender

## Kalenderansicht

Der Kalender zeigt Termine in einer **Wochen- oder Monatsansicht** mit folgenden Features:

- Farbkodierte Klienten (24 einzigartige Farben)
- Ueberlappende Termine mit mehrspaltiger Darstellung
- Praezise Zeitpositionierung (80px pro Stunde)
- Klienten-Farbelegende
- Animierter Seitenaufbau (Staggered Animations)

## Termin erstellen

Ein neuer Termin kann ueber den **"+"**-Button auf dem Dashboard oder im Kalender erstellt werden.

!!! note "Berechtigung"
    Termine erstellen koennen alle Mitarbeiter und Teamleitungen. Pruefer (Auditor) haben nur Lesezugriff.

### Termin-Felder

| Feld | Beschreibung |
|------|-------------|
| Klient | Zugeordneter Klient |
| Datum | Termin-Datum |
| Startzeit / Endzeit | Zeitraum des Termins |
| Termin-Art | Typ des Termins (siehe unten) |
| Notizen | Freitext-Dokumentation |
| Aufgezeichneter Text | Spracherkennung-Transkript (falls verfuegbar) |
| Berufsgruppe | Berufliche Zuordnung des Mitarbeiters |
| Eingliederung | Art der Eingliederung |

### Termin-Arten

| Art | Beschreibung |
|-----|-------------|
| Kliententermin | Direkte Arbeit mit dem Klienten |
| Buero | Bueroarbeit |
| Dokumentation | Dokumentationszeit |
| Supervision | Supervision |
| Teamsitzung | Teambesprechung |
| Fortbildung | Weiterbildung |
| Fahrtzeit | Fahrzeit (verknuepfbar mit Fahrweg-Datensatz) |
| Sonstige | Andere Taetigkeiten |

### Indirekte Termine

Bei indirekten Terminen (z.B. Buero, Teamsitzung) kann die Zeit auf mehrere Klienten aufgeteilt werden ueber das Feld `clientAllocations`.

### Zielverknuepfung

Termine koennen mit TIB-Zielen und ICF-Bereichen verknuepft werden. Fuer jedes Ziel kann eine Minutenzahl angegeben werden (`tibZielMinuten`), um die Zeitverteilung pro Ziel zu dokumentieren.

### Fahrwege

Hin- und Rueckfahrten koennen mit Fahrweg-Datensaetzen verknuepft werden (`fahrwegHinId`, `fahrwegRueckId`). Fahrwege erfassen:

- Start- und Zielstandort
- Distanz in Kilometern
- Verknuepfung mit Termin und Klient

Die Distanzberechnung kann optional ueber die **OpenRouteService API** automatisiert werden. Berechnete Distanzen werden gecacht.

## Termindetails

Ein Klick auf einen Termin oeffnet die Detailansicht mit allen Feldern und verknuepften Fahrwegen.

## Dokumentationsuebersicht

Der Tab "Dokumentation" zeigt alle Termine chronologisch mit Volltextsuche. Dokumentationen koennen kopiert und durchsucht werden.
