# Plattformen

## Unterstuetzte Plattformen

| Plattform | Status | Besonderheiten |
|-----------|--------|---------------|
| **Windows** | Unterstuetzt | Desktop-App, Mindestgroesse 800x600, Vollbild-Toggle |
| **macOS** | Unterstuetzt | Desktop-App, Code-Signiert, Keychain-Integration |
| **Linux** | Unterstuetzt | Desktop-App |
| **iOS** | Unterstuetzt | iPhone/iPad, Biometrie (Face ID, Touch ID) |
| **Android** | Unterstuetzt | Smartphone/Tablet, Biometrie, Root-Erkennung |
| **Web** | Unterstuetzt | Browser-basiert, Passwort-Auth statt Biometrie |

## Plattform-spezifisches Verhalten

### Authentifizierung

| Plattform | Primaer | Fallback |
|-----------|---------|----------|
| iOS | Face ID / Touch ID | Geraete-Passcode |
| Android | Fingerabdruck / Face | Geraete-PIN |
| macOS | Touch ID | Passwort |
| Windows | Windows Hello | App-Passwort |
| Linux | -- | App-Passwort |
| Web | -- | Benutzername + Passwort |

### Verschluesselungs-Speicher

| Plattform | MEK-Speicherort |
|-----------|----------------|
| iOS | Keychain (first_unlock_this_device) |
| Android | Encrypted SharedPreferences |
| macOS | Keychain |
| Windows | Flutter Secure Storage (DPAPI) |
| Linux | libsecret |
| Web | PBKDF2-Fallback (kein sicherer Keystore) |

### Sicherheits-Features

| Feature | iOS | Android | Desktop | Web |
|---------|:---:|:-------:|:-------:|:---:|
| Biometrie | Ja | Ja | Teilweise | Nein |
| Root/Jailbreak-Erkennung | Ja | Ja | Nein | Nein |
| Screenshot-Schutz | Ja (Blur) | Ja (FLAG_SECURE) | Nein | Nein |
| USB-Debug-Erkennung | Nein | Ja | Nein | Nein |
| Certificate Pinning | Ja | Ja | Ja | Nein (Browser) |

### Navigation

| Bildschirmbreite | Navigationstyp |
|------------------|---------------|
| 0-450px (Mobile) | Bottom Navigation Bar (4 Tabs + "Mehr") |
| 451-800px (Tablet) | Navigation Drawer |
| 801px+ (Desktop) | Navigation Rail (links) |

### Fenster-Verwaltung (Desktop)

- **Mindestgroesse**: 800x600 Pixel
- **Vollbild-Toggle**: Button in der Navigation
- **Window Manager**: `window_manager` Paket fuer Desktop-spezifische Funktionen
- **Orientierung**: Tablets erlauben Landscape, Phones nur Portrait

## Build-Konfiguration

### SDK-Anforderungen

```yaml
environment:
  sdk: ^3.9.2
```

### Build-Befehle

```bash
# Dependencies installieren
flutter pub get

# Code-Generierung (JSON-Serialisierung)
flutter pub run build_runner build --delete-conflicting-outputs

# Windows Build
flutter build windows

# macOS Build (nur auf Mac)
flutter build macos

# Android APK
flutter build apk

# iOS (nur auf Mac mit Xcode)
flutter build ios

# Web
flutter build web
```
