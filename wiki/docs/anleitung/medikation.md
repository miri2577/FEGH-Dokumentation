# Medikation

## Ueberblick

Das Medikationsmodul verwaltet pro Klient den Medikationsplan und quittiert jede einzelne Gabe nachvollziehbar. Pflegende, Betreuende und Verwaltung arbeiten auf derselben Datenbasis: Der Plan wird in der Verwaltungsapp gepflegt, die Gaben werden auf dem mobilen Dokumentationsgeraet erfasst.

!!! note "Berechtigung"
    Plaene anlegen und bearbeiten duerfen Admin und Teamleitung. Gaben quittieren darf jede eingewiesene Fachkraft mit Medi-PIN.

## Funktionsweise im Detail

### Das Problem, das wir loesen

In einem stationaeren Setting wird Herr K. von wechselnden Schichten
betreut: Fruehdienst Anna, Spaetdienst Bjoern, Nachtdienst Clara.
Herr K. bekommt acht Medikamente, davon zwei Betaeubungsmittel und
eines nur bei Bedarf. Ohne digitales Medikationsmodul hinge die
Verantwortung an einem Papier-Ordner im Pflege-Dienstzimmer — mit
Risiken:

- **Vergessene Gaben** kommen in der Schichtuebergabe nicht immer an.
- **BtM-Bestand** muss nach §13 BtMG/BtMVV tagesaktuell dokumentiert
  werden; Pruefer verlangen vollstaendige Ketten.
- **Wer hat wann verabreicht** ist bei Vorfaellen nicht
  rekonstruierbar.
- **Doppelgaben** passieren, wenn Uebergaben ausfallen.

Das Medikationsmodul loest alle vier Punkte durch: Plan in der
Verwaltung, Slots auf dem mobilen Geraet, harte Audit-Spur pro Gabe.

### Konkretes Szenario: Eine Fruehschicht von Anna

**06:45 Uhr.** Anna kommt zur Fruehschicht. Sie oeffnet die
Dokumentations-App auf dem Dienst-Tablet und sieht in der Ansicht
"Medikationsgaben" den heutigen Tag. Fuer Herrn K. stehen vier Slots
auf der Karte:

- 08:00 Sertralin 50 mg (1 Tablette) — rot (offen)
- 08:00 Metformin 500 mg (1 Tablette) — rot (offen)
- 08:00 Tilidin retard 50 mg (1 Tablette) — rot + Warn-Symbol (BtM)
- nur bei Bedarf: Ibuprofen 400 mg — Blitz-Symbol

**08:05 Uhr.** Anna gibt Herrn K. zuerst Sertralin und Metformin.
Sie tippt auf den Sertralin-Slot → "Gegeben". Ein Dialog fragt nach
der quittierenden Fachkraft (vorausgefuellt aus Annas Profil).
Anna bestaetigt, der Slot wird gruen, das System schreibt einen
Audit-Eintrag `medication.given` mit Zeitstempel `08:05:23`.

**08:07 Uhr.** Tilidin ist BtM. Anna tippt "Gegeben" — die App
fragt zusaetzlich:

1. **Medi-PIN** (falls Anna fuer sich einen gesetzt hat): 4-stellige
   Eingabe, 3 Versuche.
2. **Zeuge** (Vier-Augen-Prinzip): Pflichtfeld — Anna waehlt Bjoern,
   der gerade von der Nachtschicht uebergibt.
3. **BtM-Bestand**: aktuelle Menge im Vorrat eingeben (z. B. "14
   Tabletten vorher, 13 nachher"), Belegnummer der Blisterpackung.

Erst wenn alle drei Felder korrekt sind, wird die Gabe als
`medication.given` + `medication.btm.entry` persistiert. Bjoern
bestaetigt mit seiner Mitarbeiter-ID; die Audit-Spur enthaelt beide
Namen.

**10:30 Uhr.** Herr K. klagt ueber Kopfschmerzen. Anna gibt eine
Tablette Ibuprofen aus der PRN-Verordnung. Auf der Karte tippt sie
auf das Blitz-Symbol → Dialog "Bedarfsgabe erfassen" mit
**Pflichtgrund** (Anna schreibt "Klient klagt ueber Kopfschmerzen,
vitale Zeichen unauffaellig"). Audit-Event:
`medication.given.prn` mit Grund + Zeitstempel.

**19:00 Uhr.** Am Abend haben sich drei Slots nicht quittieren
lassen — Herr K. war bei einem Termin beim Hausarzt. Die
nicht-quittierten Slots wurden automatisch als "versaeumt"
markiert. Clara (Nachtschicht) traegt den Grund nach.

### Sicherheitsschichten im Ueberblick

| Schicht | Was sie leistet | Wann sie greift |
|---------|-----------------|-----------------|
| **Medi-PIN** (PBKDF2, 100k Iterationen) | Verhindert, dass ein Kollege mit geliehenem Tablet Gaben auf fremde Kappe quittiert | Opt-In pro Mitarbeiter, vor jeder Quittung |
| **4-Augen-Prinzip** (`requiresWitness`) | Zwei Mitarbeiter-IDs pro Gabe, Zeuge != Gebender wird erzwungen | BtM immer; andere Medikamente per Plan-Flag |
| **BtM-Bestandsfuehrung** | Laufender Restbestand, Low-Stock-Warnung, Audit-Kette | Automatisch bei jeder BtM-Gabe |
| **BtM-Vernichtung** (§15 BtMVV) | Pflicht-Grund, Pflicht-Zeuge, optional Unterschrift | Abgelaufen / kontaminiert / Klient ausgezogen |
| **Audit-Log** | Unveraenderliche JSON-Lines-Historie mit Zeitstempel, Mitarbeiter, Kontext | Bei jeder Aktion; SIEM-exportierbar |

### Was bei der Persistenz passiert

Jede Gabe-Quittung erzeugt drei parallele Schreibvorgaenge:

1. **`MedicationAdministration`-Record** in SharedPreferences
   (`medication_administrations_v1`) — geplante Zeit, tatsaechliche
   Zeit, Status, Gebender, Zeuge, optional Grund.
2. **Audit-Event** in `audit.log` — unveraenderlich, rotiert nach
   1095 Tagen (DSGVO Art. 5 Abs. 2).
3. **Bei BtM**: zusaetzlich ein `BtmEntry` in
   `btm_entries_v1` mit Menge, Restbestand, Zeuge, Belegnummer.

Beim naechsten Cloud-Sync landen alle drei im Cloud-Speicher (HiDrive / Nextcloud / ownCloud / WebDAV) und sind fuer
andere Geraete sichtbar.

### Rechtlicher Hintergrund kurz zusammengefasst

- **§13 BtMG** + **§§12/13 BtMVV** verlangen fuer jede Anwendung von
  Betaeubungsmitteln: Datum, Uhrzeit, Name des Bewohners, Menge,
  Restbestand, Unterschrift der verabreichenden Person und eines
  Zeugen. Unsere BtM-Dokumentation setzt das 1:1 um.
- **§15 BtMVV** regelt die Vernichtung nicht mehr benoetigter
  Betaeubungsmittel — Zeuge ist Pflicht, Protokoll bleibt 3 Jahre.
- **DSGVO Art. 9** (besondere Kategorien personenbezogener Daten):
  Gesundheitsdaten. Deshalb werden Diagnosen **nicht** in der
  Medikations-Notiz gefuehrt — sie stehen in der geschuetzten
  Klientenakte; die Medikation enthaelt nur das Praeparat.

## Medikationsplan

| Feld | Beschreibung |
|------|-------------|
| Name | Handelsname und Wirkstaerke, z. B. "Sertralin 50 mg" |
| Dosierung | Gabe-Form, z. B. "1 Tablette" |
| Einnahmezeiten | Morgens (08:00), Mittags (12:00), Abends (18:00), Nacht (22:00) |
| Gueltig von / bis | Zeitraum der Verordnung |
| Verordnender Arzt | Optional, aber dringend empfohlen |
| BtM | Betaeubungsmittel — zusaetzliche Dokumentation erforderlich |
| Bedarfsmedikation (PRN) | Keine festen Einnahmezeiten, wird nur bei Bedarf gegeben |
| Notiz | Interne Hinweise (z. B. "mit Nahrung") |

## Feste Einnahmezeiten

Jede aktive Verordnung erzeugt an jedem gueltigen Tag genau die im Plan angehakten Slots. Geraet in der Fruehschicht die Morgen-Gabe in den Ueberzug, erscheint der Slot bis zur Quittung rot. Pro Slot gibt es drei Aktionen:

- **Gegeben** — mit aktuellem Zeitstempel und Quittierenden-ID
- **Verweigert** — Klient hat die Annahme abgelehnt (Grund pflicht)
- **Versaeumt** — Gabe konnte nicht erfolgen (Grund pflicht)

!!! warning "Kein Nachtragen alter Slots"
    Gaben koennen bis zum Ende des Tages quittiert werden. Aeltere Slots werden automatisch als "versaeumt" markiert und muessen mit Grund nachgepflegt werden.

## Bedarfsmedikation (PRN)

PRN steht fuer *pro re nata* — "nach Bedarf". Eine PRN-Verordnung hat keine festen Slots im Tagesraster, sondern wird genau dann dokumentiert, wenn die Gabe erfolgt.

Workflow:

1. Plan-Eintrag im Admin-Dialog als **Bedarfsmedikation** markieren
2. Auf der Planansicht erscheint das Symbol :material-flash: fuer die Gabe-Erfassung
3. Beim Klick: Dialog mit Pflichtfeld **Grund** (Symptombeschreibung oder aerztliche Anweisung), optional Notiz
4. Gabe wird als eigenstaendiger Eintrag im Audit-Log unter `medication.given.prn` gefuehrt

Typische Beispiele: Bedarfs-Antipyretika, Reserve-Inhalativa, Notfall-Anxiolytika.

## BtM-Verordnungen

BtM-Medikamente werden mit dem Warn-Symbol gekennzeichnet. Zusaetzlich zur Standard-Quittung wird bei der Gabe der aktuelle Bestand im Sucht-Kontrollbuch aktualisiert — Details: [BtM-Verordnung Wiki](https://www.bfarm.de).

## Audit und Nachweis

Jede Aktion (Plan anlegen/aendern, Gabe quittieren, Versaeumnis dokumentieren) schreibt einen Audit-Eintrag mit Zeitstempel, Mitarbeiter-ID und Kontext. Die Log-Datei liegt verschluesselt in der Cloud unter `administration/audit/` und ist von Admin und Datenschutzbeauftragten einsehbar.

## Synchronisation

Aenderungen am Plan werden beim naechsten Sync-Zyklus auf allen Geraeten sichtbar. Quittungen werden sofort lokal gespeichert und danach hochgeladen — auch offline. Konflikte (z. B. zwei Geraete quittieren den gleichen Slot) loest der letzte Sync-Schreibvorgang; Doppelquittungen werden im Audit sichtbar.
