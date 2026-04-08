# Kalkulatorische Leistungseinheiten (Indirekte Zeit auf Klienten verteilen)

**Datum:** 03.03.2026

## Kontext

Bei der Berliner Eingliederungshilfe können seit der Umstellung auf Fachleistungsstunden (FLS) indirekte Tätigkeiten (Büro, Supervision, Teamsitzung etc.) nicht mehr als generische Arbeitszeit abgerechnet werden — sie müssen konkreten Klienten zugeordnet werden. Bisher unterstützte die App nur 1:1-Zuordnung (ein Termin = ein Klient). Jetzt kann ein indirekter Termin auf mehrere Klienten verteilt werden.

## Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/models/appointment.dart` | TerminArt-Enum, ClientAllocation-Klasse, 2 neue Felder |
| `lib/models/appointment.g.dart` | Automatisch generiert via build_runner |
| `lib/providers/app_provider.dart` | Stunden-Verteilung in add/update/delete + Filter erweitert |
| `lib/screens/create_appointment_screen.dart` | TerminArt-Auswahl + Multi-Klient-Verteilungs-UI |
| `lib/screens/appointments_screen.dart` | Anzeige & Filter für indirekte Termine |
| `lib/screens/export_screen.dart` | FLS-Aggregation pro Klient angepasst |

## Neue Datenstrukturen

### TerminArt Enum

```dart
enum TerminArt {
  kliententermin,   // Direkter Klientenkontakt (bestehend)
  buero,            // Büroarbeit/Verwaltung
  dokumentation,    // Dokumentation/Fallbearbeitung
  supervision,      // Supervision
  teamsitzung,      // Teamsitzung/Teambesprechung
  fortbildung,      // Fortbildung
  fahrtzeit,        // Fahrtzeit
  sonstige,         // Sonstige indirekte Tätigkeit
}
```

Jeder Wert hat `displayName`, `isIndirect` (bool) und `icon` (String).

### ClientAllocation Klasse

```dart
class ClientAllocation {
  final String clientId;
  final String clientName;
  final int minuten;
  double get stunden => minuten / 60.0;
}
```

### Neue Felder in Appointment

```dart
final TerminArt? terminArt;                     // null = kliententermin (rückwärtskompatibel)
final List<ClientAllocation>? clientAllocations; // null für direkte Termine
```

Convenience-Getter:
- `effectiveTerminArt` — null-safe (null → kliententermin)
- `isIndirect` — true wenn nicht kliententermin

## Provider-Logik

### addAppointment()
- **Direkt**: Stundenverbrauch wie bisher auf einen Klienten
- **Indirekt**: Für jede ClientAllocation separat `updateStundenverbrauch()` aufrufen
- Automatische Arbeitszeit-Erstellung mit korrektem `ArbeitszeitTyp`

### updateAppointment()
- Alte Stunden zurückrechnen (pro Klient oder gesamt)
- Neue Stunden zurechnen (pro Klient oder gesamt)

### deleteAppointment()
- Termin lesen vor Löschung
- Stunden-Reversal: direkt oder per Allocation

### getAppointmentsForClient()
- Auch indirekte Termine zurückgeben, die eine Allocation für den Klienten haben

### Neue Helper
- `getAllocatedHoursForClient(appointment, clientId)` — zugewiesene Stunden
- `_mapTerminArtToArbeitszeitTyp(terminArt)` — Mapping auf ArbeitszeitTyp

## UI: Termin-Erstellung

### TerminArt-Auswahl
- ChoiceChip-Leiste oben im Formular (vor Klientenauswahl)
- Bei Wechsel zwischen direkt/indirekt wird die Klientenauswahl umgeschaltet

### Bedingte Klientenauswahl
- **Direkt (kliententermin)**: Bestehender Single-Client-Dropdown — unverändert
- **Indirekt**: Multi-Klient-Checkboxen mit Minutenverteilung

### Multi-Klient-Verteilungs-Widget
1. Klienten per Checkbox auswählen
2. Pro Klient: Minuteneingabe (TextFormField)
3. "Gleichmäßig verteilen"-Button
4. Zusammenfassungsleiste: Termindauer / Verteilt / Rest
5. Validierung: Summe muss = Termindauer sein

### Bedingte Formular-Abschnitte
Bei indirekten Terminen ausgeblendet:
- ICF-Bereiche
- TIB-Bereiche / Individuelle TIB-Ziele
- Familienhilfe-Kategorien

## UI: Terminliste (appointments_screen)

- Filter: Auch indirekte Termine mit Allocation für ausgewählten Klienten
- Anzeige: Indirekte Termine mit TerminArt-Name, oranger Avatar, Klientenanzahl

## Export (export_screen)

- FLS-Report: Indirekte Termine werden über clientAllocations auf Klienten aufgeschlüsselt
- Zusammenfassung: Stunden pro Klient korrekt aggregiert (direkt + indirekt)

## Rückwärtskompatibilität

- Bestehende Termine ohne `terminArt` werden als `kliententermin` behandelt (null → kliententermin)
- Kein Migration-Schritt nötig
- Alle bestehenden Flows bleiben unverändert
