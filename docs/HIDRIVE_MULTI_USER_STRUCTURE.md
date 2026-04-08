# HiDrive Multi-User/Multi-Team Ordnerstruktur

## Übersicht

Diese Dokumentation beschreibt die Implementierung einer professionellen Multi-User/Multi-Team Ordnerstruktur für die Eingliederungshilfe-Apps mit HiDrive Cloud-Synchronisation.

## Problemstellung

**Ursprüngliche Struktur:**
- Einfache Struktur: `/users/eghadmin/eingliederungshilfe_encrypted/`
- Nur einzelne Team-/Benutzer-Verwaltung
- Keine Unterstützung für mehrere Träger, Teams oder granulare Zugriffsrechte

**Anforderungen:**
1. Mehrere Benutzer pro Team
2. Mehrere Teams pro Träger
3. Personalverwaltungs-App muss alle Klienten verwalten können
4. Team-Apps müssen nur ihre Klienten sehen
5. Flexible Zugriffsrechte
6. DSGVO-konforme Datentrennung

## Neue Ordnerstruktur

```
/users/eghadmin/eingliederungshilfe/
├── organizations/
│   └── [träger-id]/                    # Z.B. "egh-mustertraeger"
│       ├── teams/
│       │   ├── [team-1-id]/           # Z.B. "team-wohnen-nord"
│       │   │   ├── clients/
│       │   │   │   ├── [client-uuid].bin
│       │   │   │   └── manifest.json.enc
│       │   │   ├── schedules/
│       │   │   │   ├── [schedule-uuid].bin
│       │   │   │   └── manifest.json.enc
│       │   │   ├── reports/
│       │   │   │   ├── monthly/
│       │   │   │   │   └── [report-uuid].bin
│       │   │   │   └── annual/
│       │   │   │       └── [report-uuid].bin
│       │   │   └── worktime/
│       │   │       ├── [timeentry-uuid].bin
│       │   │       └── manifest.json.enc
│       │   └── [team-2-id]/           # Z.B. "team-ambulant-sued"
│       │       └── ...
│       ├── employees/
│       │   ├── [employee-uuid].bin    # Mitarbeiterdaten
│       │   └── manifest.json.enc
│       ├── administration/
│       │   ├── teams.json.enc         # Team-Konfiguration
│       │   ├── permissions.json.enc   # Zugriffsrechte
│       │   └── organization.json.enc  # Träger-Stammdaten
│       └── shared/
│           ├── calendar-sync/
│           │   └── [calendar-event-uuid].bin
│           └── messages/
│               └── [message-uuid].bin
└── system/
    ├── access-logs/
    └── sync-metadata/
```

## Zugriffslogik

### 1. Personalverwaltungs-App (Admin-Zugriff)
- **Basis-URL**: `/users/eghadmin/eingliederungshilfe/organizations/[träger-id]/`
- **Vollzugriff auf:**
  - Alle Teams und deren Klienten
  - Mitarbeiterverwaltung
  - Administration
  - Reports aller Teams

### 2. Team-Apps (Team-spezifischer Zugriff)
- **Basis-URL**: `/users/eghadmin/eingliederungshilfe/organizations/[träger-id]/teams/[team-id]/`
- **Zugriff nur auf:**
  - Eigene Team-Klienten
  - Eigene Termine und Arbeitszeiten
  - Shared Calendar/Messages (readonly)

### 3. Mobile Apps (Mitarbeiter-Zugriff)
- **Basis-URL**: Abhängig von Mitarbeiter-Team-Zuordnung
- **Zugriff auf:**
  - Zugewiesene Klienten
  - Eigene Arbeitszeiten
  - Relevante Termine

## Implementierung

### Phase 1: Ordnerstruktur-Update
1. `HiDriveConfig` erweitern um Multi-Tenant Pfade
2. `setupRemoteDirectory` anpassen für neue Struktur
3. Migrations-Logic für bestehende Daten

### Phase 2: Zugriffskontrolle
1. Team-basierte URL-Generierung
2. Permissions-System implementieren
3. Settings erweitern um Team/Träger-Konfiguration

### Phase 3: Synchronisation
1. Team-spezifische Sync-Logic
2. Shared-Data Synchronisation
3. Conflict-Resolution für geteilte Klienten

## Vorteile

### Skalierbarkeit
- ✅ Unbegrenzte Anzahl Träger, Teams, Mitarbeiter
- ✅ Flexible Team-Strukturen
- ✅ Einfache Erweiterung um neue Organisationen

### Sicherheit
- ✅ DSGVO-konforme Datentrennung
- ✅ Granulare Zugriffsrechte
- ✅ Team-Isolation bei Datenlecks
- ✅ Audit-Trail durch access-logs

### Funktionalität
- ✅ Team-übergreifende Klienten-Betreuung möglich
- ✅ Zentrale Administration
- ✅ Geteilte Kalender und Nachrichten
- ✅ Flexible Report-Strukturen

## Migration

### Bestehende Daten
```bash
# Alt: /users/eghadmin/eingliederungshilfe_encrypted/[uuid].bin
# Neu: /users/eghadmin/eingliederungshilfe/organizations/default/teams/default/clients/[uuid].bin
```

### Migrations-Script
1. Bestehende `.bin` Dateien identifizieren
2. In neue Struktur verschieben
3. Manifests aktualisieren
4. Settings-Migration

## Technische Details

### URL-Generierung
```dart
// Alt
HiDriveConfig.buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe_encrypted')

// Neu
HiDriveConfig.buildTeamUrl(username, organizationId, teamId, dataType)
```

### Beispiel-URLs
```
Admin: /users/eghadmin/eingliederungshilfe/organizations/egh-muster/
Team:  /users/eghadmin/eingliederungshilfe/organizations/egh-muster/teams/wohnen-nord/
```

## Status

- [x] Analyse der Anforderungen
- [x] Strukturkonzept entwickelt
- [ ] Code-Implementierung
- [ ] Testing mit Multi-Team Szenario
- [ ] Migration bestehender Daten
- [ ] Dokumentation für Endbenutzer

## Nächste Schritte

1. `HiDriveConfig` erweitern um neue Pfad-Methoden
2. `setupRemoteDirectory` für Multi-Team Struktur anpassen
3. Settings erweitern um Träger/Team-Konfiguration
4. Migration-Logic implementieren
5. Tests mit mehreren Teams durchführen