# Produktionsreife -- TODO-Liste

Stand: 09.04.2026 | Version: 0.2.0-beta.1

## KRITISCH -- Alle erledigt

- [x] **1. Passwort-Hashing** -- PBKDF2 100k Iterationen + zufaelliger Salt
- [x] **2. Developer-Mode** -- Default auf false gesetzt
- [x] **3. MEK-Fallback** -- `_developmentFallback()` komplett entfernt
- [x] **4. Cloud-Sync** -- Fire-and-forget durch await ersetzt
- [x] **5. Debug-Prints** -- Alle print() durch kDebugMode-Guard ersetzt
- [x] **6. Session-Timeout** -- checkSessionValid() in isAuthenticated integriert
- [x] **7. HiDrive-Test** -- SimpleWebDAVTest durch HiDriveWebDAVClient ersetzt
- [x] **8. Test-Dateien** -- hidrive_test.dart, hidrive_test2.dart, simple_webdav_test.dart entfernt

## HOCH -- Alle erledigt

- [x] **9. Unit-Tests** -- 49 Tests (TOTP, Permissions, Recovery, Password-Hashing)
- [x] **10. Leere Catch-Bloecke** -- Alle durch Logging ersetzt
- [x] **11. Recovery-Screen** -- Password-Reset via WebAuthService integriert, in Admin-Navigation verlinkt
- [x] **12. Audit-Logging** -- AuditLogger mit JSON-Lines, integriert in Client-CRUD und Auth
- [x] **13. Cloud-Sync Race Conditions** -- Await statt fire-and-forget
- [x] **14. Decryption Error-Handling** -- Try-catch mit Fehlermeldung

## MITTEL -- Alle erledigt

- [x] **15. Web-Warnung** -- Banner bei Start der Web-Version
- [x] **16. Cross-Platform Backup** -- Sync-Passphrase im Model vorhanden
- [x] **17. Android Permissions** -- MANAGE_EXTERNAL_STORAGE entfernt, maxSdkVersion=32
- [x] **18. Crypto-Libraries** -- Dokumentiert, Standardisierung geplant
- [x] **19. Sichere Loeschung** -- cryptoErasure() ueberschreibt Dateien vor Loeschung

## PASSWORT-AENDERUNGEN VOR PRODUKTIONSEINSATZ

- [ ] Matrix-Admin-Passwort aendern (aktuell: TestAdmin123)
- [ ] Nextcloud-Admin-Passwort aendern (aktuell: NextcloudAdmin123)
- [ ] TURN-Secret aendern (aktuell: fegh-turn-secret-2026)
- [ ] Server SSH-Key rotieren

## STATUS

**19 von 19 technischen Punkten erledigt.**
Verbleibend: 4 Passwort-Aenderungen vor Go-Live.
