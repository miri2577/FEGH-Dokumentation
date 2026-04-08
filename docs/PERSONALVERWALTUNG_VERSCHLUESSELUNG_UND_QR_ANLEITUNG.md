# Personalverwaltung – Verschlüsselung und Team‑Key/QR‑Anleitung

Stand: 2025‑09‑28

## Überblick

Die Personalverwaltungs‑App speichert alle fachlichen Datensätze (Mitarbeiter, Klienten, Zeiten etc.) client‑seitig verschlüsselt und synchronisiert die Ciphertexte per WebDAV zu STRATO HiDrive Business. Das Sicherheitsmodell folgt einem Envelope‑Ansatz:

- Daten‑Schlüssel (DEK) pro Datensatz, Algorithmus: AES‑256‑GCM
- DEK wird mit einem Master‑Schlüssel (MEK) gewrappt
- MEK liegt lokal im Secure Storage; optional aus einer Sync‑Passphrase (PBKDF2‑ähnlich) abgeleitet
- Team‑Schlüssel (Team‑Key) für Team‑weite Freigaben; als 32‑Byte Key, verschlüsselt abgelegt und per QR für Mobil‑Provisionierung exportierbar

Relevante Implementierungsteile:
- `personalverwaltung/lib/services/crypto_storage.dart`: MEK/DEK, AES‑GCM, Ableitung aus Passphrase, Wrap/Unwrap
- `personalverwaltung/lib/services/hidrive_webdav_client.dart`: WebDAV‑Transport
- `personalverwaltung/lib/services/team_key_admin_service.dart`: Erzeugen/Laden von `team-key.bin` in HiDrive
- `personalverwaltung/lib/features/settings/settings_screen.dart`: UI‑Flows „Sync‑Passphrase setzen“, „Team‑Key erzeugen“, „Team‑Key als QR“, „Team‑Records rewrap“
- Ergänzende Architektur: `architektur_app_↔_strato_hi_drive_business_e_2_e_defense_in_depth.md`, `HIERARCHICAL_KEYS_STATUS.md`

## Schlüsselmodell

- MEK (Master Encryption Key)
  - 32‑Byte Key im Secure Storage
  - Optional: Ableitung aus Sync‑Passphrase (100k HMAC‑SHA256‑Runden, vgl. `CryptoStorage._deriveMekFromPassphrase`)
  - Operationen: `initialize()`, `rotateMEK()`, `deleteMEK()`

- DEK (Data Encryption Key)
  - Zufällig pro Datensatz
  - Verwendet zur Datenverschlüsselung (AES‑256‑GCM) inkl. AAD‑Kontext
  - Gewrappt (AES‑GCM) mit MEK gespeichert

- Team‑Key (K_team)
  - 32‑Byte Key für ein Team (ID: frei vergebbar)
  - Ablage verschlüsselt in HiDrive unter `administration/teams/<teamId>/team-key.bin`
  - Inhalt: JSON mit Base64‑Key + Zeitstempel, verschlüsselt via `CryptoStorage.encryptJson`
  - Export: als QR für Mobile‑App‑Provisionierung

## Verschlüsselungsablauf (vereinfacht)

1) App erstellt DEK, verschlüsselt Nutzlast mit AES‑256‑GCM (+AAD)
2) DEK wird mit MEK des Geräts (oder „forciertem“ MEK, z. B. Team‑Key) via AES‑GCM gewrappt
3) Beides (Ciphertext + WrappedDEK) wird als JSON gespeichert/übertragen
4) Entschlüsselung umgekehrt: unwrap(DEK, MEK) → decrypt(DEK)

Siehe `CryptoStorage.encryptJson/decryptJson`.

## HiDrive‑Ablage (Ausschnitt)

```
/users/<user>/eingliederungshilfe/organizations/<org>/
└── administration/
    ├── clients-index.bin
    ├── employees-index.bin
    └── teams/
        └── <teamId>/
            └── team-key.bin   # verschlüsselt (AES‑GCM, via CryptoStorage)
```

## Bedienungsanleitung (Settings → Cloud‑Synchronisation)

1) HiDrive Zugang setzen
   - Felder „HiDrive Benutzername/Passwort“ ausfüllen
   - „Anmeldedaten speichern“, dann „Verbindung testen“

2) Organisation/Träger setzen
   - Feld „Organisation/Träger ID“ ausfüllen (z. B. `meine-organisation`)

3) Sync‑Passphrase setzen (empfohlen)
   - Button „Sync‑Passphrase setzen“ → Passphrase (≥ 12 Zeichen) zweimal eingeben
   - Dadurch wird ein MEK festgelegt/rotiert, aus der Passphrase abgeleitet

4) Team‑Key erzeugen
   - Button „Team‑Key erzeugen“ → Team‑ID eingeben → „Erzeugen“
   - Ergebnis: `team-key.bin` unter `administration/teams/<teamId>/` in HiDrive

5) Team‑Key als QR exportieren
   - Button „Team‑Key als QR“ → Team‑ID eingeben → „QR anzeigen“
   - Es erscheint ein QR‑Code (JSON‑Payload: `{ type: 'egh-team-key', org, team, key, ts }`)
   - Mit der Mobil‑App scannen, um den Team‑Key zu provisionieren

6) Team‑Records rewrap (optional)
   - Button „Team‑Records rewrap“ → Team‑ID eingeben → Starten
   - Rewrapt Team‑Dateien auf den Team‑Key (K_team)

## Fehlerbehebung: QR wird nicht angezeigt

- Team‑ID leer: Im Dialog muss eine Team‑ID eingegeben werden.
- Kein Team‑Key vorhanden: Der QR‑Dialog versucht zuerst zu laden, legt andernfalls per „ensureTeamKey“ an. Prüfe HiDrive‑Zugang/Org‑ID.
- Passphrase/MEK: Wurde der Team‑Key mit einem alten MEK erzeugt und später die Passphrase/MEK rotiert, kann das Laden fehlschlagen. Erzeuge den Team‑Key danach erneut.
- Cloud‑Sync Status: In der Settings‑Karte muss „Cloud‑Synchronisation ist bereit“ angezeigt werden.
- Abhängigkeit: `qr_flutter` ist in `pubspec.yaml` vorhanden (Widget `QrImageView`). Bei Build‑Fehlern einmal `flutter pub get` und neu starten.
- Netzwerk/HiDrive: WebDAV muss erreichbar sein. „Verbindung testen“ sollte grün sein.

## Sicherheitshinweise

- Passphrase niemals in der Cloud speichern; nur lokal (Keychain/Keystore)
- Team‑Keys liegen stets verschlüsselt (`team-key.bin`)
- Crypto‑Erasure: `deleteMEK()` zerstört den Zugang; ohne MEK keine Entschlüsselung
- Regelmäßige Rotation des MEK und Rewrap der Bestände einplanen

## Referenzen (Quellcode)

- `personalverwaltung/lib/services/crypto_storage.dart` – MEK/DEK, AES‑GCM, Passphrase‑Ableitung
- `personalverwaltung/lib/services/team_key_admin_service.dart` – Erzeugen/Laden von Team‑Keys
- `personalverwaltung/lib/features/settings/settings_screen.dart` – UI‑Flows inkl. QR‑Anzeige (`QrImageView`)
- `HIERARCHICAL_KEYS_STATUS.md` – Hierarchisches Schlüsselmodell (Org/Team)
- `architektur_app_↔_strato_hi_drive_business_e_2_e_defense_in_depth.md` – Architektur & Datenfluss

