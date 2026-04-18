# Plan: Dienstplan-Modul (optional)

Stand: 18.04.2026
Status: **Entscheidung offen** — abhaengig vom Zielmarkt

---

## 1. Soll das ueberhaupt gebaut werden?

### Pro: Ja, wenn Zielmarkt stationaer/tagesstrukturierend

- **Besonderes Wohnen** (stationaer, 24/7): zwingend Schichten
  Frueh/Spaet/Nacht, Wochenend-/Feiertags-Zuschlaege
- **Tagesstaetten**: feste Arbeitszeiten, aber Tausch/Krankenvertretung
- **WfbM-Foerdergruppen**: aehnlich Tagesstaette
- **Mischtraeger** (ABW + besonderes Wohnen + TS): brauchen
  mindestens fuer den stationaeren Teil Dienstplan
- Ohne Dienstplan-Modul keine Ausschreibung gegen myneva/Vivendi/MICOS
  zu gewinnen, wenn stationaere Komponente dabei

### Contra: Nein, wenn Zielmarkt rein ambulant

- **Ambulant Betreutes Wohnen (ABW)**: Mitarbeiter arbeiten
  einzelfallbezogen nach Klient-Terminen, keine Schichtbetrieb
- **Familienhilfe (SPFH)**: aehnlich ABW, Termine nach Bedarf
- **EGH im ambulanten Feld**: Terminkoordination laeuft ueber
  Kalender (bereits implementiert), nicht ueber Schichten
- Mitarbeiter tracken Arbeitszeit heute ueber `Arbeitszeit`-Modell,
  genehmigt vom Admin (Approval-Screen existiert)
- Fuer rein ambulante Traeger ist der vorhandene Kalender +
  Arbeitszeit-Genehmigung **ausreichend**

### Mittelweg: Leichtgewichtige Abwesenheits-Uebersicht

Statt eines vollwertigen Dienstplan-Moduls koennte genuegen:

- **Abwesenheits-Uebersicht**: wer ist heute/diese Woche wo (Urlaub,
  Krank, Fortbildung, im Aussendienst)
- Basiert auf bereits vorhandenem `FreizeitAntrag` + `Arbeitszeit`
- Nur ein neuer Read-Only-Screen + bestehende Daten
- Aufwand: ca. 1 Woche
- Deckt den ambulanten Use-Case ab, ohne Schicht-Logik

**Empfehlung:** Leichtgewichtigen Abwesenheits-Screen bauen. Vollwertiges
Dienstplan-Modul zurueckstellen bis konkreter stationaerer Kunde
anfragt.

---

## 2. Vollwertiges Dienstplan-Modul (falls doch beschlossen)

### 2.1 Datenmodelle

`lib/models/schicht.dart`:
```dart
enum SchichtTyp {
  frueh,      // 06:00-14:00 typisch
  spaet,      // 14:00-22:00
  nacht,      // 22:00-06:00
  zwischen,   // individuelle Zeiten
  bereitschaft, // Rufbereitschaft
  frei,       // explizit frei (zur Abgrenzung)
}

enum SchichtStatus {
  geplant,          // von Teamleitung erstellt
  bestaetigt,       // MA hat bestaetigt
  tauschangefragt,  // Tausch-Antrag offen
  getauscht,        // erfolgreich getauscht
  ausgefallen,      // krank/storniert
}

class Schicht {
  final String id;
  final String mitarbeiterId;
  final String? standortId;   // welcher Standort/Wohnheim
  final DateTime datum;
  final DateTime von;
  final DateTime bis;
  final SchichtTyp typ;
  final SchichtStatus status;
  final String? getauschtMitMitarbeiterId;
  final String? notiz;
  final String erstelltVon;   // Mitarbeiter-ID
  final DateTime erstelltAm;
  final DateTime updatedAt;
}
```

`lib/models/tauschanfrage.dart`:
```dart
enum TauschStatus { offen, akzeptiert, abgelehnt, zurueckgezogen }

class Tauschanfrage {
  final String id;
  final String schichtId;
  final String anfragendVon;  // MA-ID
  final String angefragtBei;  // MA-ID
  final String? begruendung;
  final TauschStatus status;
  final DateTime erstelltAm;
  final DateTime? entschiedenAm;
  final String? entscheidungsNotiz;
}
```

`lib/models/dienstplan_muster.dart` (optional, fuer wiederkehrende
Plaene):
```dart
class DienstplanMuster {
  final String id;
  final String name;          // "Standard Wohnheim Lichtenberg"
  final Map<int, List<SchichtMusterEintrag>> wochenplan;
  // key: Wochentag 1-7, value: Schichten dieses Tages
}

class SchichtMusterEintrag {
  final SchichtTyp typ;
  final TimeOfDay von;
  final TimeOfDay bis;
  final int anzahlMitarbeiter;
  final String? positionBeschreibung; // "Fruehdienst WG 1"
}
```

### 2.2 Services

`lib/services/dienstplan_service.dart`:

**Generierung:**
- `generateMonatsplan(teamId, monat, musterId?)` — aus Muster +
  Mitarbeiter-Verfuegbarkeit automatisch fuellen
- `addSchicht(Schicht)` / `updateSchicht` / `deleteSchicht`

**Validierung (§3, §5 ArbZG):**
- `checkConflicts(schicht)` prueft:
  - Doppelbelegung eines Mitarbeiters
  - Ruhezeit §5 ArbZG: min. 11h zwischen Schichten
  - Hoechstarbeitszeit §3 ArbZG: 8h/Tag, 48h/Woche
  - Urlaub/Krankheit aus `FreizeitAntrag` einbeziehen

**Tausch-Workflow:**
- `anfrageErstellen(Tauschanfrage)` — Benachrichtigung an Ziel-MA
- `anfrageAkzeptieren(anfrageId)` — beide Schichten tauschen
- `anfrageAblehnen(anfrageId, grund?)`

**Export:**
- `exportICal(mitarbeiterId, zeitraum)` — RFC 5545 iCalendar-Datei
  fuer Handy-Kalender
- `exportPDF(teamId, monat)` — Aushang-PDF (DIN A3 quer, mit
  Mitarbeiter-Zeilen und Schicht-Zellen farbig)
- `exportCSV(teamId, monat)` — fuer Lohnbuchhaltung

### 2.3 Screens

`lib/screens/dienstplan/dienstplan_screen.dart`:
- **Monats-Matrix**: Zeilen = Mitarbeiter, Spalten = Tage
- Schicht-Zellen farbkodiert nach SchichtTyp
- Filter: Team, Standort, einzelner MA
- Toolbar: Muster laden, Monat generieren, PDF exportieren
- Responsive: Mobile = Liste pro Tag, Desktop = Matrix

`lib/screens/dienstplan/schicht_editor_screen.dart`:
- Einzelne Schicht anlegen/aendern
- MA-Dropdown, Standort-Dropdown, Zeiten
- Konflikt-Warnung live (Ruhezeit verletzt, Doppelbelegung)

`lib/screens/dienstplan/tauschanfragen_screen.dart`:
- Tab 1: eingehende Anfragen
- Tab 2: ausgehende Anfragen
- Tab 3: Historie

`lib/screens/dienstplan/muster_verwaltung_screen.dart`:
- Dienstplan-Muster anlegen und bearbeiten
- Duplikate, Copy-Paste zwischen Mustern

### 2.4 Integration mit bestehenden Modulen

**Arbeitszeit-Erfassung:**
- Neue Methode `Arbeitszeit.fromSchicht(Schicht)` — wenn ein MA
  auf "Dienst angetreten" tippt, wird aus geplanter Schicht
  die Ist-Arbeitszeit erstellt
- Ist-/Soll-Vergleich wird moeglich (heute nur manuell)

**Kalender:**
- Schichten werden als zusaetzliche Ebene im Kalender angezeigt
  (neben Klient-Terminen)
- Unterscheidbar durch Farbe/Icon

**Benachrichtigungen:**
- Neue Tauschanfrage → Push an Ziel-MA (wenn Matrix-Chat vorhanden)
- Krankmeldung → automatischer Vorschlag: Vertretung aus Team
  angeblich frei

**Audit-Log:**
- Schicht-Erstellung, Aenderung, Tausch: `logDienstplanChange`
- Teamleitung haftet fuer korrekten Plan — Nachweis wichtig

### 2.5 Rollen/Rechte

- **Teamleitung**: Plan erstellen, aendern, Tausch genehmigen
- **Mitarbeiter**: eigene Schichten sehen, Tausch anfragen, Eintritt bestaetigen
- **Admin**: alle Teams, alle Plaene, Export
- **Pruefer**: Read-Only-Sicht (fuer MDK/Heimaufsicht)

### 2.6 Aufwand-Schaetzung

| Schritt | Aufwand |
|---------|---------|
| Models + JSON + build_runner | 2 Tage |
| Service: Generierung + Validierung | 3-4 Tage |
| Service: Tausch-Workflow | 2 Tage |
| Service: iCal/PDF/CSV-Export | 2-3 Tage |
| UI: Monats-Matrix (Desktop) | 4-5 Tage |
| UI: Monats-Matrix (Mobile) | 2-3 Tage |
| UI: Schicht-Editor | 2 Tage |
| UI: Tauschanfragen | 2 Tage |
| UI: Muster-Verwaltung | 3 Tage |
| Integration Arbeitszeit + Kalender | 2 Tage |
| Tests + Polish | 3-4 Tage |
| **Gesamt MVP** | **ca. 27-32 Arbeitstage (5-6 Wochen)** |

### 2.7 Abgrenzung zu Lohnbuchhaltung

**NICHT** Teil dieses Moduls:
- Lohnabrechnung selbst (DATEV, Lexoffice)
- Zuschlagsberechnung (Nacht/Sonn-/Feiertags)
- Sozialversicherungs-Meldungen

**ABER:** CSV-Export mit Stunden pro MA pro Zuschlagskategorie
(Nacht, Sonntag, Feiertag) — Daten-Lieferant fuer externe
Lohnsoftware.

---

## 3. Leichtgewichtige Alternative: Abwesenheits-Uebersicht

**Wenn keine volle Dienstplanung noetig ist:**

### 3.1 Neuer Screen `abwesenheiten_screen.dart`

- Kalender-Widget (bereits vorhanden via Syncfusion)
- Farbcode pro MA + Grund (Urlaub, Krank, Fortbildung, Aussendienst)
- Filter: Team, Zeitraum
- Nur Read-Only — Eingabe erfolgt wie bisher ueber
  `FreizeitAntrag`-Screen

### 3.2 Heute-Widget fuer Dashboard

- Kompakte Card "Heute abwesend: 3 MA"
- Namen + Grund + bis-Datum
- Quick-Link zum Abwesenheits-Screen

### 3.3 Aufwand

- Model: nichts neu — bestehende `FreizeitAntrag`-Daten aggregieren
- Service-Erweiterung: `getAbwesenheiten(zeitraum)` in AppProvider
- Screen: ca. 3-4 Tage
- Dashboard-Widget: 0,5 Tage
- Tests + Polish: 1 Tag
- **Gesamt: ca. 1 Woche**

---

## 4. Entscheidungsmatrix

| Kriterium | Volles Dienstplan-Modul | Abwesenheits-Uebersicht |
|-----------|-------------------------|-------------------------|
| Aufwand | 5-6 Wochen | 1 Woche |
| Zielgruppe | Stationaere Traeger | Ambulante Traeger |
| Market-Fit Berlin (ambulant) | niedrig | hoch |
| Market-Fit bundesweit stationaer | hoch | niedrig |
| Konkurrenz-Alleinstellung | niedrig (myneva hat GO ON) | niedrig (trivial) |
| Pflegestatus fuer Angebot | Must-have fuer stationaer | Nice-to-have |
| Risiko Over-Engineering | hoch | gering |

## 5. Empfehlung

**Schritt 1:** Abwesenheits-Uebersicht bauen (1 Woche) — liefert 80%
des Nutzens fuer ambulanten Berliner Zielmarkt, Low Risk.

**Schritt 2:** Volles Dienstplan-Modul **zurueckstellen**. Erst
umsetzen, wenn ein konkreter stationaerer Traeger (Wohnheim,
Tagesstaette) FEGH testet und das als Show-stopper meldet.

**Schritt 3:** Falls dann gebaut, Zeitschaetzung 5-6 Wochen
einplanen.

Diese Entscheidung faellt zu Gunsten von:
- Fokus auf Berliner ambulanten Zielmarkt
- Ressourcen fuer Wohnraum/Kassenbuch (Phase 2) und PDF-
  Vorausfuellung (Phase 3a) freihalten
- Vermeidung von Over-Engineering fuer hypothetische Kunden
