# Fahrwege-Erfassung, OSM-Routing, Kostentraeger-Ueberarbeitung & UI-Verbesserungen

**Datum:** 02.03.2026
**Version:** v0.1.0-alpha.3

---

## 1. Fahrwege-Erfassung mit Strecken-Cache

Neues Feature zur km-Dokumentation fuer Fahrtkostenerstattung.

### Neue Dateien

| Datei | Beschreibung |
|-------|-------------|
| `lib/models/standort.dart` | Standort-Model mit StandortTyp (buero, klient, amt, sonstige), optionale Koordinaten (lat/lng) |
| `lib/models/fahrweg.dart` | Fahrweg-Model (Einzelfahrt mit denormalisierten Standort-Namen) |
| `lib/models/strecken_cache.dart` | StreckenCache-Model (bidirektionale gelernte Distanzen) |
| `lib/services/distance_service.dart` | Distanzberechnung mit Nominatim + OSRM (OpenStreetMap) |
| `lib/screens/standorte_screen.dart` | Standorte-Verwaltung mit Adress-Suche und PLZ-Vorschlaegen |
| `lib/widgets/fahrweg_input_widget.dart` | Wiederverwendbares Fahrweg-Eingabe-Widget mit Auto-Berechnung |

### Geaenderte Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/models/appointment.dart` | + `fahrwegHinId`, `fahrwegRueckId` (optionale Felder) |
| `lib/models/app_settings.dart` | + `bueroStandortId`, `openRouteServiceApiKey` |
| `lib/services/secure_storage_service.dart` | CRUD fuer 3 neue Schemas: standort, fahrweg, streckencache |
| `lib/providers/app_provider.dart` | State, CRUD, Statistik-Getter (kmDrivenToday/Week/Month, kmPerClient) |
| `lib/screens/create_appointment_screen.dart` | Optionale Fahrweg-Section (ExpansionTile) |
| `lib/screens/work_time_screen.dart` | Fahrwege-Statistik + Eingabe bei Typ=Fahrt |
| `lib/screens/home_screen.dart` | Dashboard-Cards "Fahrwege (Monat)" + "Fahrten" |
| `lib/screens/settings_screen.dart` | Neue Section "Standorte & Fahrwege" |
| `lib/screens/export_screen.dart` | Neuer Export "Fahrwege Export" (CSV-kompatibel) |

### DSGVO-Konformitaet

- Keine GPS-Ortung, kein Location-Service
- Standorte nur als Labels gespeichert
- Adressen nur transient im Such-Dialog, nie persistiert
- Nur km-Wert + Label im Cache gespeichert
- Alle Daten AES-256-GCM verschluesselt

---

## 2. Umstellung auf OpenStreetMap (OSRM + Nominatim)

Die Distanzberechnung wurde von OpenRouteService auf den reinen OSM-Stack umgestellt, da ORS fehlerhafte km-Werte lieferte (z.B. 40 km statt 10 km).

### Neuer Stack

| Dienst | Zweck | URL |
|--------|-------|-----|
| **OSRM** | Routing (Fahrdistanz Auto) | router.project-osrm.org |
| **Nominatim** | Geocoding (Adress-Suche) | nominatim.openstreetmap.org |

### Vorteile

- **Kein API-Key mehr noetig** - Adress-Suche und Routing funktionieren sofort
- **Korrekte km-Werte** - OSRM liefert die gleichen Ergebnisse wie gaengige OSM-Routenplaner
- **Kostenlos** - Beide Dienste sind frei nutzbar (mit User-Agent Header)

### Aenderungen in `distance_service.dart`

- `searchAddresses()`: Nutzt Nominatim statt ORS Geocode
  - Gibt strukturierte Ergebnisse mit PLZ, Strasse, Hausnummer, Ort zurueck
  - `countrycodes=de` fuer Deutschland-Filter
  - `addressdetails=1` fuer aufgeschluesselte Adress-Felder
- `getRouteDistance()`: Nutzt OSRM statt ORS Directions
  - URL-Format: `/route/v1/driving/lng1,lat1;lng2,lat2?overview=false`
  - Response: `routes[0].distance` in Metern
- `calculateDistanceFromCoords()`: Direkte Koordinaten-Berechnung ohne Geocoding
- API-Key ist optional (Altlast aus ORS-Zeit, wird nicht mehr benoetigt)

---

## 3. Standort-Erfassung mit Adress-Suche

### Standort-Model erweitert

- Neue optionale Felder: `latitude`, `longitude`
- Neuer Getter: `hasCoordinates`
- Wenn Koordinaten vorhanden: Distanzen werden automatisch per OSRM berechnet

### Standort-Dialog mit Adress-Suche

- Adresse eingeben (mind. 3 Zeichen) → Vorschlaege nach 500ms Debounce
- Jeder Vorschlag zeigt:
  - **Zeile 1 (fett):** Strasse + Hausnummer
  - **Zeile 2 (grau):** PLZ + Ort (zur Bezirk-Unterscheidung)
- Auswahl setzt Koordinaten und befuellt den Namen automatisch
- Gruener Status-Chip "Koordinaten hinterlegt" mit Loesch-Option

### Fahrweg-Berechnung

- **Mit Koordinaten:** Automatische Distanzberechnung beim Standort-Wechsel (kein Dialog noetig)
- **Ohne Koordinaten:** Berechnungs-Dialog mit Adress-Suche fuer Start und Ziel
  - Beide Adress-Felder haben eigene Vorschlagslisten mit PLZ
  - "Berechnen" erst aktiv wenn beide Adressen aus der Liste gewaehlt wurden
  - Keine blinde Geocodierung mehr → korrekte Standort-Zuordnung
- **Immer moeglich:** Manuelle km-Eingabe als Fallback

---

## 4. Kostentraeger voll ausgeschrieben

Alle Abkuerzungen im Kostentraeger-Dropdown wurden durch vollstaendige Namen ersetzt.

### Vorher → Nachher

| Vorher | Nachher |
|--------|---------|
| JA Charl.-Wilm. | Jugendamt Charlottenburg-Wilmersdorf |
| SA Friedr.-Kreuz. | Sozialamt Friedrichshain-Kreuzberg |
| AA Berlin Mitte | Agentur fuer Arbeit Berlin Mitte |
| DRV Bund | Deutsche Rentenversicherung Bund |
| DRV Berlin-Brand. | Deutsche Rentenversicherung Berlin-Brandenburg |
| Private KV | Private Krankenversicherung |
| HEK | HEK - Hanseatische Krankenkasse |
| IKK Brandenburg Berlin | IKK Brandenburg und Berlin |
| Berufsgenossensch. | Berufsgenossenschaft |
| LAGeSo - Eingl.hilfe | LAGeSo - Eingliederungshilfe |

### Dropdown mit Gruppenheadern

Gleiche Formatierung wie Rechtsgrundlagen-Dropdown:
- Nicht-auswaehlbare Gruppen-Header (fett, grau, klein)
- 5 Gruppen: Jugendaemter, Sozialaemter/Teilhabefachdienste, Krankenkassen, Arbeitsagentur/Rentenversicherung, Sonstige
- `isExpanded: true` und `TextOverflow.ellipsis`

---

## 5. Hilfebereich komplett ueberarbeitet

11 Sektionen, passend zum aktuellen App-Stand:

1. **Willkommen** - Aktualisierte App-Beschreibung
2. **Schnellstart** - 5 Schritte inkl. Standorte einrichten
3. **Navigation** - Alle Tabs + Einstellungen
4. **Termin-Dokumentation** - Neu: Fahrweg beim Termin
5. **Klienten-Verwaltung** - Aktualisiert: Rechtsgrundlage, Kostentraeger, Informationsbericht
6. **Arbeitszeit-Erfassung** - Aktualisiert: Fahrwege-Integration
7. **Fahrwege & Standorte** - Neu: Komplette Anleitung inkl. API-Key-Setup (optional)
8. **Export & Berichte** - Neu: Fahrwege-Export fuer Fahrtkostenerstattung
9. **Einstellungen** - Neu: Alle Settings-Bereiche erklaert
10. **Sicherheit & Datenschutz** - Aktualisiert: DSGVO, optionale Cloud-Sync
11. **Problembehandlung** - Aktualisiert: Fahrwege-spezifische Probleme

---

## 6. UI-Fix: Setup-Wizard Textueberlauf

`_buildSummaryRow()` in `setup_wizard_screen.dart`:
- Problem: Auf schmalen Mobilgeraeten liefen Label und Wert ineinander
- Loesung: `Flexible` Widget mit `SizedBox(width: 16)` Gap statt `Row` mit `spaceBetween`

---

## Build-Status

- `flutter build macos` -- Erfolgreich (63.6MB)
- Ad-hoc Codesigning + Start erfolgreich
