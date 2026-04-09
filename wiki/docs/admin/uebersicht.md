# Administration -- Uebersicht

## Voraussetzungen

Der Verwaltung-Tab ist nur sichtbar fuer Benutzer mit der Rolle **Organisations-Admin** oder **PV-Admin**.

## Admin-Dashboard

Das Admin-Dashboard zeigt:

### Statistiken
- Anzahl Teams
- Anzahl Mitarbeiter
- Anzahl Klienten

### System-Status (Health Checks)

| Pruefung | Beschreibung |
|----------|-------------|
| HiDrive-Verbindung | WebDAV-Erreichbarkeit |
| Administration-Ordner | `administration/` existiert |
| Teams-Ordner | `teams/` existiert |
| Rollen-Konfiguration | `roles.json` vorhanden |
| Schreibzugriff | Datei schreiben und loeschen moeglich |

### Schnellaktionen

- **Team erstellen**: Neues Team mit HiDrive-Ordnerstruktur
- **Mitarbeiter einladen**: Provisioning-Token generieren
- **Klient zuweisen**: Klient einem Team zuordnen
- **Org initialisieren**: Erstmalige Ordnerstruktur auf HiDrive erstellen

## Organisation initialisieren

Beim ersten Mal muss die Organisationsstruktur auf HiDrive erstellt werden. Dies geschieht ueber den Button "Org initialisieren" im Verwaltung-Tab.

Dabei wird automatisch erstellt:

```
eingliederungshilfe/organizations/<orgId>/
├── administration/
├── teams/
├── employees/
├── shared/
│   ├── calendar-sync/
│   └── messages/
```

Zusaetzlich wird eine `roles.json` mit dem aktuellen Admin als erster Benutzer erstellt.

Nach der Initialisierung wird ein **Recovery-Key** (12 deutsche Woerter) angezeigt. Dieser muss sicher aufbewahrt werden (ausdrucken, Safe). Ohne den Recovery-Key ist bei Passwortverlust kein Zugriff auf die verschluesselten Daten moeglich.
