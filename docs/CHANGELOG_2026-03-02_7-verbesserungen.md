# Plan: 7 Verbesserungen fuer die EH-App (FEGH-Dokumentation) — 2026-03-02

## Kontext

Sieben UI/UX-Verbesserungen fuer die Eingliederungshilfe-App.

---

## 1. Drawer schliesst nicht automatisch (Tablet)
- `adaptive_navigation.dart`: `Navigator.pop(context)` vor Callback
- Titel "Eingliederungshilfe" → "FEGH-Dokumentation"

## 2. SGB-Paragraphen-Dropdown im Klientenstammblatt
- Neues Feld `rechtsgrundlage` in `client.dart` + build_runner
- Dropdown in `create_client_screen.dart` mit SGB IX/VIII/XII Paragraphen

## 3. Vollbild-Button (plattformuebergreifend)
- Fullscreen-Toggle via `SystemChrome` (Android/iOS) + `window_manager` (Desktop)
- Button im AppBar / NavigationRail

## 4. "Passwort vergessen" Button
- `auth_screen.dart`: TextButton unter Login-Button
- Reset-Dialog (lokal: kein Email-Reset moeglich)

## 5. DSGVO-konforme lokale Dokumentenablage
- Neuer `document_storage_service.dart`
- DSGVO-Hinweis vor PDF-Export, Auto-Loesch-Intervall

## 6. Dokumentationsuebersicht als Unter-Tab
- Unter-Tab in "Berichte" mit Volltext aller Dokumentationen
- Dashboard Quick-Action springt direkt zum Unter-Tab

## 7. Settings als aufklappbare Reiter
- `_buildSection()` → `ExpansionTile` statt statische Card
- Erste Section aufgeklappt, Rest eingeklappt
