# Build-Anleitung

## Voraussetzungen

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.9.2
- Plattform-spezifische Tools:
    - **Windows**: Visual Studio 2022 Build Tools (C++ Desktop-Entwicklung)
    - **macOS**: Xcode (fuer macOS und iOS Builds)
    - **Android**: Android SDK, Android Studio
    - **Linux**: CMake, GTK3, pkg-config

## Setup

```bash
# Repository klonen
git clone https://github.com/miri2577/FEGH-Dokumentation.git
cd FEGH-Dokumentation

# Dependencies installieren
flutter pub get

# Code-Generierung (JSON-Serialisierung)
flutter pub run build_runner build --delete-conflicting-outputs
```

## Entwicklung starten

```bash
# Windows Desktop
flutter run -d windows

# macOS Desktop
flutter run -d macos

# Web (Edge)
flutter run -d edge

# Web (Chrome)
flutter run -d chrome

# Android (angeschlossenes Geraet)
flutter run -d <device-id>
```

## Release Build

```bash
# Windows
flutter build windows

# macOS
flutter build macos

# Android APK
flutter build apk

# Android App Bundle
flutter build appbundle

# iOS (nur auf macOS)
flutter build ios

# Web
flutter build web
```

## Bekannte Build-Probleme

### Windows: Pfadlaenge

Windows hat ein Pfadlimit von 260 Zeichen. Bei tief verschachtelten Projektpfaden kann der Build fehlschlagen. Loesung: Projekt in einen kurzen Pfad verschieben (z.B. `C:\fegh\`).

### Windows: PDB-Lock

Bei schnellen Neustarts kann die `.pdb`-Datei eines Plugins gesperrt sein. Loesung: `build/windows/x64/plugins/` loeschen und neu bauen.

### Web: Secure Storage

`FlutterSecureStorage` ist auf Web nicht vollstaendig unterstuetzt. Die App nutzt einen PBKDF2-Fallback.

## Dependencies

### Runtime
- provider 6.1.2 (State Management)
- cryptography 2.7.0, crypto 3.0.3, encrypt 5.0.3 (Verschluesselung)
- flutter_secure_storage 9.2.2 (Sichere Speicherung)
- webdav_client 1.2.2 (HiDrive WebDAV)
- local_auth 2.1.8 (Biometrie)
- mobile_scanner 3.5.5, qr_flutter 4.1.0 (QR-Codes)
- pdf 3.11.1, printing 5.13.2, syncfusion_flutter_pdf 32.2.5 (PDF)
- syncfusion_flutter_calendar (Kalender)
- responsive_framework 1.4.0 (Responsive Design)
- window_manager 0.4.3 (Desktop)

### Dev
- build_runner 2.4.9 (Code-Generierung)
- json_serializable 6.8.0 (JSON-Serialisierung)
- flutter_lints 5.0.0 (Lint-Regeln)
