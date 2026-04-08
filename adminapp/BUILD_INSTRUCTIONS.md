# Build Anweisungen - Eingliederungshilfe Admin

## 🚀 Schnellstart

```bash
# 1. Dependencies installieren
pnpm install

# 2. Entwicklung starten
pnpm dev

# 3. Für Produktion bauen
pnpm build
pnpm package
```

## 📋 Detaillierte Schritte

### 1. Voraussetzungen prüfen

```bash
# Node.js Version (mindestens 18)
node --version

# pnpm installieren falls nicht vorhanden
npm install -g pnpm

# Python für native Module (optional)
python --version
```

### 2. Projekt einrichten

```bash
# In das adminapp Verzeichnis wechseln
cd adminapp

# Dependencies installieren
pnpm install

# Bei Problemen mit nativen Modulen:
npx electron-rebuild
```

### 3. Entwicklung

```bash
# Entwicklungsserver starten (Hot Reload)
pnpm dev

# TypeScript prüfen
pnpm tsc --noEmit

# Tests ausführen
pnpm test

# Linting (falls konfiguriert)
pnpm lint
```

### 4. Produktion Build

```bash
# App kompilieren
pnpm build

# Installer/DMG/AppImage erstellen
pnpm package

# Ausgabe in release/ Ordner
ls release/
```

## 🛠️ Troubleshooting

### Problem: "gyp ERR!" bei Installation

**Windows:**
```bash
npm install --global windows-build-tools
```

**macOS:**
```bash
xcode-select --install
```

**Linux:**
```bash
sudo apt-get install build-essential
```

### Problem: "keytar" Fehler

```bash
# Rebuild native modules
npx electron-rebuild

# Alternative: node-keytar ersetzen
npm uninstall keytar
npm install @electron/keytar
```

### Problem: "Cannot find module" Fehler

```bash
# Node modules neu installieren
rm -rf node_modules
rm package-lock.json
pnpm install
```

### Problem: TypeScript Fehler

```bash
# TypeScript kompilieren ohne Emit
npx tsc --noEmit

# Typen-Dependencies prüfen
pnpm install @types/node @types/react @types/react-dom
```

## 📦 Build-Varianten

### Development Build
```bash
pnpm dev
# - Hot Reload aktiv
# - DevTools geöffnet
# - Unminified Code
# - Source Maps
```

### Production Build
```bash
pnpm build
# - Optimiert & minified
# - Keine DevTools
# - Source Maps optional
```

### Distribution Build
```bash
pnpm package
# Erstellt:
# - macOS: DMG Installer
# - Windows: NSIS Installer
# - Linux: AppImage
```

## 🔧 Build-Konfiguration

### electron.vite.config.ts
- Main Process Konfiguration
- Renderer Process Konfiguration
- Preload Script Konfiguration

### package.json - Build Sektion
```json
{
  "build": {
    "appId": "com.eingliederungshilfe.admin",
    "productName": "Eingliederungshilfe Admin",
    "directories": {
      "output": "release"
    },
    "files": [
      "dist/**/*",
      "node_modules/**/*"
    ]
  }
}
```

## 🚢 Deployment

### macOS Code Signing (optional)
```bash
# Developer ID Certificate erforderlich
export CSC_NAME="Developer ID Application: Ihr Name"
pnpm package
```

### Windows Code Signing (optional)
```bash
# Code Signing Certificate erforderlich
export CSC_LINK="path/to/certificate.p12"
export CSC_KEY_PASSWORD="password"
pnpm package
```

### Notarization (macOS)
```bash
# Apple ID erforderlich
export APPLE_ID="your-apple-id@example.com"
export APPLE_ID_PASSWORD="app-specific-password"
pnpm package
```

## 📊 Build Performance

### Optimierungen aktivieren
```bash
# Package.json scripts erweitern:
"build:fast": "electron-vite build --mode development"
"build:prod": "electron-vite build --mode production"
```

### Build-Zeit reduzieren
- Nur notwendige Dependencies bundeln
- Source Maps deaktivieren für Prod
- Parallele Builds verwenden

## 🧪 Testing

### Unit Tests
```bash
pnpm test
# Verwendet: vitest + jsdom
```

### E2E Tests (optional)
```bash
# Mit Playwright/Spectron
pnpm test:e2e
```

### Manual Testing
```bash
# Development Build testen
pnpm dev

# Production Build testen
pnpm build
pnpm preview
```

## 📋 Checkliste vor Release

- [ ] Dependencies aktualisiert
- [ ] Tests bestehen
- [ ] TypeScript kompiliert ohne Fehler
- [ ] Build läuft durch
- [ ] App startet korrekt
- [ ] HiDrive-Verbindung funktioniert
- [ ] Setup-Wizard funktioniert
- [ ] Alle Features getestet
- [ ] Performance akzeptabel
- [ ] Speicherverbrauch normal

## 🔄 CI/CD (optional)

### GitHub Actions Beispiel
```yaml
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ${{ matrix.os }}
    strategy:
      matrix:
        os: [macos-latest, windows-latest, ubuntu-latest]
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: 18
      - run: npm install -g pnpm
      - run: pnpm install
      - run: pnpm build
      - run: pnpm package
```

## 📄 Logs & Debugging

### Development Logs
```bash
# Electron Main Process Logs
tail -f ~/Library/Logs/eingliederungshilfe-admin/main.log

# Renderer Process Logs
# DevTools Console
```

### Production Logs
```bash
# macOS
~/Library/Logs/eingliederungshilfe-admin/

# Windows
%APPDATA%\eingliederungshilfe-admin\logs\

# Linux
~/.config/eingliederungshilfe-admin/logs/
```

---

Bei Problemen: README.md lesen oder GitHub Issues erstellen.