# Produktionsreife Checkliste – App mit HiDrive Business

Diese Liste fasst alle wichtigen Schritte zusammen. Einfach abhaken → produktionsreif.

---

## 1) Recht & Dokumentation
- [ ] Datenschutzerklärung erstellt (inkl. STRATO HiDrive Business, E2E, Standort DE)
- [ ] Impressum gepflegt
- [ ] Verzeichnis der Verarbeitungstätigkeiten (VVT) aktualisiert
- [ ] AVV mit STRATO abgeschlossen & PDF abgelegt
- [ ] DSFA finalisiert und dokumentiert

---

## 2) Schlüssel & Verschlüsselung
- [ ] MEK in Secure Storage gespeichert
- [ ] Recovery-/Backup-Plan für MEK erstellt
- [ ] MEK-Rotation alle 12 Monate eingeplant (Utility vorhanden)
- [ ] Crypto-Erasure definiert (Key-Revoke + File-Delete)

---

## 3) Betrieb & Vorfälle
- [ ] Incident-Runbook dokumentiert & zugänglich
- [ ] Kontaktliste gepflegt (DSB, Ops, STRATO)
- [ ] Monitoring-Schwellen definiert (Fehlerquote, Speicher, Zertifikate)
- [ ] DR-Test einmal durchgeführt

---

## 4) App-Härtung
- [ ] TLS-Pinning aktiv (≥ 2 Pins)
- [ ] Root/JB-Erkennung integriert
- [ ] App-Lock (PIN/Biometrie) eingebaut
- [ ] FLAG_SECURE/Blur aktiviert
- [ ] Logs/Push/Dateinamen ohne PHI

---

## 5) HiDrive Business Konfiguration
- [ ] E2E aktiviert & getestet
- [ ] Benutzer & Rechte minimal gehalten (least privilege)
- [ ] 2FA für Admins aktiv
- [ ] Retention/Versionierung gesetzt (z. B. 90 Tage)
- [ ] Zugriffsprotokolle regelmäßig geprüft

---

## 6) Produktfunktionen
- [ ] Menüpunkt „Daten exportieren“ implementiert
- [ ] Menüpunkt „Konto löschen“ (inkl. Key-Revoke) implementiert
- [ ] Fehlermeldungen neutral gestaltet
- [ ] App-Store Privacy Labels/Data Safety korrekt eingereicht

---

## 7) Entwicklung & Lieferung
- [ ] pubspec.lock gepflegt (Dependency-Pinning)
- [ ] Security-Scans in CI/CD aktiv (Dependabot/Trivy)
- [ ] SBOM erzeugt
- [ ] Signierte Builds (Cosign/App-Store Signatur)
- [ ] Code-Reviews etabliert

---

## 8) Test & Qualität
- [ ] Negative Tests (Token abgelaufen, falsche TenantID)
- [ ] Load-Test (100–500 Dateien streamend)
- [ ] Key-Loss-Simulation (Recovery-Plan)
- [ ] DR-Test erfolgreich

---

✅ Wenn alle Punkte abgehakt sind, ist die App technisch, rechtlich und organisatorisch **produktionsreif**.

