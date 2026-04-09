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
| Kalkulationsfaktor | 1,33 | Verhaeltnis Gesamtarbeitszeit zu abrechnungsfaehiger Zeit (Berlin-typisch: 1,25-1,33) |
| Stundensatz | 40,00 EUR | Verguetung pro Fachleistungsstunde |

Diese Werte koennen pro Klient ueberschrieben werden.

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
