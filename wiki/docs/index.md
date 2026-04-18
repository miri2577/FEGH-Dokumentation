# FEGH-Dokumentation

**Digitale Eingliederungshilfe-Dokumentation** -- die App fuer Fachkraefte in der Eingliederungshilfe.

Version: **1.0.0-beta.1** | [GitHub Repository](https://github.com/miri2577/FEGH-Dokumentation)

!!! tip "Schwester-App fuer Buero-Arbeit"
    Fuer groessere Traeger gibt es die Desktop-Admin-App
    **[FEGH-Verwaltung](https://miri2577.github.io/FEGH-Verwaltung/)**
    als Ergaenzung. Sie uebernimmt Mitarbeiter-Stammdaten, Dienst-
    planung und zentrale Reports. Beide Apps teilen Daten ueber
    HiDrive/Nextcloud und die geteilten Shared-Packages
    `fegh_crypto` und `fegh_cloud`.

---

## Was ist FEGH-Dokumentation?

FEGH-Dokumentation ist eine plattformuebergreifende App zur digitalen Dokumentation in der Eingliederungshilfe. Sie unterstuetzt Fachkraefte bei der taeglichen Arbeit mit Klienten, Terminen, Berichten und Arbeitszeiterfassung.

Die App laeuft auf **Windows, macOS, Linux, iOS, Android und im Browser**.

## Kernfunktionen

| Funktion | Beschreibung |
|----------|-------------|
| **Klientenverwaltung** | Stammdaten, Kostenuebernahme, Fachleistungsstunden, TIB-Ziele |
| **Terminplanung** | Kalender mit Wochen-/Monatsansicht, farbkodierte Klienten |
| **Arbeitszeiterfassung** | Taetigkeitsbasiert mit automatischer Berechnung |
| **Berichte** | Berliner Informationsbericht (137 Felder), PDF-Export |
| **Verschluesselter Chat** | Matrix-basiert, E2E (Megolm), eigener Server, Video-Calls |
| **Team-Arbeit** | Multi-Team-Struktur, Cloud-Sync (HiDrive, Nextcloud, eigener Server) |
| **Administration** | Teams erstellen, Mitarbeiter einladen, Rollen verwalten |
| **Sicherheit** | AES-256-GCM, TOTP 2FA, Audit-Logging, DSGVO-konform |

## Schnellstart

- **Einzelnutzer**: App installieren → Ersteinrichtung → Lokal arbeiten
- **Admin (Organisation)**: App installieren → "Organisation einrichten" → HiDrive konfigurieren → Teams anlegen → Mitarbeiter einladen
- **Mitarbeiter**: App installieren → "Einladungscode verwenden" → QR-Code + PIN eingeben → Fertig

Weiter zu den [Ersten Schritten](anleitung/erste-schritte.md).

## Plattformen

Die App unterstuetzt alle gaengigen Plattformen mit einer einzigen Codebasis:

- Windows (Desktop)
- macOS (Desktop, Code-Signiert)
- Linux (Desktop)
- iOS (iPhone/iPad)
- Android (Smartphone/Tablet)
- Web (Browser)

Die Oberflaeche passt sich automatisch an die Bildschirmgroesse an (Mobile, Tablet, Desktop, 4K).
