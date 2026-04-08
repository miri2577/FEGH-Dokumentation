# Admin‑Konsole – Funktionen, Health & Repair

Stand: 2025‑09‑28

## Überblick

Die Admin‑Konsole bündelt administrative Aufgaben und Einblicke:

- Übersicht: Kennzahlen (Mitarbeiter, Teams, Klienten)
- Health: Konfigurationszustand (Org‑ID, Cloud‑Sync), Hinweise zur Ordnerstruktur
- Audit: Letzte Audit‑Einträge (300 Zeilen), Filter/Export (folgt), Quelle: `audit.log`
- Tools: Rebuilder für `clients-index.bin`, QR‑Payload für Team‑Key

Zugriff ist rollenbasiert: `org_admin`, `pv_admin` (voll), `org_auditor` (lesen).

## Nutzung

- Einstellungen → Button „Admin‑Konsole“ (rollenbasiert sichtbar)
- Tab „Tools“ → `Clients‑Index neu aufbauen` scannt `teams/*/clients/*.bin` und schreibt `administration/clients-index.bin`
- Tab „Audit“ → zeigt die letzten 300 Einträge (JSON‑Zeilen). Einträge entstehen u. a. bei `client.add/update/delete`, Index‑Rebuild

## Health‑Checks

- Org‑ID gesetzt
- Cloud‑Sync aktiviert
- Hinweise: team‑scoped Ablage `teams/<team>/clients`, Index unter `administration/clients-index.bin`

## Repair/Integrity (aktuell)

- Index‑Rebuilder: setzt den Index aus dem Ist‑Zustand neu
- Geplant: „Drift“‑Analyse (Index ↔ Dateien), selektive Reparatur, verwaiste Einträge löschen

## Audit‑Log

- Ort: lokales App‑Support‑Verzeichnis `audit.log`
- Format: eine JSON‑Zeile je Eintrag, Felder: `ts`, `action`, `ctx`
- Geplant: Filter (Text, Zeitraum) und Export (JSON/CSV)

## Sicherheit

- Aktionen sind per Policy (RBAC) geschützt
- Schreibende Tools (Index‑Rebuild) nur für Admin‑Rollen

