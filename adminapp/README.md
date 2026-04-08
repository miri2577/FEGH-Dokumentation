# Eingliederungshilfe Admin

Eine sichere Desktop-Anwendung für die Verwaltung von Mitarbeitern, Dienstplänen und Urlaubsanträgen in Einrichtungen der Eingliederungshilfe.

## 🚀 Features

### ✅ Vollständig implementiert:
- **E2E-Verschlüsselung** mit libsodium (XChaCha20-Poly1305)
- **HiDrive Business Integration** über WebDAV
- **Sichere Schlüsselverwaltung** in der System-Keychain
- **Mitarbeiterverwaltung** mit Stammdaten und Qualifikationen
- **Dienstplanung** mit Wochenkalender-Ansicht
- **Urlaubsverwaltung** mit Antrags- und Genehmigungsworkflow
- **Setup-Wizard** für einfache Ersteinrichtung
- **Responsive Design** mit modernem UI

### 🎯 Vivendi PEP Features nachgebaut:
- Mitarbeiter-Stammdaten mit Skills und Bereichen
- Schichtplanung mit verschiedenen Diensttypen
- Urlaubs- und Abwesenheitsverwaltung
- Team-/Bereichsfilter und Status-Management
- Backup & Export-Funktionen

## 🔒 Sicherheit

- **Keine Server erforderlich** - alles läuft lokal + HiDrive Cloud
- **Defense-in-Depth**: App-intern verschlüsselt + HiDrive E2E + HTTPS
- **DSGVO-konform**: Datenhaltung in Deutschland (HiDrive Business)
- **UUID-Dateinamen**: Metadaten-Schutz auch bei HiDrive-Zugriff
- **Secure Storage**: Verschlüsselungsschlüssel in OS-Keychain

## 📦 Installation & Setup

### Voraussetzungen

1. **Node.js 18+** und **npm/pnpm**
2. **HiDrive Business Account** bei STRATO
3. **Git** für Entwicklung

### 1. Repository klonen
```bash
cd adminapp
npm install
# oder
pnpm install
```

### 2. Entwicklung starten
```bash
npm run dev
# oder
pnpm dev
```

### 3. Produktion bauen
```bash
npm run build
npm run package
# oder
pnpm build
pnpm package
```

## 🔧 Konfiguration

### HiDrive Business Setup

1. **HiDrive Business Account** bei STRATO anlegen
2. **E2E-Verschlüsselung aktivieren** in den HiDrive-Einstellungen
3. **WebDAV-Zugang** aktivieren (meist automatisch aktiv)
4. **Zugangsdaten notieren**: URL, Benutzername, Passwort

### App-Konfiguration

Beim ersten Start führt Sie der Setup-Wizard durch:

1. **HiDrive-Verbindung** konfigurieren
2. **Verschlüsselung** wird automatisch eingerichtet
3. **Firmen-Daten** eingeben (optional)
4. **Verbindung testen** und abschließen

## 🛠️ Entwicklung

### Projektstruktur
```
adminapp/
├── src/
│   ├── main/           # Electron Main Process
│   ├── preload/        # IPC Bridge (secure)
│   ├── renderer/       # React Frontend
│   │   ├── components/ # UI Components
│   │   ├── hooks/      # React Hooks
│   │   └── styles/     # CSS Styles
│   ├── lib/           # Core Libraries
│   │   ├── crypto.ts  # Verschlüsselung
│   │   └── hidrive.ts # HiDrive Client
│   └── types/         # TypeScript Types
├── dist/              # Build Output
└── release/           # Packaged Apps
```

### Wichtige Scripts
```bash
# Entwicklung mit Hot Reload
npm run dev

# Produktion Build
npm run build

# App packen (DMG/EXE/AppImage)
npm run package

# Tests ausführen
npm test

# TypeScript prüfen
npx tsc --noEmit
```

### Technologie-Stack
- **Electron** + **electron-vite** für Desktop-App
- **React** + **TypeScript** für Frontend
- **libsodium** für Verschlüsselung
- **webdav** für HiDrive-Integration
- **keytar** für sichere Schlüssel-Speicherung
- **date-fns** für Datums-Handling

## 📱 Nutzung

### 1. Mitarbeiterverwaltung
- Mitarbeiter anlegen, bearbeiten, löschen
- Stammdaten mit Qualifikationen/Skills
- Bereiche und Positionen verwalten
- Filter und Suchfunktionen

### 2. Dienstplanung
- Wochenkalender mit Drag & Drop
- Verschiedene Schichttypen (Normal, Überstunden, Nacht, Wochenende)
- Mitarbeiter-Filter nach Bereichen
- Status-Tracking (Geplant, Bestätigt, Abgeschlossen)

### 3. Urlaubsverwaltung
- Anträge stellen und bearbeiten
- Genehmigungsworkflow
- Verschiedene Antragstypen (Urlaub, Krank, Persönlich, Fortbildung)
- Übersicht und Statistiken

### 4. Einstellungen
- HiDrive-Verbindung verwalten
- Arbeitszeiten konfigurieren
- Überstunden-Regeln definieren
- Backup erstellen/wiederherstellen

## 🔐 Datenschutz & Compliance

### DSGVO-Konformität
- **Datenhaltung in Deutschland** (HiDrive Business)
- **Zweckbindung**: Nur notwendige Mitarbeiterdaten
- **Löschkonzept**: Einfache Datenlöschung möglich
- **Zugriffsschutz**: Verschlüsselung + Keychain
- **Dokumentation**: Automatische Backup-Historie

### Technische Sicherheitsmaßnahmen
- **E2E-Verschlüsselung**: XChaCha20-Poly1305
- **Schlüssel-Rotation**: MEK kann gewechselt werden
- **Sichere Übertragung**: HTTPS + Certificate Pinning
- **Metadaten-Schutz**: UUID-Dateinamen, verschlüsseltes Manifest

## 🆚 Vergleich zu Vivendi PEP

| Feature | Vivendi PEP | Eingliederungshilfe Admin |
|---------|-------------|---------------------------|
| Server erforderlich | ✅ Ja (komplex) | ❌ Nein (HiDrive only) |
| Installation | 🔧 Serveradmin nötig | ✅ Einfach für Laien |
| Kosten | 💰 Lizenz + Server | 💰 Nur HiDrive Business |
| Verschlüsselung | ⚠️ Optional | ✅ Standardmäßig E2E |
| DSGVO | ✅ Ja | ✅ Ja (Deutschland) |
| Mitarbeiterverwaltung | ✅ Vollständig | ✅ Vollständig |
| Dienstplanung | ✅ Vollständig | ✅ Wochenplanung |
| Urlaubsverwaltung | ✅ Vollständig | ✅ Vollständig |
| Mobile App | ✅ Ja | 🔄 Geplant |
| Multi-Mandant | ✅ Ja | ❌ Single-Tenant |
| Reporting | ✅ Umfangreich | 🔄 Basic |

## 🎯 Zielgruppe

**Perfekt geeignet für:**
- Kleine bis mittlere Einrichtungen (5-50 Mitarbeiter)
- Träger ohne eigene IT-Abteilung
- Teams die Wert auf Datenschutz legen
- Einrichtungen mit begrenztem Budget
- Dezentrale Verwaltung ohne Server-Dependency

## 🚀 Roadmap

### Phase 1 - Core Features ✅
- [x] Mitarbeiterverwaltung
- [x] Dienstplanung
- [x] Urlaubsverwaltung
- [x] HiDrive-Integration
- [x] E2E-Verschlüsselung

### Phase 2 - Erweiterte Features 🔄
- [ ] Zeiterfassung/Stempeluhr
- [ ] Team-Management
- [ ] Erweiterte Berichte/Export
- [ ] Auto-Updates
- [ ] Multi-Language Support

### Phase 3 - Enterprise Features 📋
- [ ] Mobile Companion App
- [ ] API für Drittsysteme
- [ ] Advanced Reporting
- [ ] Multi-Tenant Support
- [ ] Workflow-Automatisierung

## 📞 Support

Bei Fragen oder Problemen:

1. **Dokumentation** prüfen (dieses README)
2. **Setup-Wizard** erneut durchlaufen
3. **HiDrive-Verbindung** testen
4. **Logs** prüfen (Entwicklertools)

### Häufige Probleme

**HiDrive-Verbindung fehlgeschlagen:**
- E2E-Verschlüsselung in HiDrive aktiviert?
- Korrekte WebDAV-URL verwendet?
- Benutzername/Passwort richtig?

**Verschlüsselung-Fehler:**
- Keychain-Zugriff erlaubt?
- MEK korrekt generiert?
- Backup vorhanden?

## 📄 Lizenz

Proprietary - Alle Rechte vorbehalten

---

**Eingliederungshilfe Admin** - Sichere, dezentrale Verwaltung für soziale Einrichtungen 🏥