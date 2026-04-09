# Datentrennung zwischen Organisationen

## 3 Ebenen der Datenisolation

### 1. HiDrive-Account (Physische Trennung)

Jeder Admin hat eigene HiDrive-Credentials (Benutzername + Passwort). Er kann nur auf seinen eigenen HiDrive-Speicher zugreifen. Ein anderer Admin mit anderem Account sieht physisch andere Dateien.

- HiDrive-Zugangsdaten werden lokal verschluesselt gespeichert
- WebDAV-Verbindung ist TLS-verschluesselt mit Certificate-Pinning-Unterstuetzung
- Kein zentraler Server -- jede Organisation nutzt ihren eigenen HiDrive-Speicher

### 2. Organisations-ID (Logische Trennung)

Alle Daten liegen unter einem organisationsspezifischen Pfad:

```
eingliederungshilfe/organizations/<orgId>/
```

Verschiedene Organisations-IDs haben komplett getrennte Pfade -- selbst auf dem gleichen HiDrive-Account.

### 3. Verschluesselung (Kryptographische Trennung)

Jede App-Installation hat einen eigenen Master Encryption Key (MEK):

- AES-256-GCM fuer alle Daten
- Envelope Encryption: Jeder Datensatz hat eigenen DEK
- Selbst bei physischem Dateizugriff ist Entschluesselung ohne MEK unmoeglich

## Szenarien

### Zwei verschiedene Organisationen

| | Admin A | Admin B |
|---|---------|---------|
| HiDrive-User | `adminA` | `adminB` |
| OrgId | `org-alpha` | `org-beta` |
| MEK | Eigener Schluessel | Eigener Schluessel |
| Daten-Pfad | `organizations/org-alpha/` | `organizations/org-beta/` |

**Ergebnis:** Komplett getrennte Welten. Kein gegenseitiger Zugriff moeglich.

### Gleiche Organisation, verschiedene Rollen

| | Admin | Mitarbeiter Team-Nord |
|---|-------|----------------------|
| Zugriff | Gesamte Organisation | Nur `teams/team-nord/` |
| Schluessel | Org-MEK | Team-Key |
| Sichtbar | Alle Teams, alle Klienten | Nur eigenes Team |

**Ergebnis:** Mitarbeiter sehen nur die Daten ihres Teams.

## Zusammenfassung

Ohne die richtigen HiDrive-Credentials **und** den passenden Encryption Key kommt niemand an fremde Daten. Die Kombination aus physischer, logischer und kryptographischer Trennung stellt vollstaendige Isolation sicher.
