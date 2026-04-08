# Sicherheit & Datentrennung zwischen Organisationen

## Uebersicht

Die FEGH-Dokumentation App stellt sicher, dass verschiedene Admins und Organisationen niemals auf fremde Daten zugreifen koennen. Die Isolation funktioniert ueber drei unabhaengige Ebenen.

## 3 Ebenen der Datentrennung

### 1. HiDrive-Account (Physische Trennung)

Jeder Admin hat seine eigenen HiDrive-Credentials (Benutzername + Passwort). Er kann nur auf seinen eigenen HiDrive-Speicher zugreifen. Ein anderer Admin mit anderem HiDrive-Account sieht physisch andere Dateien.

- HiDrive-Zugangsdaten werden lokal verschluesselt gespeichert
- WebDAV-Verbindung ist TLS-verschluesselt mit Certificate Pinning
- Kein zentraler Server -- jede Organisation nutzt ihren eigenen HiDrive-Speicher

### 2. Organisations-ID (Logische Trennung)

Alle Daten liegen unter einem organisationsspezifischen Pfad:

```
eingliederungshilfe/organizations/<orgId>/
├── administration/    # Admin-Daten, Rollen, Team-Keys
├── teams/             # Team-spezifische Daten
├── employees/         # Mitarbeiter-Daten
└── shared/            # Geteilte Ressourcen (Kalender, Nachrichten)
```

Wenn Organisation A die OrgId `org-alpha` verwendet und Organisation B `org-beta`, sind die Pfade komplett getrennt -- selbst wenn sie theoretisch den gleichen HiDrive-Account nutzen wuerden.

### 3. Verschluesselung (Kryptographische Trennung)

Jede App-Installation hat einen eigenen **Master Encryption Key (MEK)**:

- **AES-256-GCM** Verschluesselung fuer alle gespeicherten Daten
- **Envelope Encryption**: Jeder Datensatz hat einen eigenen Data Encryption Key (DEK), der mit dem MEK verschluesselt wird
- Der MEK wird im OS-Keychain gespeichert (oder per PBKDF2 mit 100.000 Iterationen abgeleitet)
- Selbst wenn jemand physischen Zugriff auf die HiDrive-Dateien haette, kann er sie ohne den passenden MEK nicht entschluesseln

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
| Schluessel | Org-MEK | Team-Key (via Provisioning-Token) |
| Kann sehen | Alle Teams, alle Klienten | Nur eigenes Team und zugewiesene Klienten |

**Ergebnis:** Mitarbeiter sehen nur die Daten ihres Teams. Der Team-Key wird ueber den Provisioning-Token (QR-Code + PIN) sicher uebertragen.

### Mitarbeiter-Onboarding

1. Admin erstellt Einladung → generiert Provisioning-Token mit Team-Key
2. Token wird mit 6-stelligem PIN verschluesselt (AES-256-GCM, PBKDF2)
3. PIN wird separat uebermittelt (muendlich, SMS, etc.)
4. Mitarbeiter scannt QR-Code + gibt PIN ein → App konfiguriert sich automatisch
5. Mitarbeiter erhaelt nur den **Team-Key**, nicht den Admin-MEK

## Zusammenfassung

Ohne die richtigen HiDrive-Credentials **und** den passenden Encryption Key kommt niemand an fremde Daten. Die Kombination aus physischer Trennung (HiDrive-Account), logischer Trennung (Organisations-ID) und kryptographischer Trennung (MEK/Team-Keys) stellt sicher, dass jede Organisation und jedes Team isoliert ist.
