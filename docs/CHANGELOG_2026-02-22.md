# Changelog 22.02.2026 — Export-Logik vereinheitlicht

## Zusammenfassung

Zentrale `ExportService.saveAndShare()` Methode eingeführt, die den Save/Share-Flow für alle Exporte (außer DSGVO) vereinheitlicht.

| Vorher | Nachher |
|--------|---------|
| 4 verschiedene Save-Mechanismen | 1 zentrale `saveAndShare()` Methode |
| Plattform-Code in 3 Screens dupliziert | Plattform-Logik nur in ExportService |
| Informationsbericht: kein FilePicker | Überall FilePicker auf Desktop |
| Appointments: FileSaver, keine Ortswahl | Konsistenter Save-Flow mit FilePicker |
| Unterschiedliche SnackBar-Styles | Einheitlich: grün/rot, 3s, "Ordner öffnen" |

---

## Geänderte Dateien

### 1. `lib/services/export_service.dart`

- **Neue Methode `saveAndShare()`** — zentraler Speicher-/Teilen-Flow:
  - **Desktop:** FilePicker → User wählt Speicherort → optional Datei öffnen → grüner SnackBar mit "Ordner öffnen"
  - **Mobile:** Temp-Datei → Share-Dialog
  - **Web:** Blob-Download
  - **Fehler:** Roter SnackBar, 3 Sekunden
- **Neue Hilfsmethoden** `_openFile(path)` und `_openFolder(filePath)` mit plattformspezifischen Befehlen (`open`/`cmd start`/`xdg-open`)
- **`exportData()` refactored:** Interne Save-Logik durch Aufruf von `saveAndShare()` ersetzt → Export Screen und Clients Screen bekommen das neue Verhalten automatisch
- **Imports:** `file_saver` entfernt, `path_provider` + `share_plus` hinzugefügt

### 2. `lib/screens/informationsbericht_screen.dart`

- **~50 Zeilen** plattformspezifischer Save/Open/Share-Code durch 1 `ExportService.saveAndShare()` Aufruf ersetzt
- `openAfterSave: true` beibehalten, damit die PDF nach dem Speichern automatisch geöffnet wird
- **Imports bereinigt:** `dart:io`, `path_provider`, `share_plus` entfernt; `export_service` hinzugefügt
- Der BottomSheet-Dialog für die 3 PDF-Varianten bleibt unverändert

### 3. `lib/screens/appointments_screen.dart`

- `FileSaver`-Logik durch `ExportService.saveAndShare()` ersetzt
- User bekommt jetzt auch hier FilePicker auf Desktop (vorher nur automatisches Speichern)
- **Imports bereinigt:** `file_saver`, `platform_utils` entfernt; `export_service` hinzugefügt

### 4. `lib/screens/export_screen.dart` (Cleanup)

- Unbenutzte Imports entfernt: `dart:typed_data`, `file_saver`, `universal_html`, `platform_utils`

---

## Nicht geändert

- **`lib/screens/clients_screen.dart`** — nutzt `ExportService.exportData()`, bekommt neues Verhalten automatisch
- **`lib/screens/settings_screen.dart`** — DSGVO-Export bleibt bewusst separat (Verschlüsselung, rechtliche Anforderungen)
- **`lib/models/export_format.dart`** — keine Änderungen nötig

---

## Neue API

```dart
static Future<bool> saveAndShare({
  required BuildContext context,
  required Uint8List bytes,
  required String filename,    // z.B. "bericht.pdf"
  required String mimeType,    // z.B. "application/pdf"
  bool openAfterSave = false,  // Datei nach Speichern öffnen (Desktop)
})
```

---

## Verifizierung

- `flutter build macos --release` erfolgreich (62 MB)
- Export Screen: nutzt `exportData()` → automatisch neuer Flow
- Informationsbericht: PDF → FilePicker → Speichern + Öffnen → SnackBar
- Appointments: Bericht → FilePicker → Speichern → SnackBar
- Clients: FLS-Export → gleicher Flow wie Export Screen
- Settings DSGVO: unverändert
