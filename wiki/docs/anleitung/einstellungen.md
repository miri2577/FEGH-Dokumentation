# Einstellungen

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
