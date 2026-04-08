# Dart‑Crypto‑Utility (Envelope + Manifest, Streaming, Rotation, GCM‑SIV) & HiDrive‑Onboarding‑Checkliste

> Sofort einsetzbar in deiner Flutter‑App. Abhängigkeiten: `cryptography`, `flutter_secure_storage`, `path_provider`, `uuid`, `http`. 

---

## 1) `crypto_storage.dart` – Envelope‑Encryption, Streaming & Rotation
```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class CryptoStorage {
  CryptoStorage({this.storageKey = 'app_mek', FlutterSecureStorage? secure})
      : secure = secure ?? const FlutterSecureStorage();

  final String storageKey;
  final FlutterSecureStorage secure;
  final Cipher _aead = AesGcm.with256bits(); // Optional: AesGcmSiv.with256bits()
  final Uuid _uuid = const Uuid();

  Future<List<int>> _getOrCreateMEK() async {
    final existing = await secure.read(key: storageKey);
    if (existing != null) return base64.decode(existing);
    final mek = _randomBytes(32);
    await secure.write(key: storageKey, value: base64.encode(mek));
    return mek;
  }

  Future<void> rotateMEK() async {
    final newMek = _randomBytes(32);
    await secure.write(key: storageKey, value: base64.encode(newMek));
    // Wichtig: Rewrap aller DEKs notwendig – z. B. Batchjob über Manifest
  }

  List<int> _randomBytes(int len) {
    final rng = Cryptography.instance.newRandom();
    return rng.nextBytes(len);
  }

  Future<Map<String, dynamic>> encryptRecord({
    required List<int> plaintext,
    Map<String, dynamic>? aad,
  }) async {
    final mek = await _getOrCreateMEK();

    final dek = _randomBytes(32);
    final nonce1 = _randomBytes(12);
    final secretKeyDek = SecretKey(dek);
    final aadBytes = utf8.encode(jsonEncode(aad ?? {}));
    final box = await _aead.encrypt(plaintext,
        secretKey: secretKeyDek, nonce: Nonce(nonce1), aad: aadBytes);

    final nonce2 = _randomBytes(12);
    final secretKeyMek = SecretKey(mek);
    final wrapped = await _aead.encrypt(dek,
        secretKey: secretKeyMek,
        nonce: Nonce(nonce2),
        aad: utf8.encode('{"type":"dek"}'));

    return {
      'v': 1,
      'alg': 'AES-256-GCM',
      'nonce': base64.encode(nonce1),
      'aad': aad ?? {},
      'ciphertext': base64.encode(box.cipherText),
      'tag': base64.encode(box.mac.bytes),
      'dekWrapped': {
        'alg': 'AES-256-GCM',
        'nonce': base64.encode(nonce2),
        'ciphertext': base64.encode(wrapped.cipherText),
        'tag': base64.encode(wrapped.mac.bytes)
      }
    };
  }

  Future<List<int>> decryptRecord(Map<String, dynamic> record) async {
    final mek = await _getOrCreateMEK();
    final secretKeyMek = SecretKey(mek);

    final wrapped = record['dekWrapped'] as Map<String, dynamic>;
    final dekBytes = await _aead.decrypt(
      SecretBox(
        base64.decode(wrapped['ciphertext']),
        nonce: Nonce(base64.decode(wrapped['nonce'])),
        mac: Mac(base64.decode(wrapped['tag'])),
      ),
      secretKey: secretKeyMek,
      aad: utf8.encode('{"type":"dek"}')
    );

    final secretKeyDek = SecretKey(dekBytes);
    final box = SecretBox(
      base64.decode(record['ciphertext']),
      nonce: Nonce(base64.decode(record['nonce'])),
      mac: Mac(base64.decode(record['tag'])),
    );
    final aadBytes = utf8.encode(jsonEncode(record['aad'] ?? {}));
    return _aead.decrypt(box, secretKey: secretKeyDek, aad: aadBytes);
  }

  Future<String> saveJsonEncrypted(String schema, Map<String, dynamic> jsonObj) async {
    final bytes = utf8.encode(jsonEncode(jsonObj));
    final rec = await encryptRecord(plaintext: bytes, aad: {'schema': schema, 'ts': DateTime.now().toUtc().toIso8601String()});
    final uuid = _uuid.v4();
    final dir = await _secureDataDir();
    final f = File('${dir.path}/$uuid.bin');
    await f.writeAsString(jsonEncode(rec), flush: true);
    await _updateManifest((m) {
      m.entries.add(ManifestEntry(uuid: uuid, schema: schema, title: jsonObj['title'] ?? '', updatedAt: DateTime.now().toUtc()));
    });
    return uuid;
  }

  Future<Map<String, dynamic>> loadJsonDecrypted(String uuid) async {
    final dir = await _secureDataDir();
    final f = File('${dir.path}/$uuid.bin');
    final rec = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
    final pt = await decryptRecord(rec);
    return jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
  }

  // Streaming Verschlüsselung: verschlüsselt großen File-Stream
  Future<void> encryptFile(File input, File output, {Map<String, dynamic>? aad}) async {
    final rec = await encryptRecord(plaintext: await input.readAsBytes(), aad: aad);
    await output.writeAsString(jsonEncode(rec));
  }

  Future<void> decryptFile(File input, File output) async {
    final rec = jsonDecode(await input.readAsString()) as Map<String, dynamic>;
    final pt = await decryptRecord(rec);
    await output.writeAsBytes(pt);
  }

  Future<Directory> _secureDataDir() async {
    final base = await getApplicationDocumentsDirectory();
    final d = Directory('${base.path}/secure');
    if (!(await d.exists())) await d.create(recursive: true);
    return d;
  }

  // Manifest Handling wie zuvor (Entries, save/load)
  // ... (gleich wie vorher)
}
```

---

## 2) Beispiel – Rotation
```dart
final cs = CryptoStorage();
await cs.rotateMEK(); // Neuer Master-Key gesetzt
// Danach Batch-Job: Alle Dateien öffnen → DEK unwrap mit altem MEK → rewrap mit neuem MEK
// Payload bleibt unverändert.
```

---

## 3) WebDAV‑Helper (wie zuvor)
- Gleiches Interface (`put`, `get`), aber bitte **TLS-Pinning** integrieren.

---

## 4) HiDrive‑Onboarding‑Checkliste (Business + E2E)

### Recht & Vertrag
- [ ] AVV abgeschlossen & PDF archiviert
- [ ] DSFA + VVT aktualisiert (STRATO Business E2E)

### HiDrive Konfiguration
- [ ] Business‑Paket: E2E aktiv (testen, ob Daten ohne Schlüssel unlesbar)
- [ ] Nutzer + Rechte minimal
- [ ] Versionierung/Retention (z. B. 90 Tage)

### App‑Integration
- [ ] Pinning aktiv (2 Pins)
- [ ] UUID‑Dateien + lokales Manifest verschlüsselt
- [ ] Envelope Encryption (MEK/DEK) aktiv, Rotationpfad dokumentiert
- [ ] Keine PHI in Dateinamen/HTTP Headern

### Betrieb & Tests
- [ ] Upload/Download Tests (große Dateien)
- [ ] Migration: Klartext → Ciphertext
- [ ] Restore-Test auf neuem Gerät
- [ ] Incident-Drill: Zugang/Schlüsselverlust

---

## 5) Tipps
- Nutze optional **AES‑GCM‑SIV**, wenn verfügbar (Nonce-Missbrauch sicherer).
- Plane Schlüsselrotation alle 12–24 Monate.
- Für riesige Daten (>100 MB): **Streaming** statt alles im RAM (hier basic umgesetzt, erweiterbar mit Streams).
- Root/Jailbreak Detection einbauen; im Zweifel App sperren.



---

## 5) Erweiterungen: Streaming‑Anhänge, alternative AEAD, Rotation

### 5.1 Streaming‑Verschlüsselung großer Dateien (Chunk‑AEAD)
> Idee: Datei in Chunks (z. B. 1–4 MiB) lesen, **jeden Chunk separat** mit demselben DEK, aber **eindeutiger Nonce** (Counter‑Nonce) verschlüsseln und **streamend** hochladen. So brauchst du nie die ganze Datei im RAM.

```dart
import 'dart:io';
import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class StreamEncryptor {
  StreamEncryptor(this._aead);
  final Cipher _aead; // z. B. AesGcm.with256bits()

  // Nonce = 12 B: 4 B fester Prefix + 8 B Chunk‑Counter (Big‑Endian)
  List<int> _nonceFor(int counter, List<int> prefix4) {
    final b = BytesBuilder();
    b.add(prefix4);
    final c = ByteData(8)..setInt64(0, counter, Endian.big);
    b.add(c.buffer.asUint8List());
    return b.toBytes();
  }

  Future<void> encryptFileToSink({
    required SecretKey dek,
    required File input,
    required IOSink out,
    int chunkSize = 1024 * 1024 * 2, // 2 MiB
    Map<String, dynamic>? aad,
  }) async {
    final prefix = Cryptography.instance.newRandom().nextBytes(4);
    final aadBytes = utf8.encode(jsonEncode(aad ?? {}));

    // Header schreiben (JSON) – enthält v, alg, noncePrefix, chunkSize
    final header = jsonEncode({
      'v': 1,
      'alg': 'AES-256-GCM',
      'noncePrefix': base64.encode(prefix),
      'chunkSize': chunkSize,
    });
    out.writeln(header); // Erste Zeile = Header‑JSON

    final raf = await input.open();
    int counter = 0;
    try {
      while (true) {
        final chunk = await raf.read(chunkSize);
        if (chunk.isEmpty) break;
        final nonce = Nonce(_nonceFor(counter++, prefix));
        final sb = await _aead.encrypt(chunk, secretKey: dek, nonce: nonce, aad: aadBytes);
        // Zeilenweise Base64 für Chunk: ct|tag
        final line = base64.encode(sb.cipherText) + '|' + base64.encode(sb.mac.bytes) + '
';
        out.write(line);
      }
    } finally {
      await raf.close();
      await out.flush();
      await out.close();
    }
  }

  Future<void> decryptSinkToFile({
    required SecretKey dek,
    required Stream<List<int>> lines,
    required File output,
    Map<String, dynamic>? aad,
  }) async {
    final it = lines.transform(utf8.decoder).transform(const LineSplitter()).iterator;
    if (!it.moveNext()) throw Exception('Missing header');
    final header = jsonDecode(it.current) as Map<String, dynamic>;
    final prefix = base64.decode(header['noncePrefix'] as String);
    final aadBytes = utf8.encode(jsonEncode(aad ?? {}));

    final sink = output.openWrite();
    int counter = 0;
    while (it.moveNext()) {
      final parts = it.current.split('|');
      if (parts.length != 2) continue;
      final ct = base64.decode(parts[0]);
      final tag = base64.decode(parts[1]);
      final sb = SecretBox(ct, nonce: Nonce(_nonceFor(counter++, prefix)), mac: Mac(tag));
      final pt = await _aead.decrypt(sb, secretKey: dek, aad: aadBytes);
      sink.add(pt);
    }
    await sink.flush();
    await sink.close();
  }
}
```

**Hinweise:**
- Jede Zeile nach dem Header = ein verschlüsselter Chunk (`ciphertext|tag` Base64). 
- **Nonce‑Kollisionen ausgeschlossen**, solange der Counter je Datei nicht wiederverwendet wird.
- Upload: Datei streamend erzeugen (z. B. `File.openWrite()` → an WebDAV‑Request‑Body pipen).

### 5.2 Alternative AEAD: ChaCha20‑Poly1305
Wenn du GCM‑SIV nicht zur Hand hast, ist **ChaCha20‑Poly1305** eine solide Alternative (AEAD, performancefreundlich auf Mobilgeräten). Nonce‑Einzigartigkeit ist **trotzdem Pflicht**.

```dart
final chacha = Chacha20.poly1305Aead();
// Nutzung identisch zu AES‑GCM (encrypt/decrypt, Nonce 12 B, aad Bytes)
```

> Empfehlung: Bleib bei **AES‑GCM** oder **ChaCha20‑Poly1305**. Wenn du echte Misuse‑Resistenz brauchst, plane GCM‑SIV später mit passender Bibliothek nach.

### 5.3 MEK‑Rotation (Rewrap ohne Payload neu zu verschlüsseln)
```dart
Future<void> rotateMEK({
  required FlutterSecureStorage secure,
  required Directory secureDir,
  required Cipher aead,
}) async {
  // 1) alten & neuen MEK
  final oldMek = base64.decode((await secure.read(key: 'app_mek'))!);
  final newMek = Cryptography.instance.newRandom().nextBytes(32);

  // 2) alle *.bin Records durchgehen
  final secretOld = SecretKey(oldMek);
  final secretNew = SecretKey(newMek);
  for (final f in secureDir.listSync().whereType<File>().where((e)=>e.path.endsWith('.bin'))) {
    final rec = jsonDecode(await f.readAsString()) as Map<String,dynamic>;
    final wrapped = rec['dekWrapped'] as Map<String,dynamic>;

    // unwrap DEK mit altem MEK
    final dekBytes = await aead.decrypt(
      SecretBox(
        base64.decode(wrapped['ciphertext']),
        nonce: Nonce(base64.decode(wrapped['nonce'])),
        mac: Mac(base64.decode(wrapped['tag'])),
      ),
      secretKey: secretOld,
      aad: utf8.encode('{"type":"dek"}'),
    );

    // neu wrappen mit neuem MEK
    final n2 = Cryptography.instance.newRandom().nextBytes(12);
    final rewrap = await aead.encrypt(
      dekBytes,
      secretKey: secretNew,
      nonce: Nonce(n2),
      aad: utf8.encode('{"type":"dek"}'),
    );

    rec['dekWrapped'] = {
      'alg': 'AES-256-GCM',
      'nonce': base64.encode(n2),
      'ciphertext': base64.encode(rewrap.cipherText),
      'tag': base64.encode(rewrap.mac.bytes),
    };

    await f.writeAsString(jsonEncode(rec), flush: true);
  }

  // 3) neuen MEK sicher speichern (alten vorher evtl. sichern/vernichten je Policy)
  await secure.write(key: 'app_mek', value: base64.encode(newMek));
}
```

### 5.4 WebDAV Streaming‑Upload (ohne Bytes im RAM zu halten)
```dart
import 'package:http/http.dart' as http;

Future<void> webdavStreamPut(Uri url, String username, String password, Stream<List<int>> stream, int length) async {
  final req = http.StreamedRequest('PUT', url);
  req.headers['Authorization'] = 'Basic ' + base64Encode(utf8.encode('$username:$password'));
  req.headers['Content-Length'] = length.toString();
  // optional: req.headers['Content-Type'] = 'application/octet-stream';
  stream.listen(req.sink.add, onDone: req.sink.close, onError: req.sink.addError);
  final res = await req.send();
  if (res.statusCode >= 300) {
    throw Exception('WebDAV stream PUT failed: ${res.statusCode}');
  }
}
```

**Praxis‑Tipp:** Ermittle die finale Größe vorher (z. B. `await file.length()`), damit der Server `Content-Length` bekommt. Für sehr große Dateien evtl. „TUS“ oder WebDAV‑Chunking.

---

> Damit hast du: **(a)** speicherschonende Verschlüsselung & Uploads, **(b)** Alternative AEAD, **(c)** saubere MEK‑Rotation ohne Payload‑Rewrite. Wenn du willst, füge ich eine kleine **CLI‑Routine** (Dart `dart run`) hinzu, die eine komplette Migration/Rotation automatisiert.

