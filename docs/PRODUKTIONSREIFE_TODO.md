# Produktionsreife -- TODO-Liste

Stand: 09.04.2026

## KRITISCH -- Blockiert Produktionseinsatz

- [ ] **1. Passwort-Hashing unsicher** (web_auth_service.dart:242)
  - Problem: Einfacher SHA256 mit hardcoded Salt `eingliederungshilfe_salt`
  - Loesung: bcrypt mit mindestens 12 Runden oder PBKDF2 mit 100.000+ Iterationen
  - Aufwand: Klein

- [ ] **2. Developer-Mode immer aktiv im Debug** (developer_mode.dart:12)
  - Problem: `allowDebugModeActivation` Default ist `true`, dadurch im Debug-Modus Keychain deaktiviert, Biometrie uebersprungen, Debug-Logs aktiv
  - Loesung: Default auf `false` setzen oder explizites Flag erzwingen
  - Aufwand: Klein

- [ ] **3. Unsicherer MEK-Fallback** (crypto_storage.dart:147-164)
  - Problem: Master Encryption Key als Klartext Base64 in Datei `.dev_mek_UNSECURE` gespeichert
  - Loesung: Methode `_developmentFallback()` komplett entfernen
  - Aufwand: Klein

- [ ] **4. Cloud-Sync ohne Fehlerbehandlung** (secure_storage_service.dart:342, 416, etc.)
  - Problem: Lokaler Delete vor Cloud-Delete, kein Await, kein Retry. Daten koennen divergieren
  - Loesung: Cloud-Ops awaiten, Retry mit Backoff, User bei Fehler benachrichtigen
  - Aufwand: Mittel

- [ ] **5. Debug-Prints mit sensiblen Daten** (diverse Services)
  - Problem: `print()` Aufrufe in auth, crypto, storage Services loggen sensible Infos
  - Loesung: Alle `print()` durch `AppLogger` ersetzen, in Release keine Security-Logs
  - Aufwand: Mittel

- [ ] **6. Session-Timeout nicht erzwungen** (web_auth_service.dart:266-283)
  - Problem: `checkSessionValid()` existiert aber wird nirgends aufgerufen
  - Loesung: In main.dart oder AppProvider regelmaessig pruefen
  - Aufwand: Klein

- [ ] **7. HiDrive-Credentials im Klartext** (app_settings.dart)
  - Problem: Username und Passwort in SharedPreferences (nicht im Keychain)
  - Loesung: Credentials in FlutterSecureStorage verschieben
  - Aufwand: Mittel

- [ ] **8. Test-Dateien im Produktionscode**
  - Problem: hidrive_test.dart (3606 Zeilen), hidrive_test2.dart (4095 Zeilen), simple_webdav_test.dart
  - Loesung: In test/ verschieben oder loeschen
  - Aufwand: Klein

## HOCH -- Muss vor Echtbetrieb gefixt werden

- [ ] **9. Keine Unit-Tests fuer Crypto/Auth/Permissions** (test/)
  - Problem: Nur 3 Test-Dateien (PDF-Tests + Smoke-Test), keine Security-Tests
  - Loesung: Tests fuer CryptoStorage, TotpService, PermissionService, RecoveryService
  - Aufwand: Gross

- [ ] **10. Leere Catch-Bloecke** (diverse Dateien)
  - Problem: `catch (_) {}` verschluckt Fehler komplett
  - Dateien: team_key_qr_scan_screen.dart:102, secure_storage_service.dart:49,68,118,137,144
  - Loesung: Mindestens loggen, besser User benachrichtigen
  - Aufwand: Mittel

- [ ] **11. Recovery-Screen nicht fertig** (recovery_screen.dart:244,254)
  - Problem: Token-Validierung OK, aber Password-Reset nicht in WebAuthService integriert
  - Loesung: WebAuthService.resetPassword() implementieren und aufrufen
  - Aufwand: Mittel

- [ ] **12. Kein Audit-Logging** (fehlt komplett)
  - Problem: DSGVO verlangt Nachweis wer wann auf welche Daten zugegriffen hat
  - Loesung: AuditLogger Service mit persistentem Log (JSON-Lines)
  - Aufwand: Mittel

- [ ] **13. Race Conditions bei Cloud-Sync** (secure_storage_service.dart)
  - Problem: Manifest vor Cloud-Op aktualisiert, keine Transaktions-Semantik
  - Loesung: Optimistic Locking oder Queue-basierter Sync
  - Aufwand: Mittel

- [ ] **14. Decryption ohne Error-Handling** (crypto_storage.dart:258)
  - Problem: `decryptRecord()` faengt keine Exceptions, App crasht bei korrupten Daten
  - Loesung: Try-Catch mit Fallback (Datensatz als korrupt markieren)
  - Aufwand: Klein

## MITTEL -- Sollte gefixt werden

- [ ] **15. Web-Version speichert Daten unverschluesselt**
  - Problem: localStorage im Browser ist nicht wirklich verschluesselt
  - Loesung: Warnung anzeigen oder Web-Version nur fuer Demo
  - Aufwand: Klein

- [ ] **16. Cross-Platform Backup nicht kompatibel**
  - Problem: MEK nutzt Hardware-ID, Backup von Windows kann nicht auf macOS entschluesselt werden
  - Loesung: Sync-Passphrase fuer plattformuebergreifende Backups erzwingen
  - Aufwand: Mittel

- [ ] **17. Android MANAGE_EXTERNAL_STORAGE veraltet**
  - Problem: Zu breite Berechtigung, wird von Google Play abgelehnt
  - Loesung: Scoped Storage mit MediaStore nutzen
  - Aufwand: Mittel

- [ ] **18. Mehrere Crypto-Libraries**
  - Problem: cryptography + crypto + encrypt -- erhoehte Angriffsflaeche
  - Loesung: Auf eine Library standardisieren
  - Aufwand: Gross

- [ ] **19. Keine sichere Loeschung**
  - Problem: `cryptoErasure()` loescht Dateien, ueberschreibt aber nicht
  - Loesung: Datei vor Loeschung mit Zufallsdaten ueberschreiben
  - Aufwand: Klein

## PASSWORT-AENDERUNGEN VOR PRODUKTIONSEINSATZ

- [ ] Matrix-Admin-Passwort aendern (aktuell: TestAdmin123)
- [ ] Nextcloud-Admin-Passwort aendern (aktuell: NextcloudAdmin123)
- [ ] TURN-Secret aendern (aktuell: fegh-turn-secret-2026)
- [ ] Server SSH-Key rotieren

## GESCHAETZTER AUFWAND

| Kategorie | Punkte | Aufwand |
|-----------|--------|---------|
| Kritisch (1-8) | 8 | ~2-3 Tage |
| Hoch (9-14) | 6 | ~3-5 Tage |
| Mittel (15-19) | 5 | ~3-4 Tage |
| **Gesamt** | **19** | **~8-12 Tage** |
