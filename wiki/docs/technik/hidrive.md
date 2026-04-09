# HiDrive-Integration

## Uebersicht

Die App synchronisiert Daten ueber **STRATO HiDrive Business** mittels WebDAV-Protokoll. Alle Daten werden vor dem Upload mit AES-256-GCM verschluesselt.

## Verbindung

| Parameter | Wert |
|-----------|------|
| Protokoll | WebDAV (PROPFIND, PUT, GET, DELETE, MKCOL) |
| URL | `https://webdav.hidrive.strato.com/users/<username>` |
| Authentifizierung | HTTP Basic Auth ueber HTTPS |
| Verschluesselung | TLS + Certificate-Pinning-Unterstuetzung |

## Sync-Modi

Die App unterstuetzt drei Betriebsmodi:

### 1. Team-Modus (`HiDriveBusinessSync.forTeam()`)

Fuer Mitarbeiter eines Teams. Zugriff auf:
```
eingliederungshilfe/organizations/<orgId>/teams/<teamId>/
```

Operationen: `uploadTeamRecord`, `downloadTeamRecord`, `deleteTeamRecord`, `listTeamRecords`

Datentypen: clients, schedules, reports, worktime

### 2. Admin-Modus (`HiDriveBusinessSync.forAdmin()`)

Fuer Organisations-Admins. Zugriff auf:
```
eingliederungshilfe/organizations/<orgId>/
```

Operationen: `uploadOrgScopedRecord`, `downloadOrgScopedRecord`, `listOrgScopedRecords`, `listOrgScopedDirectories`

### 3. Legacy-Modus (`HiDriveBusinessSync.legacy()`)

Fuer Einzelnutzer ohne Organisation:
```
eingliederungshilfe_encrypted/
```

## Ordnerstruktur

```
/users/<hidrive-user>/
└── eingliederungshilfe/
    └── organizations/
        └── <orgId>/
            ├── administration/
            │   ├── users/
            │   │   └── roles.bin
            │   └── teams/
            │       └── <teamId>/
            │           └── team-key.bin
            ├── teams/
            │   └── <teamId>/
            │       ├── clients/
            │       ├── schedules/
            │       ├── reports/
            │       │   ├── monthly/
            │       │   └── annual/
            │       ├── worktime/
            │       └── team-info.bin
            ├── employees/
            └── shared/
                ├── calendar-sync/
                └── messages/
```

## Ordner-Erstellung

Ordner werden automatisch erstellt via `setupRemoteDirectory()`:

- **Team-Ordner**: clients, schedules, reports, reports/monthly, reports/annual, worktime
- **Admin-Ordner**: teams, employees, administration, shared, shared/calendar-sync, shared/messages

Bei fehlenden Zwischenordnern werden diese rekursiv angelegt (MKCOL).

## WebDAV-Operationen

| Operation | HTTP-Methode | Verwendung |
|-----------|-------------|-----------|
| Datei hochladen | PUT | Verschluesselte Records speichern |
| Datei herunterladen | GET | Records laden |
| Datei loeschen | DELETE | Records entfernen |
| Ordner erstellen | MKCOL | Strukturen anlegen |
| Ordner auflisten | PROPFIND (Depth: 1) | Dateien und Unterordner auflisten |
| Verbindung testen | PROPFIND (Root) | Erreichbarkeit pruefen |

## XML-Namespace

HiDrive verwendet `<D:...>` (Grossbuchstabe) als DAV-Namespace-Prefix. Die App parst XML-Antworten case-insensitiv. Ordnernamen werden aus dem `<D:href>`-Pfad extrahiert, da `<displayname>` bei HiDrive leer sein kann.

## Dateinamen-Konvention

Alle Dateien werden mit UUID-basierten Namen gespeichert:
```
<uuid>.bin       (verschluesselte Datensaetze)
team-info.bin    (Team-Metadaten)
team-key.bin     (verschluesselter Team-Key)
roles.bin        (Rollen-Konfiguration)
```

Keine personenbezogenen Daten in Dateinamen oder Pfaden (ausser der Organisations-ID und Team-ID).
