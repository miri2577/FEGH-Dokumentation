# Letzte Meilensteine – Recht, Betrieb & Produkt (Produktionsreif)

Dieses Dokument ergänzt eure technische Architektur (HiDrive Business, E2E + App‑interne Verschlüsselung) um die letzten organisatorischen und produktnahen Bausteine. Damit habt ihr ein vollständiges Produktions‑Setup.

---

## 1) Recht & Policies
- **Datenschutzerklärung** (Website + App‑Store + In‑App):
  - Zweck, Kategorien, Rechtsgrundlagen (Art. 6/9 DSGVO)
  - Empfänger: STRATO HiDrive Business (Standort Deutschland)
  - Löschfristen (gesetzlich, z. B. 10 Jahre für Pflegeakten; projektbezogen kürzer möglich)
  - Rechte: Auskunft, Löschung, Berichtigung, Datenübertragbarkeit
  - Kontakt Datenschutzbeauftragter
- **Impressum**: Anbieterkennzeichnung, Verantwortliche
- **VVT**: STRATO als Auftragsverarbeiter eintragen
- **AVV**: im Kundenlogin bestätigt, PDF lokal ablegen
- **DSFA**: finalisiert, Versionierung im Git/Wiki

---

## 2) Schlüssel & Wiederherstellung
- **MEK‑Backup/Recovery**: Dokumentieren, wie ein verlorener Key ersetzt wird (Option: Nutzer‑Passphrase, Recovery‑Code im Safe)
- **MEK‑Rotation**: alle 12 Monate per „Rewrap“ (Utility vorhanden)
- **Crypto‑Erasure**: Löschung durch Key‑Revoke + Dateilöschung

---

## 3) Betrieb & Vorfälle
- **Incident‑Runbook** (Kurzform):
  1. Erkennen → Incident im Ticketsystem öffnen
  2. Innerhalb 24h: erste Einschätzung (Betroffenheit, Umfang)
  3. Innerhalb 72h: Meldung an Aufsichtsbehörde (Art. 33 DSGVO)
  4. Betroffene informieren (Art. 34 DSGVO)
  5. Nachbereitung (Root‑Cause, Lessons Learned)
- **Kontaktliste**: DSB, Ops‑Team, Geschäftsführung, STRATO Support
- **Monitoring/Alerting**:
  - Upload/Download‑Fehlerquote > 5 % → Alarm
  - Speicherverbrauch > 80 % → Alarm
  - Zertifikatsablauf < 30 Tage → Alarm

---

## 4) App‑Härtung
- **TLS‑Pinning** produktiv aktiv (≥ 2 Pins)
- **Root/JB‑Erkennung** → App schaltet auf Read‑Only, Hinweis an Nutzer
- **App‑Lock** optional aktivierbar (PIN/Biometrie)
- **FLAG_SECURE** (Android) + Blur bei iOS Backgrounding
- **Keine PHI** in Logs, Push, Dateinamen, HTTP‑Headern

---

## 5) HiDrive Business Konfiguration
- **E2E aktiviert** (Test: ohne Schlüssel kein Zugriff)
- **Benutzer/Rollen**: nur benötigte Accounts, 2FA für Admins
- **Retention**: automatische Versionierung (z. B. 90 Tage), Löschkonzept dokumentiert
- **Protokolle**: Zugriffe regelmäßig prüfen

---

## 6) Produktfunktionen (DSGVO‑Pflichten)
- **Export**: Menüpunkt „Meine Daten exportieren“ → JSON/ZIP mit allen Inhalten; AES‑verschlüsselt lokal, dann per Download/Share
- **Löschung**: Menüpunkt „Konto löschen“ → App entfernt Daten (lokal + HiDrive, inkl. Key‑Revoke)
- **Fehlermeldungen**: neutral (z. B. „Upload fehlgeschlagen“) ohne Details
- **App‑Store‑Compliance**: Privacy Labels (iOS) / Data Safety (Android) korrekt pflegen

---

## 7) Sichere Lieferung & Entwicklung
- **Dependency‑Pinning** (pubspec.lock im Repo)
- **Automatischer Security‑Scan** (Dependabot/Renovate + Trivy)
- **SBOM** erzeugen, Builds signieren (Cosign)
- **Code‑Reviews** verpflichtend für Security‑Code

---

## 8) Test & Qualität
- **Negative‑Tests**: abgelaufene Token → 401, fremde TenantID → 403
- **Load‑Tests**: 100–500 Dateien streamend hoch/runter
- **Key‑Loss‑Simulation**: MEK entfernt → Wiederherstellung nur mit Recovery‑Code
- **DR‑Test**: Neue Umgebung → Manifest + Dateien entschlüsseln, Validierung

---

## 9) Bausteine für Datenschutzerklärung (Beispiel)

> **Speicherung:** Ihre Daten werden ausschließlich verschlüsselt verarbeitet. Vor Speicherung in der App erfolgt eine Ende‑zu‑Ende‑Verschlüsselung (AES‑256‑GCM, zufälliger Schlüssel). Die Daten werden dann verschlüsselt im Cloud‑Speicher **STRATO HiDrive Business** abgelegt. Die Server befinden sich in Deutschland. STRATO ist unser Auftragsverarbeiter (Art. 28 DSGVO); eine entsprechende Vereinbarung zur Auftragsverarbeitung wurde abgeschlossen.

> **Löschung:** Sie können jederzeit die Löschung Ihrer Daten verlangen. In diesem Fall werden sowohl die Daten in der App als auch die verschlüsselten Daten im Cloud‑Speicher gelöscht. Zusätzlich werden die Schlüssel vernichtet (Crypto‑Erasure), sodass ein Zugriff unmöglich ist.

> **Export:** Auf Wunsch können Sie Ihre Daten maschinenlesbar (JSON/ZIP) exportieren.

---

## 10) Kurz‑Incident‑Runbook (für interne Ablage)

- **Alarm erkannt** (Monitoring oder Nutzerhinweis)
- **Triage**: Prüfen, welche Daten betroffen sind (Art, Umfang, Personen)
- **Meldung**: Innerhalb 72h an Behörde
- **Info**: Betroffene Personen sachlich informieren
- **Fix**: Schwachstelle schließen, Logs sichern
- **Review**: Lessons Learned, Prozess verbessern

---

Mit diesen Ergänzungen habt ihr nicht nur die technische Sicherheit, sondern auch die **rechtlich/organisatorischen Pflichtteile** (DSGVO, App‑Stores, Betrieb). Das Gesamtpaket ist damit **produktionsreif**.

