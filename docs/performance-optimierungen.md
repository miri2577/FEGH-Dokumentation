# Performance-Optimierungen

## Aktuelle Probleme

### 1. notifyListeners() Overuse
- `AppProvider` ruft bei jeder Aenderung `notifyListeners()` auf
- Das rebuildet **alle** Consumer im Widget-Tree, nicht nur betroffene Widgets
- Besonders spuerbar bei haeufigen Updates (Kalender-Drag, Resize)

### 2. Synchrones Speichern bei Drag-Events
- Kalender-Resize ruft bei jedem Schritt `updateAppointment()` auf
- Jeder Aufruf: Serialisierung → AES-256 Verschluesselung → Datei schreiben → Liste neu laden → UI-Rebuild
- Ergebnis: Mehrere Sekunden Verzoegerung bei einfachen Aenderungen

### 3. Kein Debouncing
- Drag/Resize-Events feuern bei jeder Pixelaenderung
- Jedes Event loest den kompletten Speicher-Zyklus aus

---

## Loesungsvorschlaege

### A. Granularere Provider / Selectors
```dart
// Statt:
Consumer<AppProvider>(builder: (ctx, provider, _) => ...)

// Besser:
Selector<AppProvider, List<Appointment>>(
  selector: (_, p) => p.appointments,
  builder: (ctx, appointments, _) => ...
)
```
- Nur betroffene Widgets werden neu gebaut
- Reduziert unnoetige Rebuilds drastisch

### B. Debouncing beim Kalender
```dart
Timer? _debounce;

void onAppointmentResize(Appointment apt) {
  // UI sofort aktualisieren (lokal)
  setState(() => _localAppointment = apt);

  // Speichern erst nach 500ms Pause
  _debounce?.cancel();
  _debounce = Timer(const Duration(milliseconds: 500), () {
    appProvider.updateAppointment(apt);
  });
}
```

### C. Optimistisches UI-Update
```dart
Future<bool> updateAppointment(Appointment appointment) async {
  // 1. UI sofort aktualisieren
  final index = _appointments.indexWhere((a) => a.id == appointment.id);
  _appointments[index] = appointment;
  notifyListeners();

  // 2. Im Hintergrund speichern
  final success = await _storageService.updateAppointment(appointment);
  if (!success) {
    // Rollback bei Fehler
    await _loadAppointments();
    notifyListeners();
  }
  return success;
}
```

### D. Provider aufteilen
- `AppointmentProvider` - nur Termine
- `ClientProvider` - nur Klienten
- `SettingsProvider` - nur Einstellungen
- Aenderungen an Terminen loesen keine Rebuilds in Klienten-Widgets aus

---

## Prioritaet
1. **Debouncing** (schnellster Effekt, geringster Aufwand)
2. **Optimistisches UI-Update** (mittlerer Aufwand, grosser Effekt)
3. **Selectors** (mittlerer Aufwand, mittlerer Effekt)
4. **Provider aufteilen** (grosser Aufwand, langfristig beste Loesung)
