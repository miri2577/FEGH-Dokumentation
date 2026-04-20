# Wohnraum

## Ueberblick

Das Wohnraum-Modul verwaltet die Wohnsituation der Klienten: Mietvertraege, Warmmieten, Wohnungszuweisungen und Freiwerden. Es hilft Teamleitung und Verwaltung, Platzbelegungen zu planen und den Wohnkosten-Anteil in Nebenabrechnungen korrekt zu erfassen.

!!! note "Berechtigung"
    Wohnraeume anlegen und zuweisen duerfen Admin und Teamleitung. Lesender Zugriff ist teamweit.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Eine Einrichtung betreibt typisch zwischen 5 und 50 Wohnplaetze in
Einzelzimmern, Doppelzimmern, Appartments, Wohngemeinschaften. Jeder
Platz hat **vier parallele Bezugsgroessen**:

1. **Fachlich** — ist das Zimmer gerade belegt? Vom Wem? Seit wann?
2. **Wirtschaftlich** — Kaltmiete, Nebenkosten, Heizkosten; wer zahlt was?
3. **Baulich** — Renovierungsstand, Moebel-Inventar, Maengel
4. **Kostentraeger-bezogen** — manche Traeger zahlen einen Wohnkosten-
   Anteil, andere nicht

Ohne strukturierte Wohnraum-Verwaltung haengt das oft an einer
einzelnen Buerokraft, die die Uebersicht in einer Excel-Liste
pflegt. Fluktuation, Kranktage, Vertretungsregeln → Datenstand
weicht von der Realitaet ab. Die App macht den Wohnraum zum
**strukturierten Datensatz** pro Platz — mit Historie der
Zuweisungen und automatischer Einbindung in Kassenbuch/FLS.

### Konkretes Szenario: Umzug von Herrn T. in die WG Hauptstrasse

**20. Maerz — Herr T. wird angemeldet, Zimmer 3 der WG wird vergeben.**

1. Admin Anja oeffnet **Wohnraum → WG Hauptstrasse Zimmer 3** (Status
   "verfuegbar" seit 05. Januar).
2. Kontextmenue → **Klient zuweisen** → Herr T. gewaehlt.
3. System setzt Status auf **belegt**, schreibt Audit-Event
   `wohnraum.assigned` mit beiden IDs.
4. Auf der Klientenakte von Herrn T. erscheint automatisch die
   Adresse (`Musterstrasse 5, Zimmer 3`) als Standardanschrift.
5. Im Dienstplan: neue Schichten fuer Herrn T. bekommen diesen Ort
   als Default-Standort.

**01. April — Erste Monatsmiete buchen.**

Daniel (Sozialarbeiter) oeffnet Wohnraum-Detail → Kontextmenue
"Miete buchen":

1. Monatsauswahl: April 2026
2. System berechnet Warmmiete (Kalt + NK + Heizkosten = 450 EUR)
3. **Duplikatsschutz**: System prueft, ob fuer April/Zimmer 3
   bereits ein Beleg-Tag `RENT-wohn-3-202604` existiert. Nein → ok.
4. Beschreibung: "Miete 04/2026: WG Hauptstrasse Zimmer 3"
5. Ein neuer **Kassenbuch-Eintrag** entsteht beim Klienten Herr T.:
   -450 EUR, Kategorie Haushaltsgeld, freigegeben.

Zehn Minuten spaeter klickt Daniel versehentlich nochmal "Miete
buchen" für April → System **blockiert**: "Miete für April 2026 ist
bereits gebucht."

**15. Juli — Nachzahlung Nebenkosten aus Abrechnung 2025.**

Die jaehrliche Betriebskostenabrechnung ergibt fuer Herrn T. eine
Nachzahlung von 87,40 EUR. Daniel:

1. Wohnraum-Menue → **Nebenkostenabrechnung…**
2. Betrag: 87,40 EUR, Zweck: "Nebenkostennachzahlung 2025 (Heizung)"
3. System erzeugt einen Kassenbuch-Eintrag mit Beleg-Tag
   `NK-wohn-3-<timestamp>`, **nicht freigegeben** (Daniel kann noch
   editieren, bevor er die Zahlung veranlasst).

**30. Oktober — Herr T. zieht aus (Wechsel ins eigenstaendige Wohnen).**

1. Wohnraum-Menue → **Freigeben**
2. Bestaetigungsdialog: "Herr T. wird entfernt, Status 'verfuegbar'"
3. Status wechselt auf `free`, historische Zuweisung bleibt im
   Audit-Log (`wohnraum.released`). Das Zimmer erscheint wieder in
   der "freie Plaetze"-Liste.
4. Der Dienstplan behaelt bestehende Schichten fuer Herrn T. —
   neue Schichten werden ihm aber nicht mehr automatisch zugewiesen.

### Warum ein Wohnraum = ein Klient?

Das Modell erlaubt im MVP **genau einen Klienten** pro Wohnraum-
Eintrag. Fuer Doppelzimmer werden zwei separate Eintraege angelegt
("Zimmer 3a", "Zimmer 3b"). Gruende:

- Klare Miet-Zuordnung bei Auszug eines Mitbewohners
- Saubere Audit-Spur (wer hat wann gewohnt)
- Keine komplexen Kostenverteilungs-Regeln

Fuer WGs mit gemeinsamen Raeumen (Kueche, Bad) wird die Gemeinschafts-
Infrastruktur als eigener Wohnraum-Eintrag "WG Gemeinschaftsraeume"
angelegt und ueber Nebenkostenumlagen auf die Bewohner verteilt.

### Integration mit anderen Modulen

| Modul | Was vom Wohnraum kommt |
|-------|-------------------------|
| **Kassenbuch** | Warmmiete als monatliche Abbuchung, Nebenkosten-Abrechnung |
| **Dienstplan** | Adresse als Default-Standort fuer Schichten |
| **Klientenakte** | Aktuelle Anschrift fuer Formulare, Berichte, Rechnungen |
| **Berichte** | Wohnkosten-Anteil in Jahresbilanzen |

### Rechtlicher Hintergrund

- **§42a SGB XII** — Kosten der Unterkunft und Heizung; das Land
  zahlt einen Anteil, den die Einrichtung abrechnen muss.
- **§98 SGB IX** — Zustaendigkeit des Sozialhilfetraegers bei Umzug
  eines Klienten. Historie der Wohnraumzuweisungen ist Nachweis.
- **BGB §535ff.** (Miete) — Rechenschaftspflicht ueber vereinnahmte
  Mieten gegenueber Leistungstraeger und Betreuer.

## Wohnraum-Eintrag

| Feld | Beschreibung |
|------|-------------|
| Bezeichnung | Interner Name, z. B. "WG Hauptstrasse Zimmer 3" |
| Adresse | Strasse, PLZ, Ort |
| Wohnflaeche | Quadratmeter |
| Kaltmiete / Nebenkosten / Heizkosten | Monatlich in Euro |
| Warmmiete | Automatisch berechnet (Kalt + NK + Heiz) |
| Typ | Einzelzimmer, WG-Zimmer, Appartement, Eigene Wohnung |
| Status | Verfuegbar, Belegt, In Renovierung, Auslaufend |
| Zugewiesener Klient | Optional — einzelner Klient je Wohnraum |
| Zustandsnotizen | Moebel, Maengel, Schluessel |

## Zuweisung und Freigabe

- **Klient zuweisen** — im Wohnraum-Detaildialog. Status wechselt auf *Belegt*. Die Zuweisung wird in der Klienten-Akte gespiegelt.
- **Klient entlassen** — loest die Zuweisung, Status wechselt auf *Verfuegbar*. Historische Zuweisungen bleiben im Audit-Log erhalten.
- **Umzug** — direkte Neuzuweisung. Der alte Wohnraum wird automatisch freigegeben.

!!! tip "Pro Wohnraum ein Klient"
    Das MVP erlaubt genau einen Klient je Wohnraum. Fuer Doppelzimmer legen Sie zwei separate Wohnraum-Eintraege an (z. B. "Zimmer 3a", "Zimmer 3b"), damit Verguetung und Fluktuation sauber getrennt bleiben.

## Deaktivieren

Nicht mehr nutzbare Wohnraeume werden deaktiviert, nicht geloescht. So bleibt die Historie der Zuweisungen erhalten. Deaktivierte Eintraege erscheinen ausgegraut im Archiv.

## Kosten und Berichte

Die Warmmiete wird fuer jeden belegten Zeitraum in die Monatsberichte eingerechnet. In der Fachleistungsstunden-Abrechnung werden Wohnkosten getrennt ausgewiesen — Details: [Fachleistungsstunden](fachleistungsstunden.md).

## Integration mit dem Dienstplan

Hat ein Klient einen zugewiesenen Wohnraum, erscheint die Adresse automatisch als Default-Standort bei Schichten, die fuer diesen Klienten geplant werden. Aenderungen der Adresse propagieren, neu geplante Schichten uebernehmen den aktuellen Wert.
