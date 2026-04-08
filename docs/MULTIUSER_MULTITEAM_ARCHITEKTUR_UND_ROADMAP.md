# Multi‑User/Multi‑Team Architektur – Umsetzung, Nutzung und Roadmap

Stand: 2025‑09‑28

## Zielbild (Enterprise‑tauglich)

- Mandantenfähig: Organisation → Teams → Mitarbeitergeräte
- Datenfluss über STRATO HiDrive Business (WebDAV), strikt verschlüsselt (AES‑256‑GCM, DEK/MEK, Team‑Key)
- Team‑Scoped Datenablage:
  - `.../organizations/<org>/teams/<teamId>/clients/<uuid>.bin`
  - Admin‑Indizes: `.../organizations/<org>/administration/clients-index.bin`
- Provisionierung per Team‑Key (QR) und optionaler Sync‑Passphrase
- Perspektive: RBAC (Rollen/Policies) für Aktionen und Bereiche

## Was ist umgesetzt (Stand dieses Commits)

1) Team‑Zuordnung bei Klienten
- `Client.teamId` hinzugefügt
- UI: Auswahl „Team‑Zuordnung“ im Klientenformular
- Dateien: `personalverwaltung/lib/models/client.dart`, `.../client_form_dialog.dart`

2) Team‑Scoped Sync von Klienten (PV → Cloud)
- Service `OrgClientSyncService` schreibt/aktualisiert verschlüsselte Klienten unter `teams/<teamId>/clients/` und pflegt `administration/clients-index.bin`
- Provider‑Integration: Beim Add/Update/Delete eines Klienten wird bei aktivem Cloud‑Sync automatisch synchronisiert
- Dateien: `personalverwaltung/lib/services/org_client_sync_service.dart`, `.../providers/client_provider.dart`

3) QR‑Dialog Stabilität + Logging
- PNG‑Fallback + klare Logs (`[QR]`, `[TEAMKEY]`, `[WebDAV]`) + HTTP‑Timeouts
- Dateien: `.../features/settings/settings_screen.dart`, `.../services/team_key_admin_service.dart`, `.../services/hidrive_webdav_client.dart`

## Wie nutze ich das (End‑to‑End)

1) Personalverwaltung (PV)
- Einstellungen: HiDrive Zugang + Org‑ID setzen, Cloud‑Sync aktivieren
- Teams anlegen
- Klienten anlegen → „Team‑Zuordnung“ wählen → Speichern

2) Mobile App (Mitarbeitergerät)
- Einstellungen: HiDrive Zugang + gleiche Org‑ID + eigene Team‑ID
- Team‑Key per QR scannen
- „Jetzt synchronisieren“

3) Erwartetes Ergebnis
- In HiDrive erscheinen `clients/<uuid>.bin` unter dem Team
- Der `clients-index.bin` listet `{uuid, teamId, name, updatedAt}`
- Das Mitarbeitergerät (Team‑Modus) findet die Klienten und lädt sie

## Professionalisiertes Ziel – Nächste Umsetzungen

A) RBAC‑Basis (Rollen/Policies)
- Policy‑Service + Guards für Aktionen (z. B. darf Klient bearbeiten, Team wechseln, Rewrap ausführen)
- Rollen: Org‑Admin, Auditor; Team‑Lead, Betreuer; PV‑Admin (erweiterbar)

B) Konsistenz‑Tool – Clients‑Index Rebuilder
- Admin‑Aktion in PV, die alle Team‑Ordner `teams/*/clients/` scannt, Namen entschlüsselt und `clients-index.bin` aus dem Ist‑Zustand neu aufbaut

C) „Team wechseln“ für Klienten (Migration)
- Datei in neuen Team‑Ordner laden (Inhalt mit neuer `teamId` verschlüsseln), alte löschen, Index aktualisieren

D) Stabilität/Sicherheit (laufend)
- Idempotente Uploads, Retry/Backoff, aussagekräftige Fehlermeldungen
- Regelmäßige Key‑Rotation, Audit‑Trails für kritische Aktionen

## Sicherheitshinweise

- Team‑Key ist zwingend, um Team‑Dateien zu lesen (Mobile) bzw. zu erzeugen (optional in PV)
- Sync‑Passphrase niemals in die Cloud schreiben; nur lokal halten
- Timeouts gegen hängende Requests aktiviert

## Tests & Betrieb

- Logs live ansehen (PV): `flutter run -d macos --dart-define=DEVELOPER_MODE=true | rg '\\[QR\\]|\\[TEAMKEY\\]|\\[WebDAV\\]'`
- HiDrive‑Struktur prüfen (WebDAV): Vorhandensein von `clients/*.bin` und `clients-index.bin`
- Mobile: Nach Provisionierung Sync auslösen; im Log `downloadTeamRecord('clients', ...)` sehen

## Roadmap (Phase 2)

- Vollständiges RBAC inkl. UI‑Konfiguration je Rolle
- Admin‑Viewport (org‑weit, read‑only je Rolle)
- Employee‑Keys (Feingranular, optional)
- Automatisierte Integritätsprüfungen + Repair‑Tasks

