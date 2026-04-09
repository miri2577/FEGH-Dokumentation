# Storage-Alternativen: Cloud, eigener Server, lokal

## Aktuelle Situation

Die App ist aktuell auf **STRATO HiDrive Business** ueber WebDAV ausgelegt. Da nicht jede Organisation HiDrive nutzen moechte, soll die App kuenftig auch andere Loesungen unterstuetzen -- von eigenen Servern ueber alternative Cloud-Anbieter bis hin zu reiner Lokal-Nutzung.

## Anforderungen an einen Cloud-Anbieter

| Anforderung | Pflicht | Begruendung |
|------------|---------|-------------|
| WebDAV-Protokoll **oder** REST-API | Ja | Datei-Upload/Download |
| Rechenzentrum in Deutschland/EU | Ja | DSGVO Art. 44-49 |
| AVV nach Art. 28 DSGVO | Ja | Datenschutz-Pflicht |
| HTTPS/TLS | Ja | Transportverschluesselung |
| Ausreichend Speicher (>1 GB) | Ja | Fuer verschluesselte Daten |
| Ordner/Verzeichnisse erstellen | Ja | Team-Struktur |
| Dateien einzeln lesen/schreiben | Ja | Record-basierter Zugriff |

!!! note
    Die App verschluesselt alle Daten lokal vor dem Upload. Der Cloud-Anbieter sieht **nur verschluesselte Dateien**. Die Sicherheit haengt nicht vom Anbieter ab, sondern von der App-Verschluesselung.

## Option 1: Eigener Server (maximale Kontrolle)

Die sicherste und unabhaengigste Loesung ist ein eigener Server. Keine Abhaengigkeit von Drittanbietern, keine AVV noetig, volle Kontrolle ueber alle Daten.

### Nextcloud auf eigenem Server

| Eigenschaft | Detail |
|------------|--------|
| Protokoll | WebDAV (kompatibel mit bestehender App) |
| Standort | Eigenes Rechenzentrum oder gehosteter Root-Server |
| AVV | Nicht noetig (eigene Infrastruktur) |
| Kosten | Server-Miete (ab ~5 EUR/Monat) + Administration |
| Vorteile | Volle Kontrolle, keine Datenweitergabe, beliebig erweiterbar |
| Nachteile | Eigene Administration noetig (Updates, Backups, Sicherheit) |

**Empfohlene Server-Anbieter (Deutschland):**

| Anbieter | Ab-Preis | Besonderheit |
|----------|---------|-------------|
| Hetzner Cloud | ~4 EUR/Monat | CX22, Nuernberg/Falkenstein |
| netcup | ~3 EUR/Monat | VPS, Nuernberg |
| IONOS VPS | ~4 EUR/Monat | 1&1, Frankfurt |
| Contabo | ~5 EUR/Monat | Nuernberg/Muenchen |

**Setup-Aufwand:**

1. Linux-Server mieten (Ubuntu/Debian)
2. Nextcloud installieren (Snap oder Docker, ~30 Minuten)
3. SSL-Zertifikat einrichten (Let's Encrypt, automatisch)
4. WebDAV-URL in der App eintragen
5. Fertig -- kein Code-Aenderung noetig, da Nextcloud WebDAV spricht

### ownCloud auf eigenem Server

Aehnlich wie Nextcloud, ebenfalls WebDAV-kompatibel. Enterprise-Version mit professionellem Support verfuegbar.

### Reiner WebDAV-Server (minimal)

Fuer Organisationen die keine Nextcloud-Oberflaeche brauchen:

```bash
# Beispiel: Apache mit mod_dav auf Ubuntu
sudo apt install apache2
sudo a2enmod dav dav_fs
# WebDAV-Verzeichnis konfigurieren
```

Oder als Docker-Container:

```bash
docker run -d -p 443:443 -v /data/fegh:/var/lib/dav bytemark/webdav
```

### NAS im eigenen Netzwerk

Fuer kleine Organisationen mit lokalem Netzwerk:

| NAS-System | WebDAV | Besonderheit |
|-----------|:------:|-------------|
| Synology DiskStation | Ja | WebDAV-Server als Paket installierbar |
| QNAP | Ja | WebDAV integriert |
| TrueNAS | Ja (mit Plugin) | Open Source, ZFS |

**Vorteil:** Daten verlassen nie das Gebaeude. Kein Internet noetig fuer lokale Nutzung.
**Nachteil:** Kein Zugriff von unterwegs ohne VPN.

---

## Option 2: Gehostete Cloud-Dienste

### Tier 1: WebDAV-kompatibel (geringster Aufwand)

Diese Anbieter unterstuetzen WebDAV und koennten mit minimalen Aenderungen genutzt werden:

| Anbieter | Protokoll | Standort | AVV | Besonderheit |
|----------|-----------|----------|:---:|-------------|
| **Nextcloud** (self-hosted) | WebDAV | Eigener Server | Nicht noetig (eigene Infrastruktur) | Volle Kontrolle, kein Drittanbieter |
| **Nextcloud** (gehostet) | WebDAV | Je nach Hoster (DE verfuegbar) | Ja | z.B. Hetzner, netcup, Hosting.de |
| **ownCloud** | WebDAV | Eigener Server oder gehostet | Je nach Setup | Open Source, Enterprise-Version |
| **Hetzner Storage Box** | WebDAV, SFTP | Deutschland | Ja | Guenstig, deutsches Unternehmen |
| **mailbox.org Drive** | WebDAV | Deutschland | Ja | Datenschutz-fokussiert |

**Aenderungen noetig:** Nur die WebDAV-URL und ggf. Authentifizierungsmethode anpassen. Die bestehende `HiDriveWebDAVClient`-Klasse wuerde weitgehend funktionieren.

### Tier 2: REST-API-basiert (mittlerer Aufwand)

Diese Anbieter haben eigene APIs statt WebDAV:

| Anbieter | Protokoll | Standort | AVV | Besonderheit |
|----------|-----------|----------|:---:|-------------|
| **Hetzner Object Storage** | S3-kompatibel | Deutschland | Ja | Kostenguenstig, skalierbar |
| **IONOS HiDrive S3** | S3-kompatibel | Deutschland | Ja | S3-API auf HiDrive-Infrastruktur |
| **Open Telekom Cloud OBS** | S3-kompatibel | Deutschland | Ja | Deutsche Telekom, BSI C5 |

**Aenderungen noetig:** Neuer Storage-Adapter fuer S3-Protokoll. Ordnerstruktur wird durch Key-Prefixes abgebildet.

### Tier 3: Grosse Cloud-Anbieter (groesserer Aufwand + DSGVO-Pruefung)

| Anbieter | Protokoll | Standort | AVV | DSGVO-Hinweis |
|----------|-----------|----------|:---:|-------------|
| **Microsoft OneDrive** | Graph API | EU-Region waehlbar | Ja | US-Unternehmen, EU Data Boundary verfuegbar |
| **Google Drive** | Drive API | EU-Region waehlbar | Ja | US-Unternehmen, Datenverarbeitung in EU moeglich |
| **AWS S3** | S3 API | Frankfurt (eu-central-1) | Ja | US-Unternehmen, EU-Region verfuegbar |

**Aenderungen noetig:** Komplett neuer Storage-Adapter + OAuth-Authentifizierung. DSGVO-Konformitaet muss individuell geprueft werden (Schrems II, EU-US Data Privacy Framework).

## Architektur-Plan: Storage-Abstraktionsschicht

Um mehrere Cloud-Anbieter zu unterstuetzen, wird eine Abstraktionsschicht eingefuehrt:

### Neues Interface: `CloudStorageAdapter`

```dart
abstract class CloudStorageAdapter {
  /// Verbindung testen
  Future<bool> testConnection();

  /// Datei hochladen
  Future<bool> uploadFile(String remotePath, Uint8List data);

  /// Datei herunterladen
  Future<Uint8List?> downloadFile(String remotePath);

  /// Datei loeschen
  Future<bool> deleteFile(String remotePath);

  /// Dateien in Ordner auflisten
  Future<List<String>> listFiles(String remotePath);

  /// Unterordner auflisten
  Future<List<String>> listDirectories(String remotePath);

  /// Ordner erstellen
  Future<bool> createDirectory(String remotePath);
}
```

### Implementierungen

```
CloudStorageAdapter (Interface)
├── HiDriveAdapter        (bestehend, WebDAV)
├── NextcloudAdapter      (WebDAV, neue URL-Struktur)
├── S3Adapter             (fuer Hetzner, IONOS, AWS)
├── LocalStorageAdapter   (nur lokal, kein Cloud)
└── [Weitere nach Bedarf]
```

### Konfiguration im Setup-Wizard

Der Setup-Wizard bekommt eine Anbieter-Auswahl:

1. **Nur lokal** (kein Cloud-Sync)
2. **Eigener Server / NAS** (WebDAV-URL eingeben)
3. **STRATO HiDrive** (bestehend, vorkonfiguriert)
4. **Nextcloud / ownCloud** (WebDAV-URL eingeben)
5. **Hetzner Storage Box** (WebDAV)
6. **S3-kompatibel** (Endpoint, Access Key, Secret Key)

### Migration bestehender Daten

Bei Anbieterwechsel:

1. Alle Daten vom alten Anbieter herunterladen (verschluesselt)
2. Zum neuen Anbieter hochladen
3. Ordnerstruktur wird automatisch neu erstellt
4. Team-Keys und Roles bleiben gleich (sind in den Daten, nicht im Anbieter)

## Umsetzungsreihenfolge

| Phase | Aufwand | Beschreibung |
|-------|---------|-------------|
| **Phase 1** | Gering | `CloudStorageAdapter` Interface erstellen, bestehenden HiDrive-Code umstrukturieren |
| **Phase 2** | Gering | `NextcloudAdapter` (WebDAV, fast identisch mit HiDrive) |
| **Phase 3** | Mittel | `S3Adapter` fuer Hetzner/IONOS Object Storage |
| **Phase 4** | Gering | Setup-Wizard Anbieter-Auswahl |
| **Phase 5** | Mittel | Migrations-Tool fuer Anbieterwechsel |

Phase 1-2 koennen mit minimalem Aufwand umgesetzt werden, da Nextcloud und HiDrive beide WebDAV nutzen. Der Hauptunterschied ist die URL-Struktur und ggf. die XML-Namespace-Konventionen.
