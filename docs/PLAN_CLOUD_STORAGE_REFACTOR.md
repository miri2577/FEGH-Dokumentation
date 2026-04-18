# Plan: Cloud-Storage-Refactor (fegh_cloud Package)

Stand: 18.04.2026
Ziel: Eigenimplementierte WebDAV-Clients durch `webdav_client`-Package
ersetzen, in ein gemeinsames `fegh_cloud`-Package konsolidieren das beide
Apps (FEGH-Dokumentation + FEGH-Verwaltung) nutzen.

---

## Warum

### Aktuelle Probleme

1. **Jeder Provider braucht eigene Quirks-Behandlung**:
   - STRATO HiDrive: MKCOL HTTP 415 wenn Content-Type gesetzt (Workaround:
     Pinning-Bypass, commit `c63d06c`)
   - Nextcloud/ownCloud: App-Token-Auth statt Passwort-Auth
   - Generic WebDAV: unbekannte Quirks je Implementation
2. **Doppelte Implementierungen**:
   - `lib/services/hidrive_webdav_client.dart` (Doku, 1148 Zeilen)
   - `lib/services/hidrive_webdav_client.dart` (Verwaltung, 295 Zeilen)
   - `lib/services/cloud_storage_adapter.dart` abstract + 3 Impls
   - Features divergieren, Fixes muessen mehrfach gemacht werden
3. **Eigener `_PinnedHttpClient` ist fehleranfaellig**:
   - Hat den MKCOL-415-Bug eingeschleppt (dart:io `HttpClientRequest`
     fuegt bei leerem Body automatisch Content-Type hinzu)
   - Muss fuer jeden Provider separat gepflegt werden
4. **Provider-Inkompatibilitaeten unbemerkt**:
   - Solange ein Provider getestet wird, wissen wir nichts ueber andere
   - Sync-Diagnose ist Provider-spezifisch

### Zielbild

- Ein einziges Package `fegh_cloud` kapselt allen Cloud-Storage-Zugriff
- Basiert auf bewaehrtem `webdav_client` (^1.2.2), das alle grossen
  WebDAV-Server (STRATO, Nextcloud, ownCloud, Apache, Nginx dav) kennt
- Provider-spezifische Adapter fuer Pinning, Auth-Tokens, URL-Schemas
- Beide Apps importieren via `path:` (wie `fegh_crypto`)
- Ein Bug-Fix → beide Apps profitieren

---

## Architektur

### Shared-Package Struktur

```
C:\fegh-shared\fegh_cloud\
├── pubspec.yaml                (webdav_client, http, cryptography)
├── lib\
│   ├── fegh_cloud.dart         (exports)
│   └── src\
│       ├── cloud_adapter.dart         (abstract class CloudAdapter)
│       ├── result.dart                (CloudResult<T>, Fehlertyp)
│       ├── adapters\
│       │   ├── hidrive_adapter.dart   (STRATO-Pins, Basic Auth)
│       │   ├── nextcloud_adapter.dart (App-Token-Auth)
│       │   ├── owncloud_adapter.dart  (wie Nextcloud)
│       │   └── generic_adapter.dart   (Vanilla WebDAV)
│       └── provider_type.dart         (enum CloudProviderType)
└── test\
    ├── adapter_contract_test.dart     (Gemeinsame Adapter-Vertraege)
    ├── hidrive_mock_test.dart         (Mock-Server fuer STRATO-Verhalten)
    └── nextcloud_mock_test.dart
```

### API-Skizze

```dart
abstract class CloudAdapter {
  Future<CloudResult<void>> testConnection();
  Future<CloudResult<void>> createDirectory(String path);
  Future<CloudResult<Uint8List>> download(String path);
  Future<CloudResult<void>> upload(String path, Uint8List data);
  Future<CloudResult<void>> delete(String path);
  Future<CloudResult<List<CloudEntry>>> list(String path);
  Future<CloudResult<List<CloudEntry>>> listDirectories(String path);
}

class CloudEntry {
  final String name;
  final String path;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;
}
```

### Provider-Konfiguration

```dart
class HidriveAdapter extends CloudAdapter {
  HidriveAdapter({
    required String username,
    required String password,
    List<String>? certificatePins,  // SPKI-Pins fuer STRATO
  });
}

class NextcloudAdapter extends CloudAdapter {
  NextcloudAdapter({
    required String serverUrl,
    required String username,
    required String appToken,  // nicht Login-Password
  });
}
```

---

## Phasen

### Phase 1: fegh_cloud Skelett + HiDriveAdapter (2-3 Tage)

1. Package anlegen mit `webdav_client`-Dependency
2. `CloudAdapter`-Interface, `CloudResult<T>`, `CloudEntry`
3. `HidriveAdapter` implementieren
4. Tests: Mock-Server-basiert + optional Live-Test gegen echte HiDrive
5. Doku-App: `HiDriveWebDAVClient` und `_PinnedHttpClient` durch
   `HidriveAdapter` ersetzen
6. Beide Apps pubspec: `fegh_cloud` als path-Dep

**Abschluss-Kriterium:**
- MKCOL, PUT, PROPFIND gegen HiDrive funktionieren mit
  Cert-Pinning aktiv
- Bisheriger MKCOL-Bypass kann entfernt werden

### Phase 2: Nextcloud + ownCloud Adapter (1-2 Tage)

1. `NextcloudAdapter` mit App-Token-Auth
2. `OwncloudAdapter` (Alias oder wirklich eigene Impl falls noetig)
3. Docker-Nextcloud lokal fuer Tests
4. Integration-Tests

**Abschluss-Kriterium:**
- Mindestens ein Nextcloud-Testkunde kann App produktiv nutzen

### Phase 3: Konsolidierung Verwaltung (1 Tag)

1. FEGH-Verwaltung auf `fegh_cloud` umstellen
2. Eigener `hidrive_webdav_client.dart` dort entfernen
3. Contract-Tests verifizieren dass beide Apps identisch sprechen

**Abschluss-Kriterium:**
- Verwaltung und Doku greifen auf dieselben Files zu, beide lesen und
  schreiben erfolgreich

### Phase 4: Cleanup + Doku (0.5 Tage)

1. Alte `lib/services/hidrive_webdav_client.dart` und
   `cloud_storage_adapter.dart` entfernen
2. Wiki aktualisieren (Cloud-Sync-Seite)
3. MKCOL-Bypass-TODO aus `hidrive_webdav_client.dart` entfernen
   (gesamte Datei verschwindet)
4. Changelog in beiden Apps

---

## Test-Strategie

### Unit-Tests im fegh_cloud-Package
- Adapter-Contract-Tests (gleiche Signatur, gleiches Verhalten)
- Mock-Server pro Adapter fuer spezifische Quirks

### Integration-Tests (in beiden Apps)
- Smoke-Test: testConnection, ein MKCOL, ein PUT, ein GET, ein DELETE
- Round-Trip: Verwaltung erzeugt Ordner → Doku liest ihn → beides kann schreiben

### Live-Tests (manuell)
- STRATO HiDrive: vorhandener Account
- Nextcloud: Docker-Setup aus Wiki
- Beide Apps parallel

---

## Rollback-Strategie

Falls `webdav_client` unerwartete Probleme zeigt:
- Die alten Implementierungen bleiben bis nach Phase 4 als
  `hidrive_webdav_client_legacy.dart` im Repo, nicht importiert
- Bei kritischem Fehler: Feature-Flag `useSharedCloudPackage` in
  AppSettings, Default true, Umschalten moeglich
- Provider-Adapter sind isoliert: wenn Nextcloud nicht klappt, kann
  HiDrive trotzdem via fegh_cloud weiterlaufen

---

## Zeitplan konservativ

| Phase | Dauer | Parallelisierbar |
|---|---|---|
| Phase 1: Skelett + HiDrive | 2-3 Tage | - |
| Phase 2: Nextcloud/ownCloud | 1-2 Tage | Kann nach Phase 1 starten |
| Phase 3: Verwaltung umstellen | 1 Tag | Nach Phase 1 |
| Phase 4: Cleanup + Doku | 0.5 Tage | - |
| **Gesamt** | **4-6 Tage** | |

---

## Nicht-Ziele

- Keine neuen Provider ueber das hinaus, was der aktuelle
  CloudStorageAdapter bietet (das Refactor ist drop-in, kein Feature-Build)
- Keine Aenderung am Wire-Format der Daten (weiter via `fegh_crypto`)
- Kein Impact auf Crypto, Rechnungsmodul, Wirkungsmessung, Rollen etc.

---

## Sofort-Start: Phase 1

Erste Schritte:
1. `C:\fegh-shared\fegh_cloud\` anlegen analog zu `fegh_crypto`
2. `pubspec.yaml` mit `webdav_client: ^1.2.2`
3. `CloudAdapter`-Interface definieren
4. `HidriveAdapter` als erste Implementation
5. Unit-Test mit Mock-Server: MKCOL mit/ohne Content-Type
6. Live-Test gegen vorhandenes STRATO-Setup

Nach Phase 1 ist der aktuelle MKCOL-Bypass obsolet und Cert-Pinning
wieder vollstaendig aktiv.
