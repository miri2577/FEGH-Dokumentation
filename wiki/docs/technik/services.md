# Services

## Uebersicht aller Services

| Service | Datei | Zweck |
|---------|-------|-------|
| SecureStorageService | `secure_storage_service.dart` | Zentrale Datenpersistenz mit Verschluesselung |
| CryptoStorage | `crypto_storage.dart` | AES-256-GCM Verschluesselung (MEK/DEK) |
| HiDriveWebDAVClient | `hidrive_webdav_client.dart` | WebDAV-Client fuer HiDrive |
| AdminService | `admin_service.dart` | Team-CRUD, Provisioning, Rollen, Health Checks |
| PermissionService | `permission_service.dart` | Rollenbasierte Zugriffskontrolle |
| TotpService | `totp_service.dart` | TOTP 2FA nach RFC 6238 |
| RecoveryService | `recovery_service.dart` | Passwort-Recovery und Admin-Recovery-Key |
| DocumentLockService | `document_lock_service.dart` | Optimistic Locking fuer Dokumente |
| PdfGeneratorService | `pdf_generator_service.dart` | PDF-Export (3 Varianten) |
| ExportService | `export_service.dart` | CSV/JSON-Datenexport |
| GdprService | `gdpr_service.dart` | DSGVO-Export und Crypto-Erasure |
| BackupService | `backup_service.dart` | Backup/Restore mit optionaler Verschluesselung |
| MessageService | `message_service.dart` | Internes Nachrichtensystem |
| TeamKeyService | `team_key_service.dart` | Team-Key laden und anwenden |
| AuthenticationService | `authentication_service.dart` | Biometrische Authentifizierung |
| WebAuthService | `web_auth_service.dart` | Web/Desktop Passwort-Auth |
| SecurityService | `security_service.dart` | Geraetesicherheit (Root, Jailbreak, USB-Debug) |
| DistanceService | `distance_service.dart` | Fahrtstrecken-Berechnung (OpenRouteService) |
| DemoDataService | `demo_data_service.dart` | Demo-Daten fuer Ersteinrichtung |
| AppLifecycleService | `app_lifecycle_service.dart` | App-Lebenszyklus (Init, Pause, Resume) |
| FileLogger | `file_logger.dart` | Dateibasiertes Logging |
| AppLogger | `app_logger.dart` | Kategorisiertes Konsolen-Logging |

## AdminService (Detail)

Der AdminService orchestriert alle Admin-Operationen:

### Team-Verwaltung
- `createTeam(Team)` -- HiDrive-Ordner + Team-Key erstellen
- `listTeams()` -- Teams von HiDrive laden und entschluesseln
- `updateTeam(Team)` -- Team-Info aktualisieren

### Provisioning
- `generateProvisioningToken(email, role, teamIds, pin)` -- Verschluesselten Token mit Team-Keys + TOTP-Secret generieren
- `decryptProvisioningToken(tokenB64, pin)` -- Token entschluesseln (statisch, fuer Empfaengerseite)

### Rollen
- `loadRolesPolicy()` / `saveRolesPolicy()` -- roles.json auf HiDrive lesen/schreiben
- `setUserRole(userId, role, teams)` -- Rolle zuweisen
- `removeUserRole(userId)` -- Rolle entfernen

### Health Checks
- `runHealthChecks()` -- Verbindung, Ordner, Roles, Schreibzugriff pruefen

### Organisation
- `initializeOrganizationStructure()` -- Ordnerstruktur erstellen + initiale roles.json

### Klienten
- `assignClientToTeam(clientId, teamId, encryptedData)` -- Klient verschluesselt ins Team-Verzeichnis

## PermissionService (Detail)

Nimmt eine `UserRole` und gibt boolesche Werte fuer jede Berechtigung zurueck:

- `canViewClients`, `canCreateClient`, `canEditClientMasterData`, `canDeleteClient`
- `canManageAppointments`, `canWriteReports`, `canExportReports`
- `canTrackWorkTime`, `canViewOtherWorkTime`
- `canManageTeams`, `canInviteEmployees`, `canChangeRoles`
- `canManageOrganization`, `canAccessAdmin`, `canUseAdminTools`
- `canGenerateRecoveryToken`, `canRecoverTeamLead`
- `canViewAuditLog`, `isReadOnly`
- `roleDisplayName`, `permissionSummary`

## TotpService (Detail)

Komplett eigenstaendige RFC 6238 Implementierung:

- `generateSecret()` -- 20 Byte kryptographisch sicher
- `secretToBase32()` / `base32ToSecret()` -- Kodierung
- `generateCode(secret)` -- Aktuellen 6-stelligen Code berechnen
- `verifyCode(secret, code)` -- Code pruefen (±1 Zeitschritt Toleranz)
- `generateOtpAuthUri()` -- URI fuer Authenticator-Apps
- `remainingSeconds()` -- Sekunden bis naechster Code-Wechsel
