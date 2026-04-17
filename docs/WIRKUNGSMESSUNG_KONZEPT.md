# Wirkungsmessung in der Eingliederungshilfe -- Recherche und Umsetzungskonzept

Stand: April 2026

## 1. Rechtliche Grundlagen

### BTHG (Bundesteilhabegesetz) seit 2020

Das BTHG hat den Begriff "Wirksamkeit" in das Vertragsrecht der Eingliederungshilfe eingefuehrt. Leistungserbringer und Kostentraeger muessen seither nachweisen, ob:

- Der Hilfebedarf tatsaechlich gedeckt wird
- Die Ziele/Wuensche des Menschen mit Behinderung erreicht werden (individuelle Wirkung)
- Das Angebot der Einrichtung generell geeignet ist (Wirksamkeit des Angebots)

### §128 SGB IX - Wirtschaftlichkeits- und Qualitaetspruefung

Den Kostentraegern wird ein gesetzliches Pruefrecht eingeraeumt bezueglich:

- Inhalte der Leistungen
- Umfang
- Wirtschaftlichkeit
- Qualitaet
- **Wirksamkeit der Leistungen**

Nach §121 Satz 7 SGB IX koennen die Bundeslaender zusaetzlich Stichproben-Pruefungen durchfuehren. **Fast alle Bundeslaender haben davon Gebrauch gemacht.**

### §131 SGB IX - Landesrahmenvertraege

Verpflichtet die Vertragsparteien, Regelungen zur Wirksamkeit in Landesrahmenvertraegen zu vereinbaren.

## 2. Status Berlin

### Aktuelle Situation

- **Berliner Rahmenvertrag 2019** gilt bis 31.12.2026 (wurde gekuendigt)
- **NEUER RAHMENVERTRAG tritt am 01.01.2027 in Kraft**
- Uebergangsregelung vom 14.05.2025 bereits beschlossen
- TIB (Teilhabeinstrument Berlin) ist seit 2020 verpflichtendes Bedarfsermittlungsinstrument

### Was im neuen Rahmenvertrag kommen wird

Der aktuelle Trend in den anderen Bundeslaendern zeigt: Berlin wird voraussichtlich **konkrete Wirksamkeitsnachweise** verpflichtend einfuehren. Schon heute gefordert in:

- **Brandenburg, Hessen, Niedersachsen, Sachsen, Schleswig-Holstein, NRW, Thueringen**

Inhalte werden sein:
- Regelmaessige Zielerreichungsmessung
- Strukturierte Dokumentation der Wirkungen
- Pruefrechte der Kostentraeger nach §128

## 3. Gaengige Messinstrumente

### TIB (Teilhabeinstrument Berlin) -- BEREITS IN DER APP

- ICF-orientiertes Bedarfsermittlungsinstrument
- Erfasst Ziele, Beeintraechtigungen, Aktivitaeten, Teilhabe
- Verpflichtend in Berlin seit 2020
- **Aktueller App-Support: Ja** (Felder `tibZiele` und `individuelleTibZiele`)

### POS (Personal Outcomes Scale) -- FEHLT

- Entwickelt Universitaet Gent + Arduin Stiftung
- 8 Domaenen der Lebensqualitaet
- 48 Indikatoren mit je 3-Punkte-Skala
- Maximalwert: 144
- Fuer regelmaessige Laengsschnittmessung
- Genutzt von grossen Traegern in Deutschland (Caritas, Sozialwerk St. Georg)

### GAS (Goal Attainment Scaling) -- FEHLT

- Seit ca. 1970 wissenschaftlich etabliert
- 5-Punkte-Skala pro Ziel: -2 (viel schlechter) bis +2 (viel besser als erwartet)
- 0 = erwartetes Ergebnis
- Partizipativ: Ziele werden gemeinsam mit Klient vereinbart
- Gut mit ICF kombinierbar

### ICF-Kodierung -- TEILWEISE IN DER APP

- Internationale Klassifikation (WHO)
- Kodiert Funktionsfaehigkeit, Behinderung, Gesundheit
- Domaenen: Koerperfunktionen, Koerperstrukturen, Aktivitaeten/Teilhabe, Umweltfaktoren
- **Aktueller App-Support: Ja** (Feld `icfBereiche`)

## 4. Gap-Analyse: Was fehlt der App?

| Feature | Status | Prioritaet |
|---------|:------:|:----------:|
| TIB-Ziele erfassen | Vorhanden | -- |
| ICF-Bereiche | Vorhanden | -- |
| Fachleistungsstunden tracken | Vorhanden | -- |
| **GAS-Zielerreichung pro Ziel** | **Fehlt** | **Hoch** |
| **Regelmaessige Messzeitpunkte** (Baseline, Zwischen, Ende) | **Fehlt** | **Hoch** |
| **POS-Fragebogen (8 Domaenen)** | **Fehlt** | **Mittel** |
| **Visualisierung der Entwicklung** (Verlaufskurven) | **Fehlt** | **Hoch** |
| **Wirksamkeitsnachweis-Export** fuer Kostentraeger | **Fehlt** | **Hoch** |
| Zielformulierung SMART | Fehlt | Mittel |
| Zeitpunkt der Zielerreichung (bis wann) | Fehlt | Mittel |
| Wirkungsberichte (Einzel + Aggregiert) | Fehlt | Mittel |

## 5. Umsetzungsvorschlag

### Phase 1: Datenmodell erweitern

**Neue Modelle:**

```dart
enum Zielerreichung {
  deutlichSchlechter,  // GAS: -2
  schlechter,          // GAS: -1
  wieErwartet,         // GAS:  0
  besser,              // GAS: +1
  deutlichBesser,      // GAS: +2
}

class Teilhabeziel {
  final String id;
  final String clientId;
  final String titel;
  final String beschreibung;
  final String? icfBereich;     // Verknuepfung zu ICF
  final DateTime zielTermin;     // Bis wann
  final DateTime erstelltAm;
  final String? smartKriterien;  // SMART-formuliert
}

class Zielmessung {
  final String id;
  final String zielId;
  final DateTime messdatum;
  final MesszeitpunktTyp typ; // Baseline / Zwischenmessung / Endmessung
  final Zielerreichung bewertung; // GAS-Skala
  final String? kommentar;
  final String bewertetVon; // Mitarbeiter-ID
}

class PosMessung {
  final String id;
  final String clientId;
  final DateTime datum;
  // 8 Domaenen mit je 0-18 Punkten
  final int selbstbestimmung;
  final int sozialeTeilhabe;
  final int interpersonelleBeziehungen;
  final int rechte;
  final int emotionalesWohlbefinden;
  final int physischesWohlbefinden;
  final int materiellesWohlbefinden;
  final int persoenlicheEntwicklung;
  // Summe max 144
}
```

### Phase 2: UI-Komponenten

1. **Ziel-Editor** pro Klient (SMART-kriterien, ICF-Verknuepfung, Zieltermin)
2. **GAS-Bewertung** -- einfaches Bewertungs-Widget mit 5-Punkte-Skala (Farben: Rot/Orange/Grau/Hellgruen/Dunkelgruen)
3. **Verlaufsdiagramm** -- Liniendiagramm ueber Messzeitpunkte
4. **POS-Fragebogen** -- 48 Fragen durchklickbar, Auswertung per Domaene
5. **Wirksamkeitsbericht** -- PDF-Export fuer Kostentraeger

### Phase 3: Auswertung & Export

- Pro Klient: Zielerreichung ueber Zeit, GAS-Durchschnitt, POS-Entwicklung
- Aggregiert pro Team: Durchschnittliche Zielerreichung, Erfolgsquote
- Export als PDF fuer Wirksamkeitsnachweis nach §128 SGB IX
- CSV-Export fuer statistische Auswertungen

### Phase 4: Integration in bestehende Ablaeufe

- **Bei Klient-Erstellung**: TIB-Ziele automatisch in Zielsystem uebernehmen
- **Bei Termin-Dokumentation**: Optionale GAS-Bewertung "Wie lief es heute in Richtung Ziel XY?"
- **Alle 3 Monate**: Erinnerung zur Zwischenmessung
- **Zum Betreuungsende**: Endmessung pflicht, generiert Wirksamkeitsbericht

## 6. Empfohlene Reihenfolge

| Schritt | Aufwand | Nutzen | Prioritaet |
|---------|---------|--------|:----------:|
| 1. Teilhabeziel + Zielmessung Modelle | 1-2 Tage | Grundlage | Kritisch |
| 2. Ziel-Editor + GAS-Bewertung UI | 2-3 Tage | Kernfunktion | Kritisch |
| 3. Verlaufsdiagramm | 1 Tag | Sichtbarkeit | Hoch |
| 4. Wirksamkeitsbericht PDF | 1-2 Tage | Compliance | Hoch |
| 5. POS-Fragebogen komplett | 2-3 Tage | Lebensqualitaet | Mittel |
| 6. Aggregierte Team-Auswertung | 1 Tag | Management | Mittel |

**Gesamtaufwand: ca. 8-12 Entwicklungstage**

## 7. Deadline

**Bis 31.12.2026 muss die App produktionsreif sein** -- denn ab 01.01.2027 gilt der neue Berliner Rahmenvertrag und Nutzer werden voraussichtlich Wirksamkeitsnachweise vorlegen muessen.

## 8. Quellen

- [Umsetzungsbegleitung BTHG -- Wirkung und Wirksamkeit](https://umsetzungsbegleitung-bthg.de/bthg-kompass/bk-vertragsrecht/fd17-m5/)
- [Deutscher Verein -- Eckpunkte zu Wirkung und Wirksamkeit](https://www.deutscher-verein.de/empfehlungen-stellungnahmen/detail/eckpunkte-des-deutschen-vereins-fuer-oeffentliche-und-private-fuersorge-ev-zu-wirkung-und-wirksamkeit-in-der-eingliederungshilfe/)
- [Der Paritaetische -- Wirksamkeit der Leistungen](https://www.der-paritaetische.de/themen/gesundheit-teilhabe-und-pflege/teilhabe/bundesteilhabegesetz/wirksamkeit-der-leistungen/)
- [contec -- Wirksamkeitsnachweis in der Eingliederungshilfe](https://www.contec.de/blog/beitrag/wirksamkeitsnachweis-eingliederungshilfe/)
- [TIB Teilhabeinstrument Berlin](https://www.berlin.de/sen/soziales/besondere-lebenssituationen/menschen-mit-behinderung/eingliederungshilfe-sgb-ix/bedarfsermittlung-tib/)
- [Berliner Rahmenvertrag 2019](https://www.berlin.de/sen/soziales/service/vertraege/sgb-ix/kommission-131/artikel.947636.php)
- [POS Personal Outcomes Scale](https://www.pos-misst-lebensqualitaet.de/)
- [Caritas -- Lebensqualitaet messen](https://www.caritas.de/neue-caritas/heftarchiv/jahrgang-2024/artikel/was-ist-qualitaet-in-der-eingliederungshilfe)
- [BAGueS -- Orientierungshilfe zu §128 Pruefungen](https://umsetzungsbegleitung-bthg.de/w/files/links-und-materialien/soziale-teilhabe/orientierungshilfe-pruefungen-c-128-sgb-ix-stand-januar-2021-final.pdf)
- [Goal Attainment Scaling Leitfaden NRW](https://www.lzg.nrw.de/_php/login/dl.php?u=/_media/pdf/service/Veranst/110705_Workshop_Zielerreichungsskalen/leitfaden_gas_endversion.pdf)
