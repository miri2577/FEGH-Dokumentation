# Berichte-Tab Konzept

## PDF-Struktur: Informationsbericht v1.01 (5 Seiten)

| Sektion | Felder | Auto-Fill moeglich? |
|---|---|---|
| **Kopf** | Teilhabefachdienst, ID Kostenueber., Berichtszeitraum, Leistungstyp, Leistungserbringer, Adresse | Teilweise (Klientendaten) |
| **1. Persoenliche Daten** | Anrede, Name, Geburtsdatum, Geschlecht, Familienstand, Telefon, E-Mail | Ja (aus Client-Model) |
| **2. Allgemeine Infos** | Ausbildung, Arbeit, Tagesstruktur, Kontakte, Sozialraum (Freitext) | Nein (aus Doku kopieren) |
| **3. Teilhabeziele** | Leitziel, Teilhabeziel, Indikator, Zielerreichung (Checkboxen), Erlaeuterung (Freitext) - wiederholbar | Teilweise (TIB-Ziele) |
| **4. Zusammenfassung** | Freitext + Nacht-Assistenz Ja/Nein | Nein |
| **5. Unterschriften** | Ort, Datum, Leistungserbringer | Teilweise |
| **6. Eintragungen Klient** | Freitext | Nein |

---

## Ansatz: Natives Flutter-Formular + PDF-Export

- Ein natives Flutter-Formular das die PDF-Felder 1:1 abbildet
- Auto-Fill wo moeglich (Klientendaten, TIB-Ziele, Betreuungsdaten)
- Am Ende: Export als ausgefuellte PDF im Original-Layout

## Split-Screen: Formular + Dokumentation

### Desktop/Tablet (Landscape)

```
+---------------------+---------------------+
|                     |                     |
|  Informationsbericht|  Dokumentation      |
|  (Formular)         |  (Volltext-Ansicht) |
|                     |                     |
|  Sektion 1 v        |  12.01.2026         |
|  Sektion 2 v        |  Hausbesuch bei...  |
|  Sektion 3 v        |  Notizen: Lorem...  |
|  ...                |                     |
|                     |  05.01.2026         |
|                     |  Begleitung zu...   |
|  [PDF Export]       |  [Kopieren]         |
+---------------------+---------------------+
```

### Mobile (Portrait)

```
+---------------------+
|  Informationsbericht|  <- Hauptansicht
|  (Formular)         |
|                     |
|  Sektion 2 v        |
|  [Aus Doku einfuegen]| <- Button oeffnet
+---------------------+     Bottom Sheet
        | Swipe
+---------------------+
|  Dokumentation      |  <- Sliding Panel
|  Alle Termine       |     von unten
|  [Text kopieren]    |
+---------------------+
```

## Dokumentations-Volltext-Ansicht (neues Feature)

Eine neue Ansicht "Klienten-Akte" die alle Termine chronologisch als Volltext zeigt:
- Datum + Uhrzeit + Dauer
- Notizen (Volltext)
- Sprachaufzeichnungs-Text
- ICF-Bereiche / TIB-Ziele
- Suchfunktion im Text
- "Text kopieren"-Button pro Eintrag oder Absatz

## Berichte-Tab Uebersicht

```
+---------------------+
|  Berichte            |
|                     |
|  +------------------+|
|  | Informations-    ||
|  | bericht v1.01    ||  <- Erste Vorlage
|  | [Neu erstellen]  ||
|  | [Entwuerfe (3)]  ||
|  +------------------+|
|                     |
|  +------------------+|
|  | (weitere         ||  <- Spaeter erweiterbar
|  |  Berichte)       ||
|  +------------------+|
+---------------------+
```

## Technische Bausteine

| Komponente | Umsetzung |
|---|---|
| **Formular** | Stepper/Accordion pro Sektion, TextFormFields, Dropdowns, Checkboxen |
| **Auto-Fill** | Client-Daten beim Klient-Auswaehlen automatisch eintragen |
| **Doku-Viewer** | Neue Query: alle Appointments fuer einen Client, chronologisch, Volltext |
| **Copy/Paste** | Long-Press oder Button kopiert Text in Zwischenablage |
| **Entwurf speichern** | Neues Model InformationsberichtEntwurf mit JSON-Serialisierung |
| **PDF-Export** | pdf Package - Layout nachbauen, Felder einfuegen, als PDF speichern/teilen |
| **Split-Screen** | Desktop: Row mit zwei Expanded, Mobile: DraggableScrollableSheet |

## Implementierungsreihenfolge

1. **Berichte-Tab** in Navigation einbauen
2. **Klienten-Akte** (Dokumentations-Volltext-Ansicht) als eigenstaendiges Widget
3. **Informationsbericht-Formular** (alle Sektionen als Flutter-Form)
4. **Split-Screen** (Formular + Doku nebeneinander)
5. **Auto-Fill** aus Client-Daten
6. **Entwurf speichern/laden**
7. **PDF-Export** im Original-Layout
