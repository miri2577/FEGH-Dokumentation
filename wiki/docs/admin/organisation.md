# Organisation einrichten

## Ablauf

1. App installieren und starten
2. Im Setup-Wizard **"Organisation einrichten"** waehlen
3. Profil eingeben (Vorname, Nachname)
4. **HiDrive Cloud-Sync** als Speichermodus waehlen
5. HiDrive-Zugangsdaten eingeben
6. **Organisations-ID** vergeben (z.B. `meine-firma`, `fegh-berlin`)
7. **Admin-Modus** aktivieren
8. Verbindung testen
9. App starten

## Nach dem Setup

1. Im **Verwaltung-Tab** auf **"Org initialisieren"** klicken
2. Die Ordnerstruktur wird auf HiDrive erstellt
3. Ein **Recovery-Key** wird angezeigt -- sicher aufbewahren!
4. Erstes Team erstellen
5. Mitarbeiter einladen

## HiDrive-Voraussetzungen

- STRATO HiDrive Business Account
- WebDAV-Zugriff aktiviert (in HiDrive-Einstellungen)
- Benutzername und Passwort bekannt

Die App erstellt alle Ordner automatisch. Sie muessen in HiDrive nichts manuell anlegen.

## Ordnerstruktur auf HiDrive

Nach der Initialisierung sieht die Struktur so aus:

```
/users/<hidrive-user>/
└── eingliederungshilfe/
    └── organizations/
        └── <orgId>/
            ├── administration/
            │   ├── users/
            │   │   └── roles.bin        (Rollen-Konfiguration)
            │   └── teams/
            │       └── <teamId>/
            │           └── team-key.bin  (verschluesselter Team-Key)
            ├── teams/
            │   └── <teamId>/
            │       ├── clients/          (Klientendaten)
            │       ├── schedules/        (Terminplaene)
            │       ├── reports/
            │       │   ├── monthly/      (Monatsberichte)
            │       │   └── annual/       (Jahresberichte)
            │       ├── worktime/         (Arbeitszeitdaten)
            │       └── team-info.bin     (verschluesselte Team-Info)
            ├── employees/                (Mitarbeiterdaten)
            └── shared/
                ├── calendar-sync/        (Kalender-Synchronisation)
                └── messages/             (Nachrichten)
```

Alle `.bin`-Dateien sind AES-256-GCM verschluesselt. Dateinamen sind UUIDs -- keine personenbezogenen Daten in Dateinamen.
