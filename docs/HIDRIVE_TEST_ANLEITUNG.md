# 🧪 HiDrive Test-Anleitung

**Erstellt:** 2025-09-27
**Status:** Bereit für Tests

---

## 🎯 **Test-Ziele**

1. **Verbindung testen** mit echten HiDrive Business Zugangsdaten
2. **Ordnerstruktur validieren** - automatische Erstellung der einheitlichen Struktur
3. **Certificate Pinning prüfen** - Echte STRATO Zertifikate validieren
4. **Erste Synchronisation** - Upload verschlüsselter Testdaten

---

## 📱 **App-Start**

Die macOS App wird gerade im Release-Modus gebaut. Nach dem Start:

```
flutter run -d macos --release
```

**Falls die App nicht startet:** Die App kann auch direkt aus Xcode gestartet werden.

---

## 🔐 **Test-Schritte**

### **1. HiDrive-Konfiguration**
1. App öffnen → **Settings** (Zahnrad-Icon)
2. Sektion **"Cloud-Synchronisation (HiDrive Business)"**
3. **"HiDrive konfigurieren"** anklicken

### **2. Zugangsdaten eingeben**
```
Username: [Ihr HiDrive Business Username]
Passwort: [Ihr HiDrive Business Passwort]
```

**Info-Box zeigt:**
- WebDAV URL: `https://webdav.hidrive.strato.com/users`
- E2E-Verschlüsselung wird automatisch verwendet
- Deutsche Rechenzentren (DSGVO-konform)

### **3. Verbindung testen**
1. **"Speichern"** klicken
2. Zurück zu Settings → **"Verbindung testen"** klicken
3. **Erwartete Ausgabe:**
   ```
   ✅ HiDrive-Verbindung erfolgreich
   ```

### **4. Erste Synchronisation**
1. **"Jetzt synchronisieren"** klicken
2. **Erwartete Ordnerstruktur wird erstellt:**
   ```
   /eingliederungshilfe-data/default/
   ├── organization/
   ├── employees/
   ├── clients/
   ├── schedules/
   ├── reports/
   │   ├── monthly/
   │   └── annual/
   ```

---

## 🔍 **Was wird getestet**

### **Certificate Pinning**
- **STRATO WebDAV:** `sha256/sPTchzpexg44jdkHrtGrWbKgBEKmq3vGyEaG1L2B92c=`
- **STRATO Main:** `sha256/v0UnZ0WdFoxIj5MUfER7im+Kua2y4N6e9yuQLrf7wvU=`
- **Backup Pin:** `sha256/47DEQpj8HBSa+/TImW+5JCeuQeRkm5NMpJWZG3hSuFU=`

### **Verschlüsselung**
- Alle Daten werden mit **AES-256-GCM** verschlüsselt
- **UUID-Dateinamen** (keine PHI in Metadaten)
- **DEK/MEK-System** mit Secure Storage

### **DSGVO-Konformität**
- **Crypto-Erasure** durch DEK-Löschung möglich
- **Deutsche Rechenzentren** (STRATO)
- **Zero-Knowledge E2E** verfügbar

---

## 📊 **Debug-Ausgaben**

**Erwartete Console-Logs:**
```
🔒 Certificate Pinning aktiv für: webdav.hidrive.strato.com
🔒 Erwartete Pins: 3
🔒 Prüfe Zertifikat für webdav.hidrive.strato.com:443
🔒 Zertifikat SPKI Pin: sha256/sPTchzpexg44jdkHrtGrWbKgBEKmq3vGyEaG1L2B92c=
🔒 Pin-Validierung: ✅ GÜLTIG
📁 ✅ Einheitliche Ordnerstruktur bereit für Organisation: default
☁️ ✅ Cloud-Sync initialisiert für: [username]
☁️ ✅ Cloud-Synchronisation abgeschlossen: X/Y Datensätze
```

---

## ⚠️ **Mögliche Probleme**

### **Certificate Pinning Fehler**
```
❌ TLS Handshake fehlgeschlagen: Certificate Pinning Fehler
```
**Lösung:** STRATO hat Zertifikat gewechselt → Neue Pins benötigt

### **Auth-Fehler**
```
❌ Synchronisations-Fehler: Unauthorized
```
**Lösung:** Username/Passwort prüfen, HiDrive Business Account bestätigen

### **Netzwerk-Fehler**
```
❌ Netzwerkverbindung fehlgeschlagen
```
**Lösung:** Firewall/VPN prüfen, Port 443 für webdav.hidrive.strato.com

---

## 🎉 **Erfolgreiche Test-Indikatoren**

1. **Grünes Häkchen** bei HiDrive-Konfiguration
2. **"Verbindung erfolgreich"** Message
3. **Ordnerstruktur erstellt** in HiDrive
4. **Erste Dateien synchronisiert** (verschlüsselt)
5. **Keine Certificate Pinning Fehler**

---

## 📝 **Nach dem Test**

**Bei Erfolg:**
- ✅ Phase 1 abgeschlossen
- ✅ Bereit für Phase 2 (Entwicklermodus deaktivieren)
- ✅ Personalverwaltung kann gleiche Struktur nutzen

**Bei Problemen:**
- Debug-Logs analysieren
- Certificate Pins ggf. aktualisieren
- Auth-Methode überprüfen

---

**🚀 Die App sollte jetzt starten und bereit für Tests sein!**