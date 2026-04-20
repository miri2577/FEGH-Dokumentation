# Bundeslaender und Bedarfserhebungsinstrumente

FEGH-Dokumentation unterstuetzt alle 16 Bundeslaender mit ihrem jeweiligen Bedarfserhebungsinstrument. Das Bundesland wird einmalig im Setup-Wizard oder jederzeit in den Einstellungen festgelegt.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Das BTHG hat die Eingliederungshilfe zwar bundeseinheitlich neu
aufgestellt — die **konkrete Umsetzung** ist aber Laendersache.
Jedes Bundesland hat nach §131 SGB IX einen eigenen Landesrahmen-
vertrag ausgehandelt, und fast jedes Bundesland hat dabei auf ein
eigenes Bedarfserhebungsinstrument gesetzt. Fuer Einrichtungen, die
ueber Landesgrenzen hinweg arbeiten, heisst das:

- In Berlin nutzt man **TIB** + das handschriftliche **Formular 101**.
- 100 km suedlich in Brandenburg: **ITP Brandenburg**.
- In der selben Klienten-Akte muss beides moeglich sein, wenn Herr K.
  von Berlin nach Potsdam zieht.
- Der Kostentraeger-Bericht an das Berliner Bezirksamt erwartet
  TIB-Formatierung; der Bericht an den LWV Hessen erwartet ITP.

Ohne durchdachte Mehrmandanten-Logik waeren das **16 parallele
Apps**. FEGH loest das mit einem einzigen Datenmodell + Bundesland-
Profil-System: Das Bundesland steuert welche Dropdowns, welches
Formular, welches Portal-Linkziel angezeigt werden. Der Rest bleibt
identisch.

### Konkretes Szenario: Ein Klient wechselt das Bundesland

Frau S. zog im August 2026 von Berlin nach Duesseldorf. Ihre
Einrichtung (Berliner Traeger) betreut sie fuer eine Uebergangs-
phase weiter. In Berlin war sie mit **TIB + Formular 101**
dokumentiert, der Kostentraeger war das **Sozialamt
Friedrichshain-Kreuzberg**.

**August 2026 — Uebergabe in der Einrichtung.**

Admin Anja oeffnet Frau S.' Klient-Akte:

1. **Bundesland-Override** von `Berlin` auf **`Nordrhein-Westfalen`**
2. Die App liest das neue Bundesland-Profil
   (`BundeslandProfile.forLand(nrw)`):
   - Bedarfsinstrument: **BEI_NRW** (9 ICF-Lebensbereiche)
   - Portal: **PerSEH (LVR/LWL)**
   - Keine Formular-101-Anforderung
3. Bestehende **TIB-Ziele** bleiben als `icfBereiche` erhalten — der
   ICF-Code `d170` heisst in BEI_NRW genauso wie in TIB Berlin.
   Die App zeigt sie aber **unter der BEI_NRW-Klassifikation** an.
4. Neue Ziele nutzen ab sofort BEI_NRW-Dropdowns.
5. Kostentraeger-Wechsel: Anja ergaenzt die Fallnummer beim neuen
   Traeger (LVR Landschaftsverband Rheinland).

Beim **Wirksamkeitsbericht Ende 2026** zeigt das PDF beide
Perioden klar getrennt:

- Jan-Jul: "Bedarfserhebung: TIB (Berlin)"
- Aug-Dez: "Bedarfserhebung: BEI_NRW"

GAS- und POS-Messungen — bundesweit einheitlich — laufen nahtlos
durch.

### Die Instrument-Familien im Ueberblick

Warum 4 Familien und nicht 16 Einzelinstrumente? Weil viele
Bundeslaender sich inhaltlich gegenseitig abgeschrieben haben — mit
marginalen Anpassungen:

- **ITP-Familie** (Hessen, Brandenburg, MV, Sachsen,
  Sachsen-Anhalt, Thueringen): Originalentwurf aus Hessen, direkt
  uebernommen. 9 ICF-Lebensbereiche + Freitextziele.
- **HMBV-Familie** (Hamburg Original, Bremen adaptiert): **5**
  Kernbereiche mit 5-stufiger Unterstuetzungsintensitaet (0-4).
  Deutlich anders strukturiert als ITP.
- **BEI-Familie** (NRW, BW, SH): ICF-basiert mit 9 Lebensbereichen,
  aber **eigene Scoring-Skala** pro Land.
- **Eigenstaendige**: Berlin (TIB), Niedersachsen (B.E.Ni), Bayern
  (Gesamtplan → ANLEI-Migration 2026-2028), Rheinland-Pfalz +
  Saarland (generisches ICF).

Die App hat fuer jedes Instrument ein **`BundeslandProfil`** mit:

- Bedarfsinstrument-Enum (fuer Logik)
- Menschlesbare Bezeichnung (fuer UI)
- Formular-Flag (`hatFormular101: bool`)
- Fahrtzeit-Abrechenbarkeit (`fahrtzeitAbrechenbar: bool` — relevant
  fuer FLS-Berechnung)
- Portal-URL fuer Einreichung
- Besonderheiten als Freitext (fuer den Info-Dialog)

### Was konkret passiert, wenn man das Bundesland aendert

Die Aenderung des Organisations-Bundeslands (`Einstellungen →
Bundesland`) hat **sofortige** Auswirkungen auf die App:

| Ort | Was sich aendert |
|-----|------------------|
| Neue Ziele anlegen | Dropdown zeigt passendes Instrument |
| Berichte → Amtliche Formulare | Portallinks aktualisiert |
| FLS-Berechnung | `fahrtzeitAbrechenbar`-Flag greift |
| Setup-Wizard-Info-Karte | Neue Besonderheiten angezeigt |

**Was sich NICHT aendert**: bereits erfasste Ziele, bereits
erstellte Rechnungen, bereits gespeicherte Wirkungsmessungen. Die
sind historisch mit dem Bundesland verknuepft, das zum Zeitpunkt
ihrer Entstehung galt. Das ist Absicht: Audits rekonstruieren die
Vergangenheit, nicht den aktuellen Stand.

### Rechtlicher Hintergrund

- **§131 SGB IX** — Landesrahmenvertraege. Jeder LRV kann eigene
  Instrumente vorschreiben; 13 von 16 Laendern haben das genutzt.
- **§128 SGB IX** — Wirksamkeitsnachweis (bundesweit GAS/POS).
- **§118 SGB IX** — Bedarfsermittlung als Teil des Teilhabeplans.
- **Art. 20 DSGVO (Datenuebertragbarkeit)**: Bei Klient-Umzug muss
  die Akte im strukturierten, elektronisch verarbeitbaren Format
  uebertragbar sein. JSON-Export deckt das ab.

## Warum ist das wichtig?

Nach §128 SGB IX und §131 SGB IX (BTHG) nutzt jedes Bundesland ein eigenes Bedarfserhebungsinstrument, das Pflichtbestandteil des Landesrahmenvertrages ist. Die App waehlt automatisch:

- Die passenden **ICF-Lebensbereiche** (d1-d9) beim Anlegen von Teilhabezielen
- Das Berliner **Formular 101** (nur fuer Berlin)
- Die richtigen **Hinweise und Portallinks** fuer die Einreichung

## Uebersicht

| Bundesland | Instrument | Struktur | Portal |
|------------|-----------|----------|--------|
| Baden-Wuerttemberg | BEI_BW | 9 ICF-Lebensbereiche | KVJS/kommunal |
| Bayern | Bayerischer Gesamtplan | generisches ICF | ANLEI (ab 03/2026) |
| Berlin | TIB (Teilhabe-Instrument) | Freitext + Formular 101 | OPEN/PROSOZ (via beA) |
| Brandenburg | ITP Brandenburg | 9 ICF-Lebensbereiche | Landesportal |
| Bremen | HMBV (Bremen-Adaption) | 5 Bereiche + Bedarfsintensitaet | kommunal |
| Hamburg | HMBV (Hamburger Manual) | 5 Bereiche + Bedarfsintensitaet | Behoerden-Portal |
| Hessen | ITP Hessen | 9 ICF-Lebensbereiche | PerSEH (LWV) |
| Mecklenburg-Vorpommern | ITP MV | 9 ICF-Lebensbereiche | Landesportal |
| Niedersachsen | B.E.Ni | 9 ICF-Lebensbereiche | LS-EH-Portal (Dataport) |
| Nordrhein-Westfalen | BEI_NRW | 9 ICF-Lebensbereiche | PerSEH (LVR/LWL) |
| Rheinland-Pfalz | Teilhabeinstrument RLP | generisches ICF | LSJV eFalldaten |
| Saarland | SBI | generisches ICF | LRV Saarland |
| Sachsen | ITP Sachsen | 9 ICF-Lebensbereiche | KSV Sachsen |
| Sachsen-Anhalt | ITP Sachsen-Anhalt | 9 ICF-Lebensbereiche | Landesportal |
| Schleswig-Holstein | BEI-SH / PerSEH-SH | generisches ICF | Dataport-Sozialportal |
| Thueringen | ITP Thueringen | 9 ICF-Lebensbereiche | Landesportal |

## Instrument-Familien

### ITP-Familie (6 Laender)
Der **Integrierte Teilhabeplan** wurde in Hessen entwickelt und wird in Hessen, Brandenburg, MV, Sachsen, Sachsen-Anhalt und Thueringen genutzt. 9 ICF-Lebensbereiche plus zusaetzliche Freitextziel-Felder.

### HMBV-Familie (2 Laender)
Das **Hamburger Manual zur Bedarfsermittlung** ist die Hamburger Eigenentwicklung, Bremen hat es adaptiert. 5 Kernbereiche mit einer 5-stufigen Unterstuetzungsintensitaets-Skala (0-4).

### BEI-Familie (3 Laender)
NRW (BEI_NRW), Baden-Wuerttemberg (BEI_BW) und Schleswig-Holstein (BEI-SH) nutzen ICF-basierte Instrumente mit 9 Lebensbereichen.

### Eigenstaendige Instrumente
- **Berlin:** TIB mit Berliner Formular 101
- **Niedersachsen:** B.E.Ni (eigenes Design, ICF-orientiert)
- **Bayern:** Gesamtplan (wird auf ANLEI migriert 2026-2028)
- **Rheinland-Pfalz, Saarland:** generisch ICF

## Bundesland einstellen

### Beim Einrichten
1. Setup-Wizard starten
2. Auf der Profil-Seite: **Bundesland der Organisation** auswaehlen
3. Die App zeigt die Besonderheiten des Bundeslandes als Info-Karte

### Nachtraeglich aendern
1. **Einstellungen** oeffnen
2. Unter **Zugriffsstatus** auf **Bundesland** -> **Aendern**
3. Neues Bundesland auswaehlen und speichern

Die Aenderung wirkt sich sofort aus:
- Neue Teilhabeziele zeigen das passende Instrument
- Formular-Vorlagen im Berichte-Bereich werden angepasst
- Bereits angelegte Ziele bleiben erhalten (mit ihrem urspruenglichen ICF-Code)

## Bundesland-Override pro Klient

In Grenzfaellen (Klient lebt in anderem Bundesland als der Traeger) kann ein einzelner Klient ein **abweichendes Bundesland** zugeordnet bekommen. Dann gelten fuer diesen Klienten automatisch die Dropdown-Listen und Formulare des Klient-Bundeslandes.

Diese Funktion ist derzeit ueber das Klient-Datenmodell aktivierbar (Feld `bundeslandOverride`). Eine UI-Integration im Klient-Formular folgt bei Bedarf.

## Amtliche Formulare

Unter **Berichte > Amtliche Formulare (alle Bundeslaender)** findest du pro Bundesland:

- Direkte Links zu den Landesportalen (PerSEH, ANLEI, LS-EH, ...)
- Herunterladbare Blanko-PDFs wo oeffentlich verfuegbar
- Hinweise zur Einreichung (beA, DE-Mail, Upload-Portal)

## Rechtlicher Hintergrund

Die laenderspezifischen Instrumente sind im jeweiligen **Landesrahmenvertrag nach §131 SGB IX** verbindlich festgelegt. Die App zeigt bei jedem Bundesland an, welche LRV-Fassung aktuell gilt.

!!! info "Wirksamkeit bundesweit"
    Die Wirksamkeitsmessung nach §128 SGB IX (GAS + POS) ist **bundesweit gleich**. Die landesspezifischen Unterschiede betreffen nur die **Bedarfserhebung** und die **Formularpflichten**.

## Nicht implementierte Portal-Integration

FEGH-Dokumentation liefert aktuell **keine direkte API-Anbindung** an Landesportale wie PerSEH oder ANLEI. Grund: keine oeffentlichen Schnittstellen, juristische Auftragsverarbeitungs-Anforderungen. Die App exportiert strukturierte Daten (JSON, XRechnung, PDF) und unterstuetzt beim manuellen Eintragen in die Portale.

Diese Einschraenkung ist einheitlich fuer alle 16 Bundeslaender - weder Berlin noch NRW noch andere haben offene APIs fuer Drittsoftware.
