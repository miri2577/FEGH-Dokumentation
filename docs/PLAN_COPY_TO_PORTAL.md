# Plan: Copy-to-Portal Feature

**Status:** Zurueckgestellt nach User-Wunsch am 17.04.2026.
**Motivation:** Leistungserbringer muessen Daten manuell in Webportale eintragen (PerSEH, ANLEI, KVJS, LS-EH-NI, PROSOZ). Die Felder ueberlappen stark - ein "Portal-Spickzettel" mit Tap-to-Copy spart Zeit und vermeidet Uebertragungsfehler.

## Basis-Daten der App (bereits vorhanden)

Die App erfasst bereits alle relevanten Felder in strukturierter Form:
- **Client-Stammdaten**: Name, Vorname, Geburtsdatum, klientenId (Fallnummer)
- **Leistungszeitraum**: Appointment-Modell (startTime, endTime, duration)
- **Fachleistungsstunden**: Appointment.fachleistungsstunden, Client.fachleistungsstunden
- **Ziele**: Teilhabeziel-Modell (SMART, Prioritaet, ICF, Kategorie)
- **Zielerreichung**: GasBewertung (-2 bis +2, entspricht 5er-Skala)
- **Wirkungsbeschreibung**: POS-Messungen + Wirksamkeitsbericht
- **An-/Abwesenheit**: Appointment + Arbeitszeit
- **ICF-Bereich**: Client.icfBereiche + Teilhabeziel.icfBereich
- **Bezugsbetreuer**: Client.vertreter1Id, erstelltVon in Teilhabeziel

## Geplante Portal-Presets

### Prio 1: PerSEH (NRW/Hessen)

Felder in der Reihenfolge, wie sie im PerSEH-Webformular erscheinen
(Reihenfolge muss anhand echter Login-Ansicht validiert werden, vgl. Hinweis Recherche):

1. Fallnummer Kostentraeger -> client.klientenId
2. Name, Vorname, Geburtsdatum -> client.name, vorname, geburtsdatum
3. Modulzuordnung (Modul 1-5 NRW) -> aus Leistungstyp ableitbar, UI-Frage
4. Zeitraum von-bis -> aus Appointment-Aggregation
5. ICF-Codes aus BEI -> client.icfBereiche, Teilhabeziel.icfBereich
6. Zielformulierung -> Teilhabeziel.titel + beschreibung + SMART
7. Zielerreichungsgrad -> GasBewertung-Skala mapped auf PerSEH 0-4
8. Wirkungseinschaetzung -> Zielmessung.kommentar bzw. WirksamkeitsberichtService-Fazit
9. Fachleistungsstunden -> sum(Appointment.fachleistungsstunden) im Zeitraum
10. Anwesenheits-/Abwesenheitstage -> aus Appointment-Typen
11. Besondere Vorkommnisse -> Freitext-Feld, UI-Frage
12. Naechste Schritte -> Teilhabeziel.beschreibung bei aktiven Zielen
13. Bezugsbetreuer:in -> Mitarbeiter-Stammdaten
14. Dateianhang -> WirksamkeitsberichtService-PDF als Download
15. Datum -> aktuelles Datum

### Prio 2: ANLEI-Verbund (Bayern/Hessen)

Zusaetzliche Felder gegenueber PerSEH:
- Leistungstyp-Nummer nach Landesrahmenvertrag
- Verguetete Tagessatz
- Platznummer / Wohngruppe
- Einrichtungs-IK

### Prio 3: KVJS Baden-Wuerttemberg
- BEI_BW-spezifische Struktur
- Monatsaufstellung der Stunden als eigenes Format

### Prio 4: LS-EH-Portal Niedersachsen
- B.E.Ni-Bedarfsermittlung
- Monatsnachweis / Halbjahresbericht

### Prio 5: PROSOZ NEO.connect (Berlin/Brandenburg)
- Reines XML-Export-Format
- Keine Tap-to-Copy, sondern NEO-compliant-XML erzeugen
- Braucht Einrichtungs-IK, Aktenzeichen pro Kostentraeger

## Umsetzung (Grobentwurf)

### Model
```dart
enum Portal { persehNrw, persehHessen, anleiBayern, kvjsBw, lsEhNi, neoConnect }

class PortalFeld {
  final String feldname;           // genau wie im Webformular
  final String beschriftung;       // zur besseren Orientierung
  final String Function(PortalExportContext) wertExtraktor;
  final bool pflicht;
  final String? hinweis;
}

class PortalPreset {
  final Portal portal;
  final String anzeigeName;
  final List<PortalFeld> felder;
  final String portalUrl;
}
```

### UI
- Neuer Screen: "Portal-Spickzettel"
- Klient waehlen, Zeitraum einstellen, Portal waehlen
- Tabelle: Feldname | Wert | [Copy-Button]
- "Alle kopieren" als JSON in Zwischenablage
- Button "Begleit-PDF erzeugen" -> WirksamkeitsberichtService

### Exportkanaele
1. Tap-to-Copy pro Feld (primaere Nutzung)
2. JSON-Download fuer Admin-Export
3. PDF-Begleitbericht (bereits vorhanden)
4. Fuer NEO: XML-Generator wie XRechnung, aber im NEO-Schema

## Validierungs-Anforderungen

Bevor ein Portal-Preset ausgeliefert wird:
- Stichprobe mit echtem Login-Zugang, um die Reihenfolge und exakten Feldnamen zu bestaetigen
- Traeger kontaktieren, ob Feldnamen schriftlich verfuegbar (z.B. in Schulungsunterlagen oder Handbuch)
- Testdaten ueber das Portal einsenden, Rueckmeldung abwarten

## Aufwand

- Daten-Extraktoren (allgemein): 4 Stunden
- PortalPreset-Modell + Registry: 2 Stunden
- UI-Screen (Tap-to-Copy): 4 Stunden
- PerSEH-Preset: 3 Stunden (wenn Feldliste vorhanden)
- Jedes weitere Portal: 2-4 Stunden
- Tests: 3-4 Stunden
- **Gesamt 1. Version (PerSEH only): ~16-18 Stunden**

## Risiken / Offene Fragen

- Portal-Layouts aendern sich zwischen Versionen -> UI muss leicht anpassbar bleiben
- Rechtliche Frage: Darf eine nicht zertifizierte App Daten fuer ein amtliches Portal erzeugen?
- Einrichtungs-IK-Pflege: manche Portale brauchen mehrere (pro Leistungsart); noch nicht in AppSettings
- Fallnummer-Mehrfachzuordnung: ein Klient kann bei mehreren Kostentraegern gefuehrt sein -> `client.kostentraegerFallnummern: Map<String, String>` empfehlenswert

## Wenn spaeter umgesetzt

Referenzen:
- Recherche-Dialog mit Agent vom 17.04.2026 (in Session-Transcript)
- PerSEH-Handbuch: https://www.lvr.de/de/nav_main/soziales_1/menschenmitbehinderung/perseh
- ANLEI-Projektseite: https://www.bezirk-oberbayern.de/soziales/details/fachverfahren-anlei-digitalisierung-in-der-eingliederungshilfe
- NEO.connect Schnittstellenbeschreibung: https://www.prosoz.de/wp-content/uploads/2023/11/Produktinformation_NEO.connect_eAbrechnung_OPEN-PROSOZ-1.pdf
