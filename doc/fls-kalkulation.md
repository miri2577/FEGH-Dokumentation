# FLS-Kalkulation: Kalkulationsfaktor & Stundensatz

## Datum: 2026-02-22

## Umsetzung

Die App wurde um professionelle FLS-Kalkulationsbausteine erweitert:

### Neue globale Einstellungen (`AppSettings`)

| Feld | Typ | Default | Beschreibung |
|------|-----|---------|-------------|
| `kalkulationsfaktor` | `double` | 1.33 | KLE-Faktor: Verhältnis Gesamtarbeitszeit zu abrechnungsfähiger Zeit (Berlin-typisch: 1,25-1,33) |
| `stundensatz` | `double` | 40.0 | Vergütung pro Fachleistungsstunde in EUR (Berlin: 30-44 EUR je nach Qualifikation) |

Konfigurierbar unter: **Einstellungen > Fachleistungsstunden (Kalkulation)**

### Client-Model: Präzision & Override

- `verbrauchteStunden` von `int` auf `double` umgestellt (keine Rundungsverluste mehr bei z.B. 90-Min-Terminen = 1.5h)
- Neue optionale Override-Felder pro Klient:
  - `kalkulationsfaktorOverride` — überschreibt globalen Wert
  - `stundensatzOverride` — überschreibt globalen Wert
- `verfuegbareStunden` gibt jetzt `double` zurück

### Berechnungslogik (`AppProvider`)

Neue Hilfsmethoden:

```dart
getKalkulationsfaktor(Client c)    // c.override ?? settings.global
getStundensatz(Client c)           // c.override ?? settings.global
getGesamtarbeitsstunden(Client c)  // verbrauchteStunden * kalkulationsfaktor
getAbrechnungsbetrag(Client c)     // min(verbraucht, bewilligt) * stundensatz
```

`updateStundenverbrauch` arbeitet jetzt direkt mit `double` (`.round()` entfernt).

### UI-Änderungen

**Settings Screen:**
- Neue Section "Fachleistungsstunden (Kalkulation)" zwischen Datenverwaltung und DSGVO
- Kalkulationsfaktor und Stundensatz editierbar
- Info-Hinweis: "Pro Klient im Stammblatt überschreibbar"

**Klienten-Formular (create_client_screen):**
- Neue optionale Felder in der Fachleistung-Card:
  - Kalkulationsfaktor (leer = global)
  - Stundensatz EUR (leer = global)

**FLS-Anzeige/Export:**
- Gesamtarbeitszeit mit KLE-Faktor (z.B. "20,0h FLS -> 26,6h Gesamtarbeitszeit")
- Abrechnungsbetrag in EUR (z.B. "800,00 EUR")
- Kennzeichnung ob global oder klientenspezifisch

### Geänderte Dateien

| Datei | Änderung |
|-------|----------|
| `lib/models/app_settings.dart` | +kalkulationsfaktor, +stundensatz |
| `lib/models/client.dart` | verbrauchteStunden int->double, +Override-Felder |
| `lib/models/app_settings.g.dart` | Regeneriert |
| `lib/models/client.g.dart` | Regeneriert |
| `lib/providers/app_provider.dart` | +FLS-Getter, updateStundenverbrauch fix |
| `lib/screens/settings_screen.dart` | +FLS-Section UI |
| `lib/screens/create_client_screen.dart` | +Override-Felder, dispose, parse |
| `lib/screens/clients_screen.dart` | Erweiterte FLS-Anzeige im Report |
| `lib/screens/export_screen.dart` | verbrauchteStunden formatiert |
| `lib/services/pdf_generator_service.dart` | verbrauchteStunden formatiert |
| `lib/services/export_service.dart` | Keine Änderung nötig (CSV ok) |

### Was sich NICHT geändert hat

- Terminerfassung: FLS = Terminlänge in Stunden (kein Faktor bei Erfassung)
- Der Kalkulationsfaktor ist NUR für Anzeige/Controlling
- Termine fließen weiterhin automatisch in den Stundenverbrauch ein
