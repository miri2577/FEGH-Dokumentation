# 🏗️ Einheitliche HiDrive-Ordnerstruktur für beide Apps

**Erstellt:** 2025-09-27
**Status:** 🔄 In Entwicklung

---

## 🎯 **Zielsetzung**

Beide Flutter-Apps (Eingliederungshilfe + Personalverwaltung) müssen eine **einheitliche Datenorganisation** in HiDrive verwenden, damit sie nahtlos zusammenarbeiten können.

---

## 📋 **Datenmodell-Analyse**

### **App 1: Eingliederungshilfe (Mobile)**
```dart
- Client (Klienten)
- Appointment (Termine)
- Arbeitszeit (Arbeitszeiten)
- Mitarbeiter (Grunddaten)
- FreizeitAntrag (Urlaubsanträge)
```

### **App 2: Personalverwaltung (Desktop)**
```dart
- Employee (Mitarbeiter) - ERWEITERT
- Client (Klienten) - ERWEITERT
- Team (Teams)
- Shift (Schichten)
- Vacation (Urlaub)
- Timesheet (Stundenzettel)
- VacationRequest (Urlaubsanträge)
```

### **🔄 Daten-Mapping**
| Eingliederungshilfe | Personalverwaltung | Beziehung |
|--------------------|--------------------|-----------|
| `Client` | `Client` | **1:1 Sync** |
| `Mitarbeiter` | `Employee` | **1:1 Sync** (Desktop hat mehr Felder) |
| `Appointment` | - | **Mobile only** |
| `Arbeitszeit` | `Timesheet` | **Ähnlich, kompatibel** |
| `FreizeitAntrag` | `VacationRequest` | **1:1 Sync** |
| - | `Team` | **Desktop only** |
| - | `Shift` | **Desktop only** |

---

## 🗂️ **Einheitliche HiDrive-Ordnerstruktur**

### **Root-Struktur**
```
/eingliederungshilfe-data/
├── organization/           # Einrichtungs-Metadaten
│   ├── settings.enc       # Globale Einstellungen
│   ├── teams.enc          # Teams/Abteilungen
│   └── manifest.json      # Root-Manifest
├── employees/             # Mitarbeiter (zentral verwaltet)
│   ├── {employee-uuid}/   # Pro Mitarbeiter
│   │   ├── profile.enc    # Employee-Profil (Personalverwaltung)
│   │   ├── timesheets.enc # Stundenzettel
│   │   ├── schedule.enc   # Schichtpläne
│   │   └── vacation.enc   # Urlaubsdaten
│   └── manifest.json
├── clients/               # Klienten (beide Apps)
│   ├── {client-uuid}/     # Pro Klient
│   │   ├── profile.enc    # Client-Basisdaten
│   │   ├── appointments.enc # Termine (Eingliederungshilfe)
│   │   ├── documents.enc  # Dokumente
│   │   ├── care-plans.enc # Betreuungspläne
│   │   └── assigned-staff.enc # Zugewiesene Mitarbeiter
│   └── manifest.json
├── schedules/             # Dienstpläne (Personalverwaltung)
│   ├── {year}/{month}/    # Nach Datum organisiert
│   │   ├── shifts.enc     # Schichten
│   │   └── coverage.enc   # Abdeckung
│   └── manifest.json
└── reports/               # Berichte & Analytics
    ├── monthly/           # Monatsberichte
    ├── annual/            # Jahresberichte
    └── manifest.json
```

---

## 🔐 **Verschlüsselungskonzept**

### **Dreistufiges Schema:**
1. **Organisations-Level:** Shared DEK für Teams, Settings
2. **Employee-Level:** Individual DEK pro Mitarbeiter
3. **Client-Level:** Individual DEK pro Klient

### **Zugriffskontrolle:**
```dart
Access Rights Matrix:
- Admin: Alle Ordner (Personalverwaltung)
- Teamleiter: Eigenes Team + zugewiesene Klienten
- Mitarbeiter: Nur eigene Daten + zugewiesene Klienten (Eingliederungshilfe)
```

---

## 📱💻 **App-spezifische Implementierung**

### **Eingliederungshilfe (Mobile)**
**Zugriff:**
- `clients/{client-uuid}/appointments.enc` ✅ (Lesen/Schreiben)
- `clients/{client-uuid}/profile.enc` ✅ (Lesen only)
- `employees/{own-uuid}/timesheets.enc` ✅ (Lesen/Schreiben)

**Sync-Modus:**
```dart
// Nur zugewiesene Klienten synchronisieren
final assignedClients = await getAssignedClients(employeeId);
for (client in assignedClients) {
  await syncClientAppointments(client.id);
}
```

### **Personalverwaltung (Desktop)**
**Zugriff:**
- `employees/` ✅ (Vollzugriff)
- `clients/` ✅ (Vollzugriff)
- `schedules/` ✅ (Vollzugriff)
- `organization/` ✅ (Vollzugriff)

**Sync-Modus:**
```dart
// Vollständige Synchronisation aller Daten
await syncAllEmployees();
await syncAllClients();
await syncSchedules();
await syncReports();
```

---

## 🔄 **Synchronisations-Workflow**

### **Szenario 1: Neuer Klient**
1. **Personalverwaltung:** Erstellt `clients/{uuid}/profile.enc`
2. **Auto-Sync:** Manifest wird aktualisiert
3. **Eingliederungshilfe:** Lädt neue Klientenliste
4. **Assignment:** Admin weist Klient zu Mitarbeiter zu
5. **Eingliederungshilfe:** Kann jetzt Termine für Klient erstellen

### **Szenario 2: Terminbuchung**
1. **Eingliederungshilfe:** Erstellt `clients/{uuid}/appointments.enc`
2. **Auto-Sync:** Upload zu HiDrive
3. **Personalverwaltung:** Sieht Termine in Reports/Analytics

### **Szenario 3: Mitarbeiter-Update**
1. **Personalverwaltung:** Aktualisiert `employees/{uuid}/profile.enc`
2. **Auto-Sync:** Upload zu HiDrive
3. **Eingliederungshilfe:** Lädt aktualisierte Mitarbeiterdaten

---

## 🛡️ **Sicherheitskonzept**

### **Berechtigungsmatrix:**
```
Datentyp          | Mobile App | Desktop App | Verschlüsselung
------------------|------------|-------------|----------------
Client Profile    | Read       | Read/Write  | Client-DEK
Client Appts      | Read/Write | Read        | Client-DEK
Employee Profile  | Read (own) | Read/Write  | Employee-DEK
Timesheets        | Write (own)| Read/Write  | Employee-DEK
Teams             | Read       | Read/Write  | Org-DEK
Schedules         | Read       | Read/Write  | Org-DEK
```

### **Isolation:**
- **Mandantenfähigkeit:** Jede Einrichtung hat eigenen HiDrive-Pfad
- **GDPR-Konformität:** Crypto-Erasure durch DEK-Löschung
- **Audit-Trail:** Alle Änderungen werden in Manifest protokolliert

---

## 📊 **Manifest-Schema**

### **Root Manifest:**
```json
{
  "version": "2.0",
  "organization": {
    "id": "einrichtung-uuid",
    "name": "Muster-Einrichtung GmbH",
    "created": "2025-09-27T10:00:00Z"
  },
  "schema_version": "1.0",
  "encryption": {
    "algorithm": "AES-256-GCM",
    "kdf": "PBKDF2"
  },
  "last_sync": "2025-09-27T15:30:00Z",
  "apps": {
    "eingliederungshilfe": {
      "version": "2.0.0",
      "last_active": "2025-09-27T15:25:00Z"
    },
    "personalverwaltung": {
      "version": "1.0.0",
      "last_active": "2025-09-27T15:30:00Z"
    }
  },
  "data_stats": {
    "employees": 12,
    "clients": 45,
    "teams": 3,
    "total_encrypted_files": 234
  }
}
```

### **Client Manifest:**
```json
{
  "client_id": "client-uuid",
  "assigned_employees": ["emp-uuid-1", "emp-uuid-2"],
  "access_levels": {
    "emp-uuid-1": ["appointments", "notes"],
    "emp-uuid-2": ["appointments"]
  },
  "data_files": {
    "profile.enc": {
      "created": "2025-09-27T10:00:00Z",
      "modified": "2025-09-27T15:00:00Z",
      "size": 2048,
      "checksum": "sha256:abc123..."
    },
    "appointments.enc": {
      "created": "2025-09-27T11:00:00Z",
      "modified": "2025-09-27T15:30:00Z",
      "size": 4096,
      "checksum": "sha256:def456..."
    }
  }
}
```

---

## 🚀 **Implementierungsplan**

### **Phase 1: Struktur implementieren**
- [ ] HiDrive-Ordnerstruktur in beiden Apps
- [ ] Unified Manifest-System
- [ ] Crypto-Key-Management

### **Phase 2: Sync-Engine**
- [ ] Bidirektionale Synchronisation
- [ ] Konflikt-Resolution
- [ ] Offline-Support

### **Phase 3: Berechtigungen**
- [ ] Role-based Access Control
- [ ] Client-Assignment-System
- [ ] Audit-Logging

---

## ⚠️ **Wichtige Designentscheidungen**

1. **Client-Assignment:** Wird in Personalverwaltung verwaltet, von Mobile App respektiert
2. **Data Ownership:** Personalverwaltung = Master, Mobile App = Consumer+Producer
3. **Conflict Resolution:** "Last Writer Wins" mit Timestamp-basiertem Merge
4. **GDPR:** Crypto-Erasure auf Client- und Employee-Level möglich

---

## ✅ **Implementierungsstatus**

### **Eingliederungshilfe App:**
- [x] HiDrive-Ordnerstruktur implementiert
- [x] Organization-Modell erstellt
- [x] WebDAV-Client erweitert mit einheitlichen Pfaden
- [x] SecureStorageService aktualisiert
- [ ] Organization-Settings UI
- [ ] Client-Assignment-System

### **Personalverwaltung App:**
- [ ] HiDrive-Ordnerstruktur übernehmen
- [ ] Organization-Modell integrieren
- [ ] Admin-Interface für Organization-Setup
- [ ] Client-Assignment-Verwaltung

---

**🔄 Nächster Schritt:** Mit echten HiDrive-Zugangsdaten testen und Ordnerstruktur validieren