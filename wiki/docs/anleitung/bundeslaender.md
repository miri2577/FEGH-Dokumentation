# Bundeslaender und Bedarfserhebungsinstrumente

FEGH-Dokumentation unterstuetzt alle 16 Bundeslaender mit ihrem jeweiligen Bedarfserhebungsinstrument. Das Bundesland wird einmalig im Setup-Wizard oder jederzeit in den Einstellungen festgelegt.

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
