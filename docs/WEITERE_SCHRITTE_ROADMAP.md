# Weitere Schritte – Roadmap und Empfehlungen

Stand: 2025‑09‑28

## Kurzfristig (1–2 Sprints)

- RBAC finalisieren
  - Policy‑Checks in allen Flows: Export/Reports, Archive/Restore, Admin‑Tools
  - Audit‑Trail für sensible Aktionen: Team‑Key erzeugen/QR, Rewrap, Passphrase, Index‑Rebuild, Export
- Health & Repair erweitern
  - Schreibrechte‑Tests auch in Team‑Pfaden (`teams/<team>/clients`)
  - Drift‑Analyse: verwaiste Team‑Ordner, fehlerhafte Dateinamen/Endungen
  - „Dry‑Run“ + Repair‑Plan vor Ausführung
- Sync‑Robustheit
  - Idempotente Uploads, Retry/Backoff im WebDAV‑Wrapper
  - UI‑Syncstatus: letzter Erfolg/Fehler, Dauer, nächster Sync
- QR‑Provisionierung
  - PV: Multi‑Select Teams (statt CSV), Payload‑Preview
  - Mobile: Hinweis „Provisioniert via QR am <Datum>“ in Settings
- Logging/Telemetrie
  - Strukturierte JSON‑Logs, Log‑Level, optional zentrale Auswertung

## Mittelfristig

- Admin‑Viewport
  - Audit‑Filter (Mehrfachauswahl, Zeitraum/Uhrzeit), Export (JSON/CSV), Pagination
  - Org‑weite Übersichten (Teams/Klienten/Index‑Drift/Sync‑Status) mit Navigation
- Schlüssel‑Management
  - Geplante Team‑Key Rotation (Kalender/Erinnerungen) + Mass‑Rewrap
  - Backup/Recovery‑Flows dokumentiert & getestet (Crypto‑Erasure, Wiederherstellung)
- Mobile‑Qualität
  - Settings: klare Anzeige von Rolle/Teams/Policy‑Quelle
  - Policy‑Konflikte (Team nicht erlaubt) → geführter Dialog/Auto‑Korrektur
- HiDrive‑Abstraktion
  - Zentrale Storage‑Abstraktion (Policy‑Layer, Pfad‑Helper) für konsistente Pfade

## Langfristig

- Directory/SSO (OIDC/SAML) für echte Multi‑User‑Verwaltung (optional)
- Employee‑Keys (K_emp) für feingranulare Datenhoheit, inkl. Rewrap‑Tools
- Compliance & QA
  - Automatisierte Tests (Crypto, Sync, Policies, Index‑Rebuild)
  - Readiness‑Checkliste (DSGVO, Incident‑Handling, Backup/Restore Drill)

## Konkrete, „ready‑to‑implement“ Tickets

1) PV‑QR Dialog
   - Multi‑Select Teams (aus Teams‑Provider) + Payload‑Preview
2) Admin‑Konsole – Audit
   - Mehrfachauswahl Aktionstypen + Zeitraum mit Uhrzeit, Export über FileSaver
3) Health
   - Schreibrechte in Team‑Pfaden + verwaiste Ordner erkennen
4) Export/Audit
   - ExportDialog mit erweitertem Audit (Zeitraum, Datentyp), Guards im History‑Export

