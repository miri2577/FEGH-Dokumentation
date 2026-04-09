# Teams verwalten

## Team erstellen

Im Verwaltung-Tab auf **"Team erstellen"** klicken oder in der Team-Verwaltung den **"+"**-Button nutzen.

### Felder

| Feld | Pflicht | Beschreibung |
|------|---------|-------------|
| Team-Name | Ja | z.B. "Team Nord", "TBEW" |
| Beschreibung | Nein | Optionale Beschreibung |
| Standort | Nein | z.B. "Berlin-Mitte" |

### Was automatisch passiert

Beim Erstellen eines Teams werden auf HiDrive automatisch angelegt:

1. **Team-Ordner** mit Unterordnern: `clients/`, `schedules/`, `reports/monthly/`, `reports/annual/`, `worktime/`
2. **Team-Key** (32 Byte AES): Zufaellig generiert, verschluesselt mit dem Org-MEK, gespeichert unter `administration/teams/<teamId>/team-key.bin`
3. **Team-Info**: Verschluesselte Team-Metadaten unter `teams/<teamId>/team-info.bin`

## Team-Status

| Status | Bedeutung |
|--------|----------|
| Aktiv | Team ist in Betrieb |
| Inaktiv | Team ist deaktiviert |
| Pausiert | Team ist voruebergehend pausiert |

## Team-Mitglieder

Mitarbeiter werden ueber den Einladungsprozess einem Team zugewiesen. Ein Mitarbeiter kann mehreren Teams angehoeren (`teamIds`-Feld im Mitarbeiter-Modell).

## Team-Klienten

Klienten werden ueber den **Klienten-Zuweisungs-Screen** einem Team zugeordnet. Die Klientendaten werden verschluesselt im Team-Verzeichnis auf HiDrive abgelegt.

Mitarbeiter des Teams koennen nur die Klienten ihres eigenen Teams sehen. Admins sehen alle Klienten aller Teams.

## Team-Key

Jedes Team hat einen eigenen 32-Byte AES-Schluessel. Dieser wird:

- Bei Team-Erstellung zufaellig generiert
- Mit dem Organisations-MEK verschluesselt auf HiDrive gespeichert
- Ueber den Provisioning-Token an Mitarbeiter verteilt
- Fuer die Ver- und Entschluesselung aller Team-Daten verwendet
