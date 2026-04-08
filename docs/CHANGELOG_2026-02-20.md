# Changelog - 20.02.2026

## UI-Fixes und Feature-Erweiterungen

---

### 1. Text zentriert (Hilfe-Screen & Neuer Termin)

**Dateien:** `lib/screens/hilfe_screen.dart`, `lib/screens/create_appointment_screen.dart`

- Hilfe-Screen: Aeussere Column von `CrossAxisAlignment.start` auf `CrossAxisAlignment.center` geaendert, damit Inhalte zentriert dargestellt werden
- Hilfe-Screen: Willkommens-Ueberschrift in `Expanded` gewrappt, um Text-Overflow auf kleinen Bildschirmen zu verhindern
- Neuer Termin (Empty State): `textAlign: TextAlign.center` zum Text "Noch keine Klienten vorhanden" hinzugefuegt

---

### 2. Intervall "Woechentlich" hinzugefuegt

**Dateien:** `lib/models/client.dart`, `lib/screens/create_client_screen.dart`

- Enum `FachleistungsIntervall` um `woechentlich` erweitert (mit `@JsonValue('woechentlich')`)
- Steht in logischer Reihenfolge vor `monatlich` und `jaehrlich`
- Intervall-Dropdown im Klienten-Formular zeigt nun drei Optionen: Woechentlich, Monatlich, Jaehrlich
- `client.g.dart` neu generiert

---

### 3. Klienten-ID Feld

**Dateien:** `lib/models/client.dart`, `lib/screens/create_client_screen.dart`

- Neues optionales Feld `String? klientenId` im Client-Model (vom Benutzer vergebene ID, nicht die interne UUID)
- In Konstruktor, `Client.create()` Factory und `copyWith()` eingebaut
- JSON-Serialisierung ueber build_runner generiert
- Neues TextFormField "Klienten-ID" in der Grunddaten-Sektion des Klienten-Formulars (zwischen Vollstaendiger Name und Vorname)
- Platzhalter-Text: "z.B. KL-001"
- Klienten-ID wird zusaetzlich als read-only Info in der Fachleistungsstunden-Sektion angezeigt (sofern vergeben)
- Wird beim Erstellen und Bearbeiten eines Klienten gespeichert

---

### 4. Taetigkeit einer Klienten-ID zuordnen

**Datei:** `lib/screens/work_time_screen.dart`

- `AddWorkTimeScreen`: Neues Dropdown "Klient zuordnen (optional)" in der Details-Card
  - Zeigt alle Klienten aus dem AppProvider
  - Anzeige: Klienten-ID + vollstaendiger Name (falls ID vergeben)
  - Erste Option: "Kein Klient" (Wert: null)
  - Speichert ausgewaehlten Klienten in `arbeitszeit.clientId`
- `EditWorkTimeScreen`: Gleiches Dropdown, initialisiert mit dem bestehenden `clientId` der Arbeitszeit
  - Ermoeglicht nachtraegliche Aenderung der Klienten-Zuordnung
- Beide Screens nutzen `Consumer<AppProvider>` fuer die aktuelle Klientenliste

---

### 5. FAB oeffnet Full-Page-Formular statt Dialog

**Datei:** `lib/screens/work_time_screen.dart`

- FAB im Arbeitszeit-Screen navigiert jetzt per `Navigator.push` zu `AddWorkTimeScreen` (Full-Page-Formular)
- Alter `showDialog()`-Code mit `AlertDialog` entfernt
- Nicht mehr benoetigte State-Variablen in `_WorkTimeScreenState` entfernt:
  - `_selectedDate`, `_startTime`, `_endTime`, `_description`, `_selectedTyp`, `_descriptionController`
- Konsistentes Verhalten: Alle Dateneingaben erfolgen nun ueber Full-Page-Formulare

---

## Betroffene Dateien

| Datei | Aenderung |
|---|---|
| `lib/models/client.dart` | Enum `woechentlich` + Feld `klientenId` |
| `lib/models/client.g.dart` | Neu generiert (build_runner) |
| `lib/screens/hilfe_screen.dart` | Text-Zentrierung + Overflow-Fix |
| `lib/screens/create_appointment_screen.dart` | Text-Zentrierung Empty State |
| `lib/screens/create_client_screen.dart` | Klienten-ID Feld + Intervall Dropdown |
| `lib/screens/work_time_screen.dart` | Klient-Zuordnung + FAB Full-Page |

## Verifizierung

- `flutter pub run build_runner build` erfolgreich
- `flutter analyze` ohne neue Fehler (nur vorbestehende Infos/Warnings)
