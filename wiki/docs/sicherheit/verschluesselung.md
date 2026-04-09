# Verschluesselung

## Uebersicht

Alle Daten in der FEGH-Dokumentation App werden mit **AES-256-GCM** verschluesselt gespeichert. Die Verschluesselung folgt dem **Envelope Encryption**-Muster mit Master Encryption Key (MEK) und Data Encryption Keys (DEK).

## Verschluesselungsschema

### Hierarchie

```
MEK (Master Encryption Key)
 └── DEK 1 (Data Encryption Key) → Datensatz 1
 └── DEK 2 → Datensatz 2
 └── DEK n → Datensatz n
```

### Ablauf beim Verschluesseln

1. Fuer jeden Datensatz wird ein zufaelliger **32-Byte DEK** generiert
2. Der Datensatz wird mit dem DEK verschluesselt (AES-256-GCM, 12-Byte Nonce)
3. Der DEK wird mit dem **MEK** verschluesselt (AES-256-GCM, eigener Nonce)
4. Beides wird zusammen als `EncryptedRecord` gespeichert

### Verschluesseltes Datensatz-Format

```json
{
  "v": 1,
  "alg": "AES-256-GCM",
  "nonce": "<Base64>",
  "aad": {},
  "ciphertext": "<Base64>",
  "tag": "<Base64>",
  "dekWrapped": {
    "alg": "AES-256-GCM",
    "nonce": "<Base64>",
    "ciphertext": "<Base64>",
    "tag": "<Base64>"
  }
}
```

## Master Encryption Key (MEK)

Der MEK wird auf verschiedene Arten bereitgestellt:

### 1. OS-Keychain (Primaer)

- **iOS**: Keychain mit `first_unlock_this_device` Accessibility
- **Android**: Encrypted SharedPreferences
- **macOS/Windows/Linux**: Flutter Secure Storage

### 2. PBKDF2-Fallback

Wenn der Keychain nicht verfuegbar ist:

- 100.000 Iterationen HMAC-SHA256
- Salt: Zufaellig generiert, lokal gespeichert
- Passwort: Hardware-Identifier + Plattform-Info (oder externe Sync-Passphrase)

### 3. Externer MEK (Team-Key)

Fuer Team-Arbeit kann ein externer MEK gesetzt werden:

- 32-Byte Team-Key aus dem Provisioning-Token
- Ueberschreibt den lokalen MEK fuer Team-Daten
- Ermoeglicht gemeinsamen Zugriff auf verschluesselte Daten

## Manifest

Ein verschluesseltes Manifest (`manifest.json`) indexiert alle gespeicherten Datensaetze:

- UUID-basierte Dateinamen (keine personenbezogenen Daten in Pfaden)
- Schema, Titel und Metadaten pro Eintrag
- Wird mit dem MEK verschluesselt

## Dateinamen

Alle Dateien auf HiDrive werden mit UUIDs benannt (z.B. `a1b2c3d4-e5f6-...bin`). Es sind keine personenbezogenen Daten in Dateinamen oder Ordnerstrukturen sichtbar.
