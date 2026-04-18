# Strategie-Plan: Dienstplan → Wohnraum/Kassenbuch → PerSEH-Konnektor

Stand: 18.04.2026
Ziel: FEGH-Dokumentation schliesst die drei groessten Funktions-Luecken
gegenueber myneva.daarwin und aehnlichen Enterprise-Loesungen. Einstieg
pro Phase mit klarem MVP, danach inkrementeller Ausbau.

---

## Phase 1: Dienstplan-Modul

**Motivation:** Show-stopper fuer besonderes Wohnen, Tagesstaetten,
ambulante Dienste mit Schichtbetrieb. Ohne Dienstplan kein Verkauf
an Wohnheime / ABW-Traeger mit mehr als 10 MA.

**Business-Case:** Berliner Traeger besonderes Wohnen: 50-200 MA,
24/7-Betrieb, Frueh-/Spaet-/Nacht-Schichten, Tausch-Anfragen,
Feiertags-/Wochenend-Zuschlaege. Aktuell oft Excel/Printout +
Papier-Urlaubsantraege.

### 1a. Datenmodelle (neu)

`lib/models/schicht.dart`:
```dart
class Schicht {
  final String id;
  final String mitarbeiterId;
  final DateTime datum;
  final DateTime von, bis;
  final SchichtTyp typ; // frueh, spaet, nacht, zwischendienst, bereitschaft, frei
  final String? standortId; // welcher Standort
  final String? notiz;
  final SchichtStatus status; // geplant, bestaetigt, getauscht, getauscht_mit
  final String? getauschtMitMitarbeiterId;
  final String createdBy; // Teamleitung, Admin
}

enum SchichtTyp { frueh, spaet, nacht, zwischendienst, bereitschaft, frei }
enum SchichtStatus { geplant, bestaetigt, tauschangefragt, getauscht }
```

`lib/models/tauschanfrage.dart`:
```dart
class Tauschanfrage {
  final String id;
  final String schichtId;
  final String anfragendVon; // Mitarbeiter-ID
  final String angefragtBei; // Mitarbeiter-ID
  final String? begruendung;
  final TauschStatus status; // offen, akzeptiert, abgelehnt, zurueckgezogen
  final DateTime erstelltAm;
  final DateTime? entschiedenAm;
}
```

### 1b. Services

`lib/services/dienstplan_service.dart`:
- `generateMonatsplan(teamId, monat)` — aus Mitarbeiter-Verfuegbarkeit + Muster
- `checkConflicts(schicht)` — Doppelbelegung, Ruhezeit §5 ArbZG (11h), Hoechstarbeitszeit §3
- `applyTausch(anfrageId)` — nach beidseitiger Bestaetigung
- `exportICal(mitarbeiterId, monat)` — iCalendar-Datei fuer persoenliche Kalender
- `exportPDF(teamId, monat)` — Aushang-PDF im Dienstplan-Design

### 1c. Screens

- `lib/screens/dienstplan/dienstplan_screen.dart` — Monatskalender mit
  Mitarbeiter-Zeilen, Schicht-Zellen farbkodiert
- `lib/screens/dienstplan/schicht_editor_screen.dart` — Einzel-Schicht
  anlegen/bearbeiten, Tausch anfragen
- `lib/screens/dienstplan/tauschanfragen_screen.dart` — eingehende/
  ausgehende Anfragen verwalten

### 1d. Integration

- Arbeitszeit-Erfassung kann aus Schicht automatisch befuellt werden
  (bereits heute: `Arbeitszeit`, neu: `fromSchicht(schichtId)`-Konstruktor)
- Kalender-Tab zeigt Schichten farblich hinterlegt
- Push-Benachrichtigung bei neuen Tauschanfragen (spaeter)

### 1e. Aufwand

- Models + Services: 1-2 Wochen
- Screens: 2-3 Wochen (Monats-Matrix ist UI-intensiv)
- Tests + Polish: 1 Woche
- **Gesamt: ca. 4-6 Wochen MVP**

---

## Phase 2: Wohnraum-/Mietverwaltung + Kassenbuch/Taschengeld

**Motivation:** BTHG §42a SGB XII trennt Fach- und Existenzsicherungs-
leistungen. Fuer besonderes Wohnen zwingend dokumentationspflichtig:
Miete, Nebenkosten, Kaution, Haushaltsgeld, Taschengeld. myneva hat
dafuer eigene Module; ohne das verlieren wir Wohnheim-Ausschreibungen.

**Business-Case:** Traeger besonderes Wohnen betreut typisch 15-50
Klienten, verwaltet deren Wohnraum-Finanzen treuhaenderisch. Eine
Fehler-Auszahlung (zu viel Taschengeld / falsche NK-Abrechnung) ist
Regressrisiko. Muss lueckenlos dokumentiert sein.

### 2a. Datenmodelle

`lib/models/wohnraum.dart`:
```dart
class Wohnraum {
  final String id;
  final String clientId;
  final String adresse;
  final double kaltmiete;
  final double nebenkosten;
  final double kaution;
  final DateTime mietbeginn;
  final DateTime? mietende;
  final String? vermieter;
  final String? vertragsnummer;
}
```

`lib/models/kassenbuch_eintrag.dart`:
```dart
class KassenbuchEintrag {
  final String id;
  final String clientId;
  final DateTime datum;
  final double betrag; // positiv = Eingang, negativ = Ausgang
  final KassenbuchKategorie kategorie;
  final String beschreibung;
  final String? belegnummer;
  final String? quittungPfad; // PDF/Foto der Quittung
  final String erfasstVon; // Mitarbeiter-ID
  final String? unterzeichnetVon; // Klient oder Betreuer bei Entgegennahme
}

enum KassenbuchKategorie {
  taschengeld_auszahlung,
  haushaltsgeld_einkauf,
  gesundheit_apotheke,
  freizeit_kino_restaurant,
  bekleidung,
  sonstige_ausgabe,
  eingang_bar,
  eingang_sozialleistung,
}
```

`lib/models/mietabrechnung.dart`: Nebenkostenabrechnung monatlich/
jaehrlich mit Aufschluesselung Heiz/Wasser/Abfall/etc.

### 2b. Services

`lib/services/kassenbuch_service.dart`:
- `eintragErfassen(KassenbuchEintrag)` mit Unterschrift-Capture (Signatur-Pad)
- `saldoBerechnen(clientId, zeitraum)` — Kassenstand pro Klient
- `exportPDFTaschengeldQuittung(eintragId)` — unterschriebene Quittung als PDF
- `exportJahresabschluss(clientId, jahr)` — fuer Sozialamt/Betreuer

`lib/services/wohnraum_service.dart`:
- `mieteVerbuchen(monat)` — automatische monatliche Buchungen
- `nebenkostenabrechnung(clientId, jahr)` — aufgeschluesselte NK-Abrechnung

### 2c. Screens

- `lib/screens/wohnraum/wohnraum_uebersicht_screen.dart`
- `lib/screens/wohnraum/kassenbuch_screen.dart` — Liste mit Saldo-Header,
  Filter nach Kategorie/Zeitraum
- `lib/screens/wohnraum/eintrag_erfassen_screen.dart` mit Signatur-Pad
- `lib/screens/wohnraum/mietabrechnung_screen.dart`

### 2d. Rechtliche Absicherung

- Datenschutz: Kassenbuch-Daten sind besonders sensibel (Verhaltens-
  rueckschluesse moeglich); Zugriff nur fuer Teamleitung + beauftragte
  Mitarbeiter
- Archivierungspflicht: 10 Jahre nach HGB §257, 5 Jahre nach AO §147
- Audit-Log fuer jeden Eintrag zwingend (wer hat wann was gebucht)

### 2e. Aufwand

- Models + Services + PDF-Quittungen: 2-3 Wochen
- Screens + Signatur-Pad-Integration: 3-4 Wochen
- Mietverwaltung + NK-Abrechnung: 2 Wochen (algorithmisch)
- **Gesamt: ca. 7-9 Wochen MVP**

---

## Phase 3: PerSEH-Konnektor — Machbarkeitsanalyse

### 3.1 Was ist PerSEH?

**Wichtige Klarstellung: Der Name bezeichnet ZWEI Systeme.**

- **PerSEH Hessen** (urspruenglich, seit 2008) — IT-Verfahren des
  Landeswohlfahrtsverbandes Hessen (LWV). Seit 01.10.2020 durch
  **PiT Hessen** abgeloest, laeuft aber weiter ueber die PerSEH-
  Infrastruktur. Weiterentwicklung durch **ANLEI-Service GmbH**
  (LWV-Tochter, Kassel).
- **PerSEH NRW** — Web-basiertes DV-Verfahren von **LVR** und **LWL**,
  Huelle fuer das Bedarfsermittlungsinstrument **BEI_NRW**. Aktiver
  Roll-out. Zugriff fuer Leistungserbringer via LWL-Serviceportal
  (Citrix Unified Gateway) + LWL-Bena mit 2-FA.

**Kooperationsblock:** ANLEI/LWV + LVR/LWL + Bayern-Bezirke (Oberfranken,
Oberbayern, Schwaben) seit 2024 — faktisch der dominante Quasi-Standard
in der deutschen EGH-Digitalisierung.

**Rechtsgrundlage:** §118 SGB IX (ICF-orientiertes Bedarfsermittlungs-
instrument, BTHG 3. Reformstufe) + Landesrahmenvertraege.

### 3.2 Technische Realitaet

**Kernbefund:** PerSEH ist **primaer ein Webportal zum manuellen
Eintragen**. Eine offene REST-/SOAP-API fuer Drittanbieter existiert
**nicht oeffentlich dokumentiert**.

Es gibt eine **XML-Schnittstelle** (belegt durch LWL-Dokument
2019_05_15 "Information zu Schnittstelle LWL-Webverfahren PerSEH"),
aber:
- Kein oeffentliches XSD-Schema — bisherige Anbindungen bilateral
  im Rahmen von Projekten
- Kein XOeV-Standard "XBedarf" oder "XEGH" in KoSIT-Pipeline
  (Stand 2026) — bundesweite Normierung politisch blockiert, da
  Laender bewusst unterschiedliche Instrumente fahren
- Authentifizierung nur personengebunden (2-FA per E-Mail via
  Citrix Gateway), keine Maschinen-API
- Keine Sandbox, kein Entwicklerportal, kein Partnerprogramm
- Hessen-Variante: XML-Export existiert, laesst sich ins Portal
  wieder einlesen (Rolle "Einleser")

**BTHG-Kompass** (Umsetzungsbegleitung Deutscher Verein) lief bis
Dez 2024 aus, **ohne** bundesweiten Datenaustauschstandard
etabliert zu haben.

### 3.3 Vergleich andere Bundeslaender

| Land | Instrument | Plattform | API-Offenheit |
|------|-----------|-----------|---------------|
| NRW | BEI_NRW | PerSEH (LVR/LWL) | XML-Import bilateral |
| Hessen | PiT (vormals ITP) | PerSEH/ANLEI | XML-Import bilateral |
| Niedersachsen/Bremen | B.E.Ni 4.0 | Landesamt + Laemmerzahl | projektbasiert |
| **Berlin** | **TIB** | **Teilhabefachdienst, Fraunhofer FOKUS** | **Keine offene API** |
| Bayern | ANLEI-Verbund ab 2024 | ANLEI | uebernimmt NRW/Hessen-Muster |
| BW | KVJS-Instrumente | kein zentrales IT-System | keine API |
| SN/TH/BB/MV | ITP-Varianten | gemischt | ueberwiegend Portal |

**Fuer Berliner Traeger:** TIB hat **noch weniger** Schnittstellenreife
als PerSEH. Der Teilhabefachdienst arbeitet mit Modulformularen, die
Fraunhofer FOKUS prozessmodelliert hat — klassischer Workflow-Ansatz
ohne Drittanbieter-API.

### 3.4 Bestehende Konnektoren (Marktlage)

- **myneva**: wirbt mit "Integration landesspezifischer Bedarfs-
  ermittlungsinstrumente" — konkrete PerSEH-Anbindung nicht
  oeffentlich dokumentiert, wohl projektbezogen bilateral
- **VRG MICOS**: EGH-positioniert, keine dokumentierte PerSEH-Spec
- **Connext Vivendi**: Marktfuehrer Sozialwirtschaft, keine
  oeffentliche PerSEH-Referenz
- **Laemmerzahl**: in Arbeitsgruppen zu B.E.Ni aktiv, analog
  bilaterale PerSEH-Kopplungen moeglich

**Dokumentierte Integrationen sind Mangelware.** Risiko (unklare
Spec) und Chance (First-Mover moeglich) zugleich.

### 3.5 Aufwand-Schaetzung

- **Erste NRW-XML-Anbindung (nur Export Richtung PerSEH):**
  4-8 Personenmonate (2-3 PM Spec-Beschaffung + Test-Koordination
  mit LWL.IT, 2-4 PM Entwicklung, 1 PM Test/Abnahme)
- Pro weiteres Bundesland (Berlin TIB, Niedersachsen B.E.Ni):
  +3-5 PM wegen abweichender Instrumente
- Laufende Wartung: 0,5-1 PM/Jahr pro Anbindung

**Keine oeffentliche Foerderung** fuer Softwarehersteller gefunden.
BMAS-Umsetzungsbegleitung lief aus, REACT-EU ebenso. Laender-
foerderung adressiert Traeger, nicht Hersteller. Finanzierungsquelle
muss vom Kunden / Traegerverbund kommen.

### 3.6 Risiken

- **Rechtlich:** Kostentraeger empfaengt Daten formal vom Traeger,
  nicht vom Drittanbieter-Tool. FEGH bleibt Software — Traeger
  rechtlicher Absender. Auftragsverarbeitung nach Art. 28 DSGVO
  zwingend.
- **Haftung bei Fehldaten:** liegt beim Traeger; FEGH braucht saubere
  Validierung + Audit-Trail (bereits vorhanden).
- **Versionierung:** Keine semantische API-Versionierung — Portal-
  Aenderungen koennen XML-Struktur brechen. Monitoring LWL-Release-
  Notes noetig.
- **Politisches Risiko:** Wenn ANLEI/LVR/LWL ein offizielles
  Partnerprogramm launcht (Zertifizierung, Gebuehren), aendert
  sich Spielfeld ueber Nacht.

### 3.7 Ampel-Bewertung

| Horizont | Ampel | Begruendung |
|----------|-------|-------------|
| **Kurz (0-12 M)** | **ROT** | Keine API, keine Sandbox, kein Partnerprogramm. Nur bilateral mit Referenzkunde. Fuer Berliner Zielmarkt zudem falsches System (TIB statt PerSEH). |
| **Mittel (1-3 J)** | **GELB** | ANLEI/LVR/LWL-Verbund + Bayern waechst. Formale Spec zunehmend wahrscheinlich. PDF-Vorausfuellung schon heute machbar, lohnt bei NRW/Hessen-Kunden. |
| **Lang (3-5+ J)** | **GRUEN (bedingt)** | Kommt ein XOeV-Standard "XEGH" oder ANLEI-Partnerprogramm, ist ein frueher sauberer Konnektor strategischer Vorsprung. |

### 3.8 Empfohlener Umsetzungspfad

**Statt sofortigen API-Konnektor: PDF-Formular-Vorausfuellung als
Zwischenschritt** — rechtssicher, ohne API machbar, sofortiger
Kundennutzen. Liefert gleichzeitig das Datenmapping, das spaeter
fuer XML gebraucht wird.

**Phase 3a — PDF-Vorausfuellung (3-4 Monate, 2 PM):**
- Offizielle Landes-PDFs besorgen: BEI_NRW, TIB (Berlin), PiT Hessen,
  B.E.Ni Niedersachsen
- Feld-Mapping definieren: `bei_nrw.dart` / `generisch_icf.dart` auf
  Landesinstrument-Felder (teils schon vorhanden)
- PDF-Fill via Syncfusion (bereits im Einsatz fuer Formular 101)
- Plausi-Check vor Export (Pflichtfelder, ICF-Code-Validitaet)
- UI: "Landesformular exportieren" unter Berichte

**Phase 3b — Beziehungsaufbau (parallel, 6-12 Monate):**
- LWL.IT Service Abteilung + LWL-Inklusionsamt Soziale Teilhabe
- ANLEI-Service GmbH Kassel
- Senatsverwaltung Soziales Berlin / Teilhabefachdienste fuer TIB
- Ziel: Schnittstellen-Spec + Sandbox-Zugang offiziell anfragen,
  mit Rueckendeckung eines Referenztraegers

**Phase 3c — XML-Konnektor NRW (wenn Phase 3b erfolgreich, 4-8 PM):**
- Bilaterale Spec mit LWL.IT abstimmen
- BEI_NRW-XML-Export implementieren
- Pilot mit 1 Referenztraeger, 1 Kostentraeger
- Foerderantrag an Berliner Senat oder Bezirk NRW parallel vorbereiten

**Phase 3d — Monitoring:**
- Abonnement LWL-/LVR-/ANLEI-Newsletter
- DTVP/TED-Vergabealarme auf "PerSEH", "BEI_NRW",
  "Bedarfsermittlung", "Teilhabeplanverfahren"
- Ausschreibungen enthalten oft detaillierte technische Specs

### 3.9 Empfehlung fuer FEGH

**Kurzfassung:** Phase 3a (PDF-Vorausfuellung) **ja** — niedriges
Risiko, hoher Nutzen, Mapping baut Basis fuer spaeter. Phase 3c
(XML-Konnektor) **nicht vor 2027**, erst wenn Referenzkunde in
NRW oder Hessen gewonnen + Kontakt zu LWL.IT oder ANLEI besteht.

Fuer **primaeren Berliner Zielmarkt** ist PerSEH zweitrangig — TIB-
Portal hat noch weniger Reife. Die PDF-Vorausfuellung fuer TIB-
Formulare (Analogie zu Formular 101, das bereits laeuft) ist fuer
Berlin-Kunden wertvoller als ein PerSEH-XML-Konnektor.

**Sequenz-Empfehlung:** Phase 1 (Dienstplan) + Phase 2 (Wohnraum)
zuerst — die sind Show-stopper beim Kundengewinn. Phase 3a (PDF-
Vorausfuellung Landesformulare) danach oder parallel. Phase 3c
(XML) nur mit konkretem Anchor-Kunden.

---

## Gesamt-Zeitplan

```
Phase 1 Dienstplan           ───── 4-6 Wochen ──────┐
Phase 2 Wohnraum/Kassenbuch  ────────── 7-9 Wochen ─┤
Phase 3a PDF-Vorausfuellung  ─────── 3-4 Monate ────┤─> Release 2.0
Phase 3b Beziehungsaufbau    (parallel, 6-12 Monate)│
Phase 3c XML-Konnektor NRW   (bedingt, 4-8 PM)      ├─> Release 2.5
```

Phase 1 und 2 koennen parallel laufen (unterschiedliche Bereiche).
Phase 3a beginnt mit dem Mapping aus Phase 2 und nutzt bestehende
Syncfusion-PDF-Infrastruktur. Phase 3c ist an Referenzkunden
gekoppelt und kann 1-2 Jahre verzoegern.

## Priorisierung nach Kunde

| Kundentyp | Dienstplan | Wohnraum | PerSEH |
|-----------|-----------|----------|--------|
| Ambulante Dienste (ABW) | mittel | niedrig | hoch (wenn NRW) |
| Besonderes Wohnen | hoch | hoch | hoch |
| Tagesstaetten | hoch | niedrig | mittel |
| Familienhilfe/SPFH | niedrig | niedrig | niedrig |
| Berliner Traeger | mittel | hoch | niedrig (BE nicht bei PerSEH) |

**Empfehlung:** Phase 1 und 2 sofort starten, Phase 3 erst nach
Analyse entscheiden. Fuer Berliner Zielmarkt ist PerSEH weniger
relevant als Dienstplan+Wohnraum.
