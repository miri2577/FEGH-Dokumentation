# Fahrwege-Erfassung mit Strecken-Cache und Online-Distanzberechnung

**Datum:** 02.03.2026
**Feature:** Kilometer-Tracking fuer Fahrtkostenerstattung
**DSGVO-Status:** Konform (keine GPS-Ortung, keine Adressen gespeichert)

---

## Uebersicht

Mitarbeiter der Eingliederungshilfe fahren taeglich zu Klienten. Das neue Fahrwege-Feature ermoeglicht:
- Erfassung von Fahrten mit Start/Ziel-Standorten und km-Angabe
- Einmalige Distanzberechnung per OpenRouteService API (Ergebnis wird gecacht)
- km-Statistik pro Tag/Woche/Monat/Klient
- CSV-Export fuer Fahrtkostenerstattung beim Arbeitgeber
- Integration in Termin-Dokumentation und Arbeitszeit-Erfassung

---

## Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `lib/models/standort.dart` | Standort-Model mit StandortTyp Enum (buero, klient, amt, sonstige) |
| `lib/models/standort.g.dart` | Generierte JSON-Serialisierung |
| `lib/models/fahrweg.dart` | Fahrweg-Model (Einzelfahrt mit denormalisierten Standort-Namen) |
| `lib/models/fahrweg.g.dart` | Generierte JSON-Serialisierung |
| `lib/models/strecken_cache.dart` | StreckenCache-Model (bidirektionale gelernte Distanzen) |
| `lib/models/strecken_cache.g.dart` | Generierte JSON-Serialisierung |
| `lib/services/distance_service.dart` | OpenRouteService API-Integration (Geocoding + Routing) |
| `lib/screens/standorte_screen.dart` | Standorte-Verwaltung Screen (CRUD, Typ-Zuweisung, Klient-Verknuepfung) |
| `lib/widgets/fahrweg_input_widget.dart` | Wiederverwendbares Fahrweg-Eingabe-Widget |

## Geaenderte Dateien

| Datei | Aenderung |
|-------|----------|
| `lib/models/appointment.dart` | Neue optionale Felder: `fahrwegHinId`, `fahrwegRueckId` |
| `lib/models/appointment.g.dart` | Regeneriert |
| `lib/models/app_settings.dart` | Neues optionales Feld: `bueroStandortId` |
| `lib/models/app_settings.g.dart` | Regeneriert |
| `lib/services/secure_storage_service.dart` | CRUD-Methoden fuer 3 neue Schemas: `standort`, `fahrweg`, `streckencache` mit UUID-Index Maps |
| `lib/providers/app_provider.dart` | State-Felder, CRUD-Methoden, Statistik-Getter (kmDrivenToday/Week/Month, kmPerClient, etc.) |
| `lib/screens/create_appointment_screen.dart` | Optionale Fahrweg-Section (ExpansionTile) mit FahrwegInputWidget |
| `lib/screens/work_time_screen.dart` | Fahrwege-Statistik-Section + Fahrweg-Eingabe bei ArbeitszeitTyp.fahrt |
| `lib/screens/home_screen.dart` | Dashboard-Card "Fahrwege (Monat)" + "Fahrten" (bedingt sichtbar) |
| `lib/screens/settings_screen.dart` | Neue Section "Standorte & Fahrwege" + Buero-Standort-Auswahl |
| `lib/screens/export_screen.dart` | Neue Export-Option "Fahrwege Export" mit CSV-kompatibler Ausgabe |

---

## Datenmodelle

### Standort
```
id: String (Timestamp)
name: String            -- z.B. "Buero", "Klient Mueller", "Amt Neukoelln"
typ: StandortTyp        -- buero | klient | amt | sonstige
clientId: String?       -- Optionale Verknuepfung mit Klient
createdAt: DateTime
```

### StreckenCache
```
id: String
startStandortId: String
zielStandortId: String
distanzKm: double
nutzungsAnzahl: int     -- Zaehler fuer Sortierung haeufiger Strecken
zuletztGenutzt: DateTime
createdAt: DateTime
```
Bidirektional: `matchesRoute()` prueft beide Richtungen.

### Fahrweg
```
id: String
datum: DateTime
startStandortId: String
startStandortName: String   -- Denormalisiert fuer schnelle Anzeige
zielStandortId: String
zielStandortName: String
distanzKm: double
appointmentId: String?      -- Optionale Verknuepfung mit Termin
clientId: String?
notizen: String?
createdAt: DateTime
```

---

## Architektur

```
Standort (Label)  ──┐
                     ├──> StreckenCache (Start→Ziel = X km)  ──> Fahrweg (Einzelfahrt)
Standort (Label)  ──┘         ↑ einmalig per API berechnet         ↓
                                                              Statistik + Export
```

### Distanzberechnung (DistanceService)
- API: OpenRouteService (kostenlos, 2000 Req/Tag)
- Geocoding: `GET /geocode/search?text=...&boundary.country=DE`
- Routing: `GET /v2/directions/driving-car?start=...&end=...`
- Adressen werden **transient** im Dialog eingegeben, **nie** gespeichert
- Ergebnis (km) wird im StreckenCache persistiert
- Alternative: Manuelle km-Eingabe immer moeglich

### Storage
- Verschluesselt mit AES-256-GCM (CryptoStorage)
- 3 neue Schemas: `standort`, `fahrweg`, `streckencache`
- UUID-Index Maps fuer O(1) Lookups
- Non-blocking Cloud-Sync (HiDrive)

### Provider
- State: `_standorte`, `_fahrwege`, `_streckenCache`
- Laden in `_loadAllDataDeferred()` (Stage 2, non-blocking)
- Statistik-Getter: `kmDrivenToday`, `kmDrivenThisWeek`, `kmDrivenThisMonth`, `totalKmDriven`, `kmPerClient`

---

## UI-Integration

### Settings > Standorte & Fahrwege
- Standard-Buero waehlen
- Standorte verwalten (Link zum StandorteScreen)
- StreckenCache-Statistik

### StandorteScreen
- Liste aller Standorte mit Icon je nach Typ
- Hinzufuegen/Bearbeiten/Loeschen via Dialog
- Als Standard-Buero setzen (Kontextmenue)

### FahrwegInputWidget (wiederverwendbar)
- Start-Dropdown (vorbelegt mit Buero-Standort)
- Ziel-Dropdown (auto-gesetzt bei verknuepftem Klient)
- Distanz aus Cache auto-befuellt, editierbar
- "Berechnen" Button oeffnet Distanzberechnungs-Dialog
- "Rueckfahrt gleich" Checkbox
- "+" Button fuer neue Standorte inline

### CreateAppointmentScreen
- Neue ExpansionTile "Fahrweg dokumentieren" (eingeklappt)
- Beim Speichern: Fahrweg-Records erstellen, mit Appointment verknuepfen

### WorkTimeScreen (AddWorkTimeScreen)
- Bei Typ=Fahrt: FahrwegInputWidget eingeblendet
- Fahrwege-Statistik-Section mit 4 DashboardCards + haeufigste Strecken

### HomeScreen
- Dashboard-Card "Fahrwege (Monat)" + "Fahrten" (bedingt sichtbar wenn Fahrwege vorhanden)

### ExportScreen
- Neue Export-Kachel "Fahrwege Export"
- CSV-kompatibles Format: Datum;Start;Ziel;km;Klient;Notizen
- Monats-Zusammenfassung mit Gesamt-km und km pro Standort

---

## DSGVO-Konformitaet

| Aspekt | Umsetzung |
|--------|-----------|
| Keine GPS-Ueberwachung | Kein `geolocator`, kein Location-Service, keine Echtzeit-Ortung |
| Keine Adressen gespeichert | Standorte nur als Labels ("Buero", "Klient Mueller") |
| Transiente Adresseingabe | Adressen nur im Berechnungs-Dialog, mit DSGVO-Hinweis, nicht persistiert |
| Lokale Speicherung | AES-256-GCM verschluesselt wie alle anderen Daten |
| Datensparsamkeit | Nur km-Wert + Label gespeichert, keine Routen-Details |
| Mitarbeiter-Kontrolle | Alle Daten vom Mitarbeiter selbst eingegeben |

---

## API-Key Konfiguration

Der `DistanceService` benoetigt einen OpenRouteService API-Key:
1. Kostenlos registrieren auf https://openrouteservice.org
2. API-Key generieren (2000 Requests/Tag frei)
3. Key via `DistanceService(apiKey: 'xxx')` oder `setApiKey('xxx')` setzen
4. **Alternative:** Distanzen koennen immer manuell eingegeben werden (kein API-Key noetig)

---

## Backward Compatibility

- Bestehende Appointments ohne `fahrwegHinId`/`fahrwegRueckId` laden weiterhin korrekt (nullable Felder)
- Bestehende AppSettings ohne `bueroStandortId` laden weiterhin korrekt (nullable Feld)
- Fahrwege-UI ist vollstaendig optional (ExpansionTile, bedingte Anzeige)
- Dashboard-Cards erscheinen nur wenn Fahrwege vorhanden sind

## Build-Status

`flutter build macos` -- Erfolgreich (63.5MB)
