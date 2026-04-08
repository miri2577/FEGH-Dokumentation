# Changelog 2026-02-25: Performance-Optimierung

## Zusammenfassung

Die App startet jetzt deutlich schneller und reagiert fluessiger. Orientiert an der Architektur der personalverwaltung-App wurden drei zentrale Performance-Engpaesse beseitigt.

## Aenderungen

### 1. IndexedStack durch Lazy Screen Cache ersetzt

**Datei:** `lib/screens/home_screen.dart`

**Problem:** `IndexedStack` hat alle 10 Screens (Dashboard, Klienten, Termine, Arbeitszeiten, Kalender, Nachrichten, Berichte, Export, Hilfe, Einstellungen) bei jedem `build()` gleichzeitig erstellt und im Widget-Tree gehalten. Das bedeutete O(n) Speicherverbrauch und unnoetige Initialisierungsarbeit fuer nicht sichtbare Screens.

**Loesung:** Ein `Map<int, Widget> _screenCache` erstellt Screens erst beim ersten Tab-Wechsel und cached sie fuer spaetere Aufrufe. Nur der aktive Screen befindet sich im Widget-Tree.

- Nicht besuchte Tabs werden erst beim ersten Klick geladen
- Tab-Wechsel bleibt instantan (Screen bleibt im Cache)
- Speicherverbrauch sinkt erheblich, da nur besuchte Screens im Speicher liegen

### 2. Zweistufige Initialisierung (schnellerer App-Start)

**Datei:** `lib/providers/app_provider.dart`

**Problem:** `initialize()` hat sequentiell auf Storage, Auth, Speech, alle Daten und Messages gewartet. Die UI zeigte nur einen Ladebildschirm bis ALLES fertig war.

**Loesung:** Initialisierung in zwei Stufen aufgeteilt:

- **Stufe 1 (blockiert UI kurz):** SecureStorageService, Authentifizierung und Settings laden. Danach wird `isLoading = false` gesetzt und die UI sofort angezeigt.
- **Stufe 2 (non-blocking, im Hintergrund):** Klienten, Termine, Arbeitszeiten, Mitarbeiter, Freizeit-Antraege, E-Mail-Ziele und Benutzerprofil laden parallel via `Future.wait()`. Speech-Initialisierung und MessageService laufen fire-and-forget.

Neues Flag `isDataLoading` zeigt an, ob die Hintergrund-Daten noch laden.

### 3. Dezenter Ladeindikator im Dashboard

**Datei:** `lib/screens/home_screen.dart`

Waehrend die Daten im Hintergrund laden (Stufe 2), zeigt das Dashboard einen `LinearProgressIndicator` am oberen Rand. Dieser verschwindet automatisch sobald alle Daten geladen sind. Die Dashboard-Karten zeigen in der Zwischenzeit "0" fuer noch nicht geladene Werte.

## Betroffene Dateien

| Datei | Aenderung |
|-------|-----------|
| `lib/screens/home_screen.dart` | IndexedStack entfernt, Lazy Screen Cache, Ladeindikator |
| `lib/providers/app_provider.dart` | Zweistufige Init, `isDataLoading` Flag, `_loadAllDataDeferred()`, `_initMessageServiceIfReady()` |

## Nicht geaendert

- Kein Riverpod-Migration (zu grosser Refactor)
- Kein AppProvider-Split (wenig Gewinn vs. obige Massnahmen)
- Keine Aenderung an Daten-Persistierung (JSON-Parsing ist nicht der Bottleneck)
