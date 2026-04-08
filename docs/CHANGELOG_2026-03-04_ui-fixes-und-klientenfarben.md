# UI-Fixes & Benutzerdefinierte Klientenfarben

**Datum:** 04.03.2026

## Änderungen

### 1. Dokumentation-Tab: Inhalte direkt sichtbar
- `ExpansionTile` durch direkt aufgeklappte Card-Darstellung ersetzt
- Notizen, Transkription, ICF-Bereiche und TIB-Ziele sind sofort lesbar
- Kein Aufklappen mehr nötig

### 2. Dropdown-Maße im Dokumentation-Tab
- Klienten-Dropdown hat jetzt gleiches Styling wie das Suchfeld
- `OutlineInputBorder`, `isDense`, Person-Icon als `prefixIcon`

### 3. Fix: Einrichtungsassistent startete bei jedem App-Start
- **Ursache:** `clearAllData()` setzte `setupCompleted = false` ohne persistent zu speichern
- **Fix:** `setupCompleted = true` wird beibehalten und nach Reset gespeichert

### 4. Kalender: Benutzerdefinierte Klientenfarben
- Neues `customColor`-Feld (Hex-String) im Client-Model
- Farblegende (Palette-Icon) interaktiv: Tippen auf Farbe öffnet ColorPicker mit 16 Presets
- Reset-Button setzt auf automatische Hash-basierte Farbe zurück
- `colorForClient()` prüft zuerst `customColor`, dann Fallback
- `AppointmentDataSource` leitet Klienten-Farben weiter

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/screens/dokumentation_uebersicht_screen.dart` | ExpansionTile → direkte Darstellung, Dropdown-Styling |
| `lib/providers/app_provider.dart` | clearAllData() behält setupCompleted=true |
| `lib/models/client.dart` | Neues Feld `customColor` |
| `lib/models/client.g.dart` | Automatisch generiert |
| `lib/widgets/appointment_data_source.dart` | colorForClient() mit customColor-Support |
| `lib/screens/calendar_screen.dart` | Interaktive Farblegende + ColorPicker |
