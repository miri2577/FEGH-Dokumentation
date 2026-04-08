# Plan: Admin-Funktionalität in FEGH-Dokumentation

## Kontext

Die FEGH-Verwaltungsapp (Flutter, Riverpod) ist noch nicht fertig. Bis dahin muss FEGH-Dokumentation eigenständig Admin-Funktionen bieten: Organisation einrichten, Teams/Mitarbeiter/Klienten anlegen, HiDrive-Strukturen automatisch erzeugen, und Mitarbeiter per Token einladen.

Analyse beider Apps abgeschlossen. Die Verwaltungsapp hat wertvolle Konzepte (Provisioning-QR, RolesPolicyService, Health Checks, Drift Detection), die wir übernehmen.

## Architektur-Entscheidung: Eine App, rollenbasiert

Keine separate App/Branch. Rollenbasierte UI im bestehenden Projekt.

- `isAdmin`, `HiDriveBusinessSync.forAdmin()`, QR-Scan mit Rollenerkennung existieren bereits
- Admin-Screens in `lib/screens/admin/` klar getrennt
- Admin kann die App gleichzeitig als eigenes Dokumentationstool nutzen

---

## Phase 1: Foundation -- Datenmodelle & Services

### 1a. `lib/models/team.dart` (NEU)
Orientiert an Verwaltungsapp (`FEGH-Verwaltung/lib/models/team.dart`):
```dart
class Team {
  final String id, name, description;
  final String? department, location, teamLeaderId;
  final List<String> memberIds;
  final List<String> clientIds;
  final TeamStatus status; // active, inactive, onHold
  final DateTime createdAt, updatedAt;
}
```

### 1b. `UserRole` Enum in `lib/models/app_settings.dart`
Übernommen aus Verwaltungsapp `roles_policy_service.dart`:
```dart
enum UserRole { orgAdmin, pvAdmin, teamLead, teamMember, orgAuditor }
```
- `isAdmin` wird Getter: `get isAdmin => role == orgAdmin || role == pvAdmin`
- Backward-kompatibel mit bestehendem `bool isAdmin`

### 1c. `Mitarbeiter` erweitern (`lib/models/mitarbeiter.dart`)
- Neues Feld `teamIds: List<String>` (Mitarbeiter kann in mehreren Teams sein)
- `teamNummer` bleibt für Kompatibilität

### 1d. `lib/services/admin_service.dart` (NEU)
Zentraler Admin-Service, baut auf bestehenden Services auf:

**Team-Verwaltung:**
- `createTeam(Team)` -- HiDrive-Ordner anlegen via `HiDriveBusinessSync.forTeam()` + `setupRemoteDirectory()`, Team-Key generieren (32 Byte AES), verschlüsselt nach `administration/teams/<teamId>/team-key.bin` hochladen
- `updateTeam()`, `deleteTeam()`, `listTeams()`

**Mitarbeiter-Einladung (Provisioning-QR aus Verwaltungsapp):**
- `generateProvisioningToken()` -- Payload-Format:
  ```json
  {
    "type": "egh-provisioning-v1",
    "org": "<orgId>",
    "user": "<email>",
    "role": "team_member|team_lead",
    "teams": ["team-a"],
    "teamKeys": { "team-a": "<base64>" },
    "hidrive": { "username": "...", "appPassword": "..." },
    "flags": { "managed": true, "forceInitialSync": true },
    "ts": "ISO-8601"
  }
  ```
- Token wird mit PIN verschlüsselt (AES-256-GCM, PBKDF2 aus 6-stelligem PIN)

**Klienten-Zuweisung:**
- `assignClientToTeam(clientId, teamId)` -- Klient-Record in Team-Verzeichnis hochladen

**Rollen-Verwaltung (aus Verwaltungsapp `roles_policy_service.dart`):**
- `roles.json` auf HiDrive unter `administration/users/roles.json`
- `addUserRole()`, `removeUserRole()`, `getRoleFor(username)`

**Health Checks (aus Verwaltungsapp `admin_health_service.dart`):**
- Ordnerstruktur prüfen, Schreibtest, roles.json vorhanden?

---

## Phase 2: Admin-Screens

Alle unter `lib/screens/admin/`.

### 2a. `admin_dashboard_screen.dart`
- Übersicht: Teams, Mitarbeiter, Klienten (Statistiken)
- Health-Status: Ordnerstruktur OK? Sync OK? roles.json vorhanden?
- Quick Actions: Team erstellen, Mitarbeiter einladen, Klient zuweisen

### 2b. `team_management_screen.dart`
- Teams auflisten, erstellen, bearbeiten
- Team-Mitglieder und zugewiesene Klienten anzeigen
- Bei Erstellung: HiDrive-Ordner automatisch angelegt

### 2c. `employee_invitation_screen.dart`
- Mitarbeiter auswählen/erstellen, Team zuweisen, Rolle festlegen
- Provisioning-Token generieren (Format aus Verwaltungsapp)
- Anzeige als QR-Code + kopierbarer Text + PIN-Anzeige

### 2d. `client_assignment_screen.dart`
- Klienten Teams zuordnen/umordnen
- Bei Zuweisung: Upload in Team-Verzeichnis auf HiDrive

---

## Phase 3: Setup-Wizard für Mitarbeiter-Onboarding

### Änderung in `lib/screens/setup_wizard_screen.dart`

Verzweigung auf Willkommens-Seite:

**Pfad A: "Organisation einrichten" (Admin)**
1. HiDrive-Credentials eingeben
2. Organisation benennen (Name, Typ)
3. Erstes Team erstellen
4. Org-Ordnerstruktur auf HiDrive automatisch anlegen
5. Admin-Rolle wird gesetzt, App startet im Admin-Modus

**Pfad B: "Einladungscode verwenden" (Mitarbeiter)**
1. QR scannen oder Token-Text einfügen
2. PIN eingeben → Token entschlüsseln
3. Automatisch konfiguriert: HiDrive-Credentials, Org-ID, Team-ID, Team-Key, Rolle
4. Persönliches App-Passwort vergeben
5. Profil bestätigen → Fertig, App startet mit Team-Zugang

---

## Phase 4: Navigation & UI-Integration

- Neuer Tab "Verwaltung" in Navigation, nur sichtbar wenn `isAdmin`
- Admin-Dashboard als zusätzlicher Screen
- Admin-Aktionen in Settings-Screen

---

## Phase 5: HiDrive-Erweiterungen

- `createTeamDirectories(teamId)` -- Team-Verzeichnis mit allen Unterordnern
- `saveTeamToCloud()`, `loadTeamsFromCloud()`, `saveTeamKeyToCloud()`, `saveRolesPolicy()`

---

## Verifizierung

1. Admin-Flow: App starten → Setup als Admin → Org erstellen → Team erstellen → HiDrive-Ordner prüfen
2. Einladungs-Flow: QR generieren → zweites Gerät → scannen + PIN → automatische Konfiguration
3. Klient-Zuweisung: Klient zuweisen → Daten im Team-Verzeichnis auf HiDrive prüfen
4. Bestehende Features: Termine, Berichte, Arbeitszeit dürfen nicht beeinträchtigt werden
5. `flutter analyze` ohne Fehler
