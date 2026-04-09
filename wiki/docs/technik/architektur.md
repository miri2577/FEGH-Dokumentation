# Architektur

## Technologie-Stack

| Komponente | Technologie |
|-----------|-------------|
| Framework | Flutter (Dart) |
| State Management | Provider (ChangeNotifier), spezialisierte Sub-Provider |
| Verschluesselung | AES-256-GCM (cryptography), PBKDF2 100k Iterationen |
| Cloud-Sync | WebDAV (HiDrive, Nextcloud, eigener Server) via CloudStorageAdapter |
| Chat | Matrix-Protokoll (Conduit Server, Rust), E2E Megolm |
| Lokaler Speicher | Flutter Secure Storage, SharedPreferences |
| PDF-Generierung | pdf, Syncfusion Flutter PDF |
| Kalender | Syncfusion Flutter Calendar |
| QR-Codes | mobile_scanner (Scan), qr_flutter (Generierung) |
| Authentifizierung | local_auth (Biometrie), TOTP 2FA (RFC 6238), Session-Timeout |
| Audit | Persistenter JSON-Lines Logger (AuditLogger) |

## Verzeichnisstruktur

```
lib/
├── main.dart                 # App-Einstiegspunkt
├── config/
│   └── developer_mode.dart   # Build-Parameter Sicherheit
├── models/                   # Datenmodelle (JSON-Serialisierung)
│   ├── app_settings.dart     # Globale Konfiguration + UserRole
│   ├── client.dart           # Klientenstammblatt
│   ├── appointment.dart      # Termine
│   ├── arbeitszeit.dart      # Arbeitszeit-Eintraege
│   ├── mitarbeiter.dart      # Mitarbeiter
│   ├── team.dart             # Teams (Multi-Team)
│   ├── message.dart          # Nachrichten
│   ├── informationsbericht.dart  # Berliner Formular 101
│   ├── freizeit_antrag.dart  # Urlaubs-/Freizeitantraege
│   ├── fahrweg.dart          # Fahrtstrecken
│   ├── tib_ziel.dart         # Teilhabeziele (TIB)
│   ├── standort.dart         # Standorte
│   └── ...                   # Weitere Modelle
├── providers/
│   ├── app_provider.dart         # Zentraler App-State (Fassade)
│   ├── auth_provider.dart        # Authentifizierung (spezialisiert)
│   ├── client_provider.dart      # Klientenverwaltung (spezialisiert)
│   └── settings_provider.dart    # Einstellungen (spezialisiert)
├── services/                 # Business-Logik
│   ├── secure_storage_service.dart   # Datenpersistenz (await Cloud-Ops)
│   ├── crypto_storage.dart           # Verschluesselung (MEK/DEK, sichere Loeschung)
│   ├── hidrive_webdav_client.dart    # HiDrive WebDAV-Client
│   ├── cloud_storage_adapter.dart    # Abstraktionsschicht (HiDrive/Nextcloud/Lokal)
│   ├── matrix_chat_service.dart      # Matrix-Chat (E2E, Raeume, Dateien)
│   ├── admin_service.dart            # Admin-Operationen
│   ├── permission_service.dart       # Rollenbasierte Zugriffskontrolle
│   ├── totp_service.dart             # TOTP 2FA (RFC 6238)
│   ├── recovery_service.dart         # Passwort-Recovery (Token + 12-Wort-Key)
│   ├── document_lock_service.dart    # Dokument-Locking (Optimistic)
│   ├── audit_logger.dart             # DSGVO Audit-Log (JSON-Lines)
│   ├── pdf_generator_service.dart    # PDF-Export
│   ├── export_service.dart           # CSV/JSON-Export
│   ├── gdpr_service.dart             # DSGVO-Funktionen
│   ├── backup_service.dart           # Backup/Restore
│   ├── team_key_service.dart         # Team-Key-Verwaltung
│   ├── authentication_service.dart   # Biometrische Auth
│   ├── security_service.dart         # Geraetesicherheit
│   └── ...                           # Weitere Services
├── screens/                  # UI-Screens
│   ├── home_screen.dart      # Dashboard + Tab-Navigation
│   ├── auth_screen.dart      # Anmeldung + TOTP
│   ├── setup_wizard_screen.dart  # Ersteinrichtung
│   ├── admin/                # Admin-Screens
│   │   ├── admin_dashboard_screen.dart
│   │   ├── team_management_screen.dart
│   │   ├── employee_invitation_screen.dart
│   │   └── client_assignment_screen.dart
│   └── ...                   # 20+ weitere Screens
├── widgets/                  # Wiederverwendbare UI-Komponenten
│   ├── adaptive_navigation.dart  # Responsive Navigation
│   └── ...
└── utils/                    # Hilfsfunktionen
    ├── responsive_utils.dart
    ├── platform_utils.dart
    └── theme_config.dart
```

## App-Start-Flow

```
main() → SecurityCheck → AppProvider.initialize()
  → AuthScreen (Biometrie/Passwort + optional TOTP)
    → SetupWizardScreen (falls Ersteinrichtung)
      → HomeScreen (Dashboard mit Tab-Navigation)
```

## State Management

Ein zentraler `AppProvider` (ChangeNotifier) verwaltet:

- Authentifizierungsstatus
- App-Einstellungen
- Klienten, Termine, Arbeitszeiten, Mitarbeiter
- Lade- und Fehlerzustaende
- Cloud-Sync-Status

Daten werden in zwei Phasen geladen:

1. **Essentiell** (blockiert UI): Storage-Init, Biometrie-Check, Settings
2. **Deferred** (Hintergrund): Klienten, Termine, Mitarbeiter, Nachrichten

## Responsive Design

Die App verwendet `ResponsiveFramework` mit folgenden Breakpoints:

| Breakpoint | Bereich | Navigation |
|-----------|---------|-----------|
| Mobile | 0-450px | Bottom Navigation Bar (4 Tabs + Mehr) |
| Tablet | 451-800px | Navigation Drawer |
| Desktop | 801-1920px | Navigation Rail (links) |
| 4K | >1920px | Navigation Rail (erweitert) |
