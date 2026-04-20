# Einstellungen

## Funktionsweise im Detail

### Das Problem, das wir loesen

Die App bedient sehr unterschiedliche Einrichtungen: kleine
Wohngruppen mit 3 Mitarbeitern genauso wie mittelgrosse Traeger mit
50 Mitarbeitern und mehreren Standorten. Jede Einrichtung hat
eigene Stundensaetze, eigene Kalkulationsfaktoren, eigenes
Bundesland, eigene Urlaubsregelungen.

Ohne zentrale Einstellungen muesste jeder dieser Werte an jeder
Stelle im Code stehen — Folge: Updates gelten nicht, Defaults sind
falsch, Einstellungen widersprechen sich. Der Einstellungs-Screen
buendelt alle **organisationsweiten** und **persoenlichen** Parameter
an einer Stelle und sorgt dafuer, dass andere Module sie konsistent
abfragen.

### Zwei Ebenen: persoenlich vs. organisationsweit

| Ebene | Wer setzt | Beispiele |
|-------|-----------|-----------|
| **Persoenlich** | Mitarbeiter selbst | Name, Dunkelmodus, Wochenarbeitszeit, Zwei-Faktor |
| **Organisation** | Admin | Bundesland, FLS-Stundensatz, Kalkulationsfaktor, Leistungstyp-Default |
| **Geraete-lokal** | automatisch | Cloud-Zugang, Session-Tokens, Recovery-Material |

Persoenliche Einstellungen gelten nur fuer den aktuellen Mitarbeiter
auf dem aktuellen Geraet. Organisations-Einstellungen werden ueber
die Cloud verteilt und gelten fuer alle — die App laedt sie bei
jedem Sync-Zyklus neu. Geraete-lokale Einstellungen kommen nie in
die Cloud (sie enthalten Keys/Tokens).

### Konkretes Szenario: Einrichtung wechselt Kostentraeger-Vertrag

Die Traeger-Einrichtung "Assistenz gGmbH" hat seit 2026 einen
neuen Rahmenvertrag mit dem Land Berlin. Wirksam ab 01. April 2026:

- Stundensatz steigt von 52,00 auf 54,50 EUR
- Kalkulationsfaktor bleibt 1,33

**01. April, Admin Anja passt an.**

1. `Einstellungen → FLS-Kalkulation`
2. Stundensatz: 54,50 setzen
3. Speichern
4. Audit-Event `settings.updated` mit alt=52,00, neu=54,50 wird
   geschrieben.

**Was automatisch passiert:**

- Alle **neu erstellten** Rechnungen ab heute nutzen 54,50 EUR.
- **Bestehende Rechnungen** bleiben unberuehrt (sie haben den
  Stundensatz bereits festgeschrieben — Aenderung waere GoBD-
  Verstoss).
- Klienten mit einem `stundensatzOverride` werden NICHT beruehrt —
  dort gelten die individuell ausgehandelten Saetze weiter.

Zwei Minuten spaeter loggt sich Mitarbeiterin Mia auf ihrem Tablet
ein: Beim naechsten Cloud-Sync laedt ihr Geraet die neue
Stundensatz-Einstellung. Sie bemerkt nichts — die naechste Rechnung,
die sie erzeugt, nutzt schon 54,50.

### Zwei-Faktor-Authentifizierung (TOTP)

Optional. Schuetzt gegen:

- **Tablet gestohlen**: der Dieb kennt das Entsperr-Passwort nicht;
  App verlangt TOTP beim Start.
- **Recovery-Code kompromittiert**: zweiter Faktor blockiert
  Recovery-Misbrauch.

Einrichtung:

1. `Einstellungen → Zugriffsstatus → 2FA einrichten`
2. QR-Code mit Authenticator-App scannen (Google Authenticator,
   Authy, 1Password, Bitwarden, KeePassXC-Plugin alle ok).
3. Testen: 6-stelliger Code eingeben.
4. **Backup-Codes** ausdrucken und sicher verwahren — falls das
   Handy weg ist.

Der TOTP-Standard (RFC 6238) nutzt 30-sekuendige Zeitfenster, d. h.
das Geraet und die App-Uhr muessen synchron sein (bis ±60 s ok).

### Rechtlicher Hintergrund

- **§146 Abs. 4 AO / GoBD** — einmal erzeugte Rechnungs-Stundensaetze
  duerfen nicht rueckwirkend geaendert werden.
- **Art. 32 DSGVO** — angemessene Sicherheit durch technische und
  organisatorische Massnahmen. 2FA ist eine solche TOM.
- **Betriebsrats-Mitbestimmung** — zentrale Einstellungen zur
  Arbeitszeiterfassung (Wochenarbeitszeit-Default, Urlaubstage)
  unterliegen §87 BetrVG.

## Zugriffsstatus

Zeigt die aktuelle Konfiguration:

- **Organisation**: Organisations-ID
- **Team**: Team-ID oder "Admin-Modus (kein Team)"
- **Rolle**: Organisations-Admin, PV-Admin, Teamleitung, Mitarbeiter oder Pruefer
- **Zwei-Faktor-Authentifizierung**: Aktiviert/Nicht eingerichtet (mit Einrichten-Button)
- **Meine Berechtigungen**: Aufklappbare Liste aller Rechte der aktuellen Rolle

## Benutzerprofil

- Name und Vorname
- Berufsgruppe
- Wochenarbeitszeit (Standard: 40 Stunden)
- Urlaubstage (Standard: 30 Tage)
- Buero-Standort (Standard-Startort fuer Fahrwege)

## Darstellung

- Dunkelmodus ein/aus
- Sprache (Deutsch)
- Kalender-Schluesselwoerter (fuer Terminfilterung)

## FLS-Kalkulation

Globale Einstellungen fuer die Fachleistungsstunden-Berechnung:

| Einstellung | Standard | Beschreibung |
|------------|----------|-------------|
| Kalkulationsfaktor | 1,33 | **Nur informativ** - Verhaeltnis Gesamtarbeitszeit zu Kontaktzeit. Bereits im Stundensatz eingepreist, darf nicht zusaetzlich auf Rechnungen angewendet werden. |
| Stundensatz | 40,00 EUR | Verguetung pro abgerechneter Fachleistungsstunde (aus §125-Vereinbarung) |

Diese Werte koennen pro Klient ueberschrieben werden
(`kalkulationsfaktorOverride`, `stundensatzOverride`).

## Rechnungssteller-Daten

Pflichtangaben fuer XRechnung / §14 UStG. Ohne diese Daten kann keine
rechtsguetige Rechnung erzeugt werden.

| Feld | Pflicht | Beschreibung |
|------|---------|-------------|
| Name des Leistungserbringers | ja | Firmenname bzw. Traegerbezeichnung |
| Strasse, PLZ, Ort | ja | Vollstaendige Anschrift |
| USt-IdNr. | bedingt | Bei Umsatzsteuerpflicht; bei §4 UStG-Befreiung Steuernummer |
| Steuernummer | bedingt | Alternativ zur USt-IdNr. |
| Einrichtungs-IK | empfohlen | Institutionskennzeichen der SV fuer Sozialleistungstraeger |
| IBAN / BIC / Kontoinhaber | ja | Zahlungsweg auf der Rechnung |
| E-Mail / Telefon | empfohlen | Kontaktdaten fuer Rueckfragen des Kostentraegers |

Statusbadge im Einstellungen-Screen: gruen, wenn alle Pflichtangaben
vollstaendig; rot sonst. Ein Klick oeffnet den Bearbeiten-Dialog.

## Cloud-Sync (HiDrive)

- HiDrive Benutzername und Passwort
- Organisations-ID
- Team-ID
- Sync-Passphrase (optional, fuer zusaetzliche Verschluesselung)
- Root-Unterordner (z.B. "Gemeinsam/Eingliederungshilfe")
- Verbindungstest

## Backup

- **Automatisches Backup**: Ein/Aus, Intervall in Tagen (Standard: 7)
- **Manuelles Backup**: Export aller Daten als verschluesselte Datei
- **Backup wiederherstellen**: Import einer Backup-Datei

## Datenverwaltung

- **Datenstatistik**: Anzahl Klienten und Termine
- **DSGVO-Export** (Art. 20): Vollstaendiger Datenexport, optional passwortgeschuetzt
- **Alle Daten loeschen**: Unwiderrufliche Loeschung mit Bestaetigungscode (Crypto-Erasure)

## Sicherheit

- Biometrische Authentifizierung ein/aus
- TOTP Zwei-Faktor-Authentifizierung einrichten/deaktivieren
- Entwicklermodus-Status (nur im Debug-Build)
