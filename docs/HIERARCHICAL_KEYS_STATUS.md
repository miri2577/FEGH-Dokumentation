# Hierarchische Schlüssel – Implementierungsstand (Option B)

Datum: 2025-09-28

## Ziel

E2E‑Verschlüsselung mit hierarchischem Schlüsselmodell:

- Organisations‑Key (K_org) aus Organisations‑Passphrase
- Team‑Keys (K_team) je Team, mit K_org geschützt
- Optional: Employee‑Keys (K_emp) je Mitarbeiter, mit K_org geschützt
- Records: pro Datei DEK, geschützt mit K_team oder K_emp

## Aktueller Stand

### Mobile App (eingliederungshilfe_flutter)

- Sync‑Passphrase (Org‑Passphrase) implementiert (Settings → Cloud → „Sync‑Passphrase setzen“)
- Zweirichtungs‑Sync (erst Pull, dann Push) auf „Jetzt synchronisieren“
- Team‑Key‑Support:
  - `TeamKeyService.loadAndApplyTeamKey(teamId)` lädt `administration/teams/<team>/team-key.bin`
  - Bei Erfolg wird der MEK direkt auf den Team‑Key gesetzt (`CryptoStorage.setExternalMEK`)
  - Fallback: Sync‑Passphrase/Hardware‑Key

### Personalverwaltungs‑App

- CryptoStorage erweitert um externe Passphrase und forcierten MEK
- `TeamKeyAdminService.ensureTeamKey(teamId)`
  - erzeugt und speichert 32‑Byte Team‑Key unter `administration/teams/<team>/team-key.bin`
  - Team‑Key ist mit K_org (Org‑MEK) verschlüsselt
- HiDrive WebDAV‑Client und Sync‑Service vorhanden (Basis)

## Ordnerstruktur (relevant)

```
/users/<user>/eingliederungshilfe/organizations/<org>/
├── teams/
│   └── <team>/
│       ├── clients/
│       ├── schedules/
│       └── worktime/
├── employees/
│   └── <employee>/
│       ├── profile/
│       └── vacation/
└── administration/
    ├── employees-index.bin
    ├── clients-index.bin
    └── teams/
        └── <team>/
            └── team-key.bin
```

## Nächste Schritte

1. Personalverwaltung (UI):
   - Settings: Org‑Passphrase setzen (analog Mobile)
   - Team‑Verwaltung: Button „Team‑Key erzeugen/anzeigen“ (QR‑Export für Provisionierung) – IMPLEMENTIERT
   - Optional: Mitarbeiter‑Keys (K_emp) analog aufsetzen

2. Mobile App:
   - Provisionierung ohne Org‑Passphrase – IMPLEMENTIERT:
     - QR‑Scan des Team‑Keys → `setExternalMEK`
     - (Alternative Pfad: mobile lädt `team-key.bin` per Org‑Passphrase – bereits unterstützt)

3. Re‑Wrap/Rotation:
   - Tools, um bestehende Team‑Records (noch K_org) auf K_team umzuwrapen – BASIS IMPLEMENTIERT (Admin‑Dialog „Team‑Records rewrap“)
   - Key Rotation (K_org): Rewrap aller K_team (team-key.bin) und administrativer Dateien

4. Employee‑Keys (optional, Phase 2):
   - Struktur `employees/<id>/employee-key.bin` (mit K_org gewrappt)
   - Records unter employees/ mit K_emp verschlüsseln

## Sicherheit

- Passphrase wird lokal (Keychain/Keystore) gespeichert; nie in die Cloud
- Team‑Keys liegen verschlüsselt (mit K_org) in HiDrive
- Crypto‑Erasure: Löschen der MEK/Keys zerstört Zugriff
- PBKDF2 (100k HMAC‑SHA256 Runden) für MEK‑Ableitung aus Passphrase

## Offene Punkte

- UI/Flows Personalverwaltung (Team‑Key Management) ausbauen
- Vollständige Migration existierender Dateien auf K_team (derzeit Basis‑Rewrap vorhanden)
- Automatisierte Tests für Key‑Load/Decrypt‑Pfad

## Admin‑Sync (PV)

- AppBar‑Sync‑Button verdrahtet (Org‑Setup, Admin‑Ordner werden angelegt) – IMPLEMENTIERT
- Pull→Push in PV (Employees als Beispiel) – IMPLEMENTIERT
- Nächster Schritt: Weitere Kategorien (Clients, Timesheets, Vacation) integrieren
