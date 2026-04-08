# Mobile App ↔ Personalverwaltung – Verbindung & Datenfluss

Stand: 2025‑09‑28

## Ziel

Diese Anleitung beschreibt, wie Android/iOS‑Geräte (Haupt‑App) über die Personalverwaltung angebunden werden, wie der Team‑Key per QR provisioniert wird und wie der bidirektionale Daten‑Sync über STRATO HiDrive Business funktioniert.

## Architektur in Kürze

- Cloud: STRATO HiDrive Business (WebDAV)
- Verschlüsselung: Client‑seitig (AES‑256‑GCM, DEK/MEK‑Envelope), identisch in beiden Apps
- Schlüssel:
  - MEK lokal im Secure Storage oder aus Sync‑Passphrase abgeleitet
  - Optional Team‑Key (32‑Byte) für Team‑spezifische Verschlüsselung; via QR von der Personalverwaltung zur Mobile‑App
- Ordnerstruktur (vereinfacht):

```
/users/<user>/eingliederungshilfe/organizations/<org>/
├── administration/
│   ├── employees-index.bin
│   ├── clients-index.bin
│   └── teams/<teamId>/team-key.bin
├── employees/<employeeId>/{profile,vacation}/...
├── teams/<teamId>/{clients,schedules,worktime}/...
└── shared/messages/...
```

## Voraussetzungen

- Personalverwaltung:
  - HiDrive Benutzername/Passwort konfiguriert
  - Organisation/Träger ID gesetzt
  - „Cloud‑Synchronisation ist bereit“ (Einstellungen)
- Mobile App (Android/iOS):
  - HiDrive Zugang gesetzt (Einstellungen → Cloud‑Synchronisation)
  - Organisation/Träger ID (und optional Team‑ID) eingetragen
  - Kamera‑Berechtigung für QR‑Scan (AndroidManifest/Info.plist sind vorbereitet)

## Ablauf – Geräte koppeln und versorgen

1) In der Personalverwaltung
- Einstellungen → Cloud‑Synchronisation
- Organisation/Träger ID setzen (z. B. `meine-organisation`).
- Optional je Team: Team‑Key erzeugen (Button „Team‑Key erzeugen“).
- Team‑Key als QR anzeigen (Button „Team‑Key als QR“, Team‑ID eingeben → „QR anzeigen“).
  - Falls Key nicht lesbar: „Neu erzeugen (überschreiben)“ nutzen, dann erscheint der QR.

2) In der Mobile App
- Einstellungen → Cloud‑Synchronisation
- HiDrive Zugang und Organisation/Träger ID setzen, optional Team‑ID.
- Team‑Key übernehmen:
  - „Team‑Key per QR scannen“ wählen und QR von der Personalverwaltung scannen.
  - Alternativ „Team‑Key importieren (Base64)“ und den Key manuell einfügen.
- Optional: „Sync‑Passphrase setzen“ (ableitet MEK lokal; bei aktivem Team‑Key hat dieser Vorrang, solange gesetzt).
- „Jetzt synchronisieren“ auslösen (lädt ggf. Team‑Key‑geschützte Daten und lädt lokale Daten hoch).

3) Datenfluss (bidirektional)
- Mobile App verschlüsselt Datensätze lokal (DEK/MEK) und lädt die Ciphertexte nach HiDrive in die passend gescopten Ordner (z. B. `teams/<teamId>/clients`).
- Personalverwaltung arbeitet mit der gleichen Organisation/Struktur, kann Daten auslesen/schreiben (z. B. Indizes unter `administration/`).
- Beide Seiten nutzen identisches Verschlüsselungsformat; Zugriff ist an MEK/Team‑Key gebunden.

## Provisionierung – Details

- QR‑Payload der Personalverwaltung (beispielhaft):

```
{
  "type": "egh-team-key",
  "org": "<org>",
  "team": "<teamId>",
  "key": "<base64-32byte>",
  "ts": "<ISO-8601>"
}
```

- Mobile App‑Verarbeitung:
  - `TeamKeyQrScanScreen` liest QR, prüft `type`, decodiert `key` (Base64→32 Byte) und setzt `cryptoStorage.setExternalMEK(key)`.
  - Nach dem Scan „Jetzt synchronisieren“, damit der neue Schlüssel für Cloud‑Zugriffe verwendet wird.

## Typische Workflows

- Teams bereitstellen:
  1. In der Personalverwaltung pro Team einen Team‑Key erzeugen und als QR bereitstellen.
  2. Mobile Geräte der Teammitglieder scannen den QR und erhalten Zugriff (nur verschlüsselte Inhalte; keine Klartext‑Metadaten in der Cloud).

- Geräte ersetzen / Key‑Rotation:
  - Passphrase gewechselt oder MEK rotiert? In der Personalverwaltung Team‑Key neu erzeugen (überschreiben) und QR neu verteilen.
  - Mobile Geräte erneut scannen.

## Troubleshooting

- QR bleibt leer in der Personalverwaltung:
  - Team‑ID eingeben, „QR anzeigen“. Bei Entschlüsselungsfehlern meldet der Dialog jetzt den Grund; „Neu erzeugen (überschreiben)“ löst einen frischen Key.
- Mobile App kann nicht synchronisieren:
  - HiDrive Zugang/Organisation/Team stimmen? „Verbindung testen“.
  - Team‑Key per QR erneut anwenden.
  - Zeitnah nach Passphrase‑/MEK‑Rotation erneut provisionieren.

## Verweise (Code in beiden Apps)

- Personalverwaltung:
  - `personalverwaltung/lib/services/crypto_storage.dart` – MEK/DEK/Envelope
  - `personalverwaltung/lib/services/team_key_admin_service.dart` – Team‑Key Erzeugen/Lesen
  - `personalverwaltung/lib/features/settings/settings_screen.dart` – QR‑Dialog, Rewrap
- Mobile App (Haupt‑App):
  - `lib/services/crypto_storage.dart` – MEK/DEK/Envelope, Passphrase, Manifest
  - `lib/services/secure_storage_service.dart` – Cloud‑Sync & Ordner‑Scoping
  - `lib/screens/team_key_qr_scan_screen.dart` – QR‑Scan und `setExternalMEK`
  - `lib/services/hidrive_webdav_client.dart` – WebDAV

Hinweis: Beide Apps müssen dieselbe Organisation/Träger ID benutzen und auf denselben HiDrive‑Account zugreifen, damit die Ordnerstrukturen übereinstimmen und Daten ausgetauscht werden können.

