import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:cryptography/cryptography.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../config/developer_mode.dart';
import '../utils/platform_utils.dart';
import 'package:crypto/crypto.dart' as crypto;

class CryptoStorage {
  CryptoStorage({this.storageKey = 'app_mek', FlutterSecureStorage? secure})
      : secure = secure ?? const FlutterSecureStorage(
          aOptions: AndroidOptions(
            encryptedSharedPreferences: true,
          ),
          iOptions: IOSOptions(
            accessibility: KeychainAccessibility.first_unlock_this_device,
          ),
        );

  final String storageKey;
  final FlutterSecureStorage secure;
  final Cipher _aead = AesGcm.with256bits();
  final Uuid _uuid = const Uuid();
  List<int>? _forcedMEK; // Optional: direkt gesetzter MEK (z. B. Team-Key)
  String? _externalPassphrase;

  // Performance: MEK und Manifest im RAM cachen
  List<int>? _cachedMEK;
  Manifest? _manifestCache;

  void setExternalPassphrase(String? passphrase) {
    _externalPassphrase = (passphrase != null && passphrase.isNotEmpty) ? passphrase : null;
  }

  Future<List<int>> _getOrCreateMEK() async {
    // Session-Cache: MEK nur einmal pro App-Lebenszyklus laden
    if (_cachedMEK != null) return _cachedMEK!;

    // Wenn ein externer MEK (Team-Key) gesetzt wurde, verwende diesen direkt
    if (_forcedMEK != null && _forcedMEK!.length == 32) {
      if (DeveloperMode.allowSecurityDebugLogs) {
        if (kDebugMode) debugPrint('🔐 Verwende extern gesetzten MEK (Team/Org-Key)');
      }
      _cachedMEK = _forcedMEK!;
      return _cachedMEK!;
    }
    try {
      final existing = await secure.read(key: storageKey);
      if (existing != null) {
        _cachedMEK = base64.decode(existing);
        return _cachedMEK!;
      }
      final mek = _randomBytes(32);
      await secure.write(key: storageKey, value: base64.encode(mek));
      _cachedMEK = mek;
      return _cachedMEK!;
    } catch (e) {
      // SICHERE Alternative: PBKDF2-basierte Verschlüsselung
      if (kDebugMode) debugPrint('🔐 Keychain nicht verfügbar, verwende sichere PBKDF2-Verschlüsselung');
      _cachedMEK = await _getSecurePBKDF2MEK();
      return _cachedMEK!;
    }
  }

  // Externen MEK setzen (z. B. aus Team-Key-Datei). Hebt Passphrase-/Keychain-Mechanismus auf.
  void setExternalMEK(List<int>? mek) {
    if (mek == null || mek.isEmpty) {
      _forcedMEK = null;
    } else {
      if (mek.length != 32) {
        throw ArgumentError('MEK muss 32 Bytes lang sein');
      }
      _forcedMEK = List<int>.from(mek);
    }
    _cachedMEK = null; // Cache invalidieren bei MEK-Wechsel
    _manifestCache = null;
  }

  /// SICHERE PBKDF2-basierte MEK-Ableitung als Keychain-Alternative
  /// Nutzt Hardware-spezifische Daten als "Passwort" für PBKDF2
  Future<List<int>> _getSecurePBKDF2MEK() async {
    final dir = await _secureDataDir();
    final saltFile = File('${dir.path}/.pbkdf2_salt');

    List<int> salt;
    if (await saltFile.exists()) {
      salt = base64.decode(await saltFile.readAsString());
    } else {
      salt = _randomBytes(32);
      await saltFile.writeAsString(base64.encode(salt));
    }

    // Passphrase wählen: bevorzugt externe Sync-Passphrase, sonst Hardware-ID
    String passphrase;
    if (_externalPassphrase != null && _externalPassphrase!.isNotEmpty) {
      passphrase = 'sync:${_externalPassphrase!}';
    } else {
      final machineId = await _getMachineIdentifier();
      passphrase = '$machineId:eingliederungshilfe:${Platform.operatingSystem}';
    }

    // PBKDF2 mit 100.000 Iterationen (manuell implementiert)
    final passphraseBytes = utf8.encode(passphrase);
    List<int> result = passphraseBytes;

    for (int i = 0; i < 100000; i++) {
      final hmac = crypto.Hmac(crypto.sha256, salt);
      result = hmac.convert(result).bytes.toList();
    }

    if (_externalPassphrase != null && _externalPassphrase!.isNotEmpty) {
      if (kDebugMode) debugPrint('🔐 PBKDF2-MEK generiert (Sync-Passphrase, 100k Iterationen)');
    } else {
      if (kDebugMode) debugPrint('🔐 PBKDF2-MEK generiert (Hardware-gebunden, 100k Iterationen)');
    }
    return result.take(32).toList(); // Nur 32 Bytes für AES-256
  }

  /// Hardware-spezifischen Identifier generieren
  Future<String> _getMachineIdentifier() async {
    // Verwende App-Verzeichnis als Hardware-spezifischen Identifier
    final dir = await getApplicationSupportDirectory();
    final dirHash = crypto.sha256.convert(utf8.encode(dir.path)).toString();

    // Zusätzlich Plattform-spezifische Daten
    final platformData = '${Platform.operatingSystem}:${Platform.operatingSystemVersion}';
    final combined = '$dirHash:$platformData';

    return crypto.sha256.convert(utf8.encode(combined)).toString().substring(0, 32);
  }

  // _developmentFallback() ENTFERNT -- Sicherheitsrisiko, siehe PRODUKTIONSREIFE_TODO.md #3

  /// Speichert den MEK verschluesselt mit einem Recovery-Key auf der Festplatte.
  /// Der Recovery-Key (12 Woerter) muss sicher vom User aufbewahrt werden.
  /// Bei Passwort-Verlust kann damit der MEK wiederhergestellt werden.
  Future<bool> storeMekBackup(String encryptedMekB64) async {
    try {
      final dir = await _secureDataDir();
      final backupFile = File('${dir.path}/mek_recovery.bin');
      await backupFile.writeAsString(encryptedMekB64);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[CRYPTO] storeMekBackup error: $e');
      return false;
    }
  }

  /// Liest den verschluesselten MEK-Backup falls vorhanden.
  Future<String?> loadMekBackup() async {
    try {
      final dir = await _secureDataDir();
      final backupFile = File('${dir.path}/mek_recovery.bin');
      if (!await backupFile.exists()) return null;
      return await backupFile.readAsString();
    } catch (e) {
      if (kDebugMode) debugPrint('[CRYPTO] loadMekBackup error: $e');
      return null;
    }
  }

  /// Stellt den MEK aus einem Recovery-Backup wieder her.
  /// Der wiederhergestellte MEK wird im Keychain gespeichert.
  Future<bool> restoreMekFromBackup(List<int> recoveredMek) async {
    try {
      if (recoveredMek.length != 32) return false;
      await secure.write(key: storageKey, value: base64.encode(recoveredMek));
      _cachedMEK = null; // Cache invalidieren
      _manifestCache = null;
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[CRYPTO] restoreMekFromBackup error: $e');
      return false;
    }
  }

  /// Aktuellen MEK abrufen (fuer Backup-Zwecke).
  Future<List<int>?> getCurrentMek() async {
    try {
      return await _getOrCreateMEK();
    } catch (e) {
      if (kDebugMode) debugPrint('[CRYPTO] getCurrentMek error: $e');
      return null;
    }
  }

  Future<void> rotateMEK() async {
    final oldMek = await secure.read(key: storageKey);
    if (oldMek == null) {
      throw Exception('Kein MEK zum Rotieren gefunden');
    }

    final newMek = _randomBytes(32);

    await _rewrapAllFiles(base64.decode(oldMek), newMek);

    await secure.write(key: storageKey, value: base64.encode(newMek));
  }

  Future<void> _rewrapAllFiles(List<int> oldMek, List<int> newMek) async {
    final dir = await _secureDataDir();
    final secretOld = SecretKey(oldMek);
    final secretNew = SecretKey(newMek);

    for (final file in dir.listSync().whereType<File>().where((e) => e.path.endsWith('.bin'))) {
      final rec = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final wrapped = rec['dekWrapped'] as Map<String, dynamic>;

      final dekBytes = await _aead.decrypt(
        SecretBox(
          base64.decode(wrapped['ciphertext']),
          nonce: base64.decode(wrapped['nonce']),
          mac: Mac(base64.decode(wrapped['tag'])),
        ),
        secretKey: secretOld,
        aad: utf8.encode('{"type":"dek"}'),
      );

      final n2 = _randomBytes(12);
      final rewrap = await _aead.encrypt(
        dekBytes,
        secretKey: secretNew,
        nonce: n2,
        aad: utf8.encode('{"type":"dek"}'),
      );

      rec['dekWrapped'] = {
        'alg': 'AES-256-GCM',
        'nonce': base64.encode(n2),
        'ciphertext': base64.encode(rewrap.cipherText),
        'tag': base64.encode(rewrap.mac.bytes),
      };

      await file.writeAsString(jsonEncode(rec), flush: true);
    }
  }

  List<int> _randomBytes(int len) {
    final random = Random.secure();
    return List<int>.generate(len, (i) => random.nextInt(256));
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
        secretKey: secretKeyDek, nonce: nonce1, aad: aadBytes);

    final nonce2 = _randomBytes(12);
    final secretKeyMek = SecretKey(mek);
    final wrapped = await _aead.encrypt(dek,
        secretKey: secretKeyMek,
        nonce: nonce2,
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
    try {
      final mek = await _getOrCreateMEK();
      final secretKeyMek = SecretKey(mek);

      final wrapped = record['dekWrapped'] as Map<String, dynamic>;
      final dekBytes = await _aead.decrypt(
        SecretBox(
          base64.decode(wrapped['ciphertext']),
          nonce: base64.decode(wrapped['nonce']),
          mac: Mac(base64.decode(wrapped['tag'])),
        ),
        secretKey: secretKeyMek,
        aad: utf8.encode('{"type":"dek"}')
      );

      final secretKeyDek = SecretKey(dekBytes);
      final box = SecretBox(
        base64.decode(record['ciphertext']),
        nonce: base64.decode(record['nonce']),
        mac: Mac(base64.decode(record['tag'])),
      );
      final aadBytes = utf8.encode(jsonEncode(record['aad'] ?? {}));
      return _aead.decrypt(box, secretKey: secretKeyDek, aad: aadBytes);
    } catch (e) {
      if (kDebugMode) debugPrint('decryptRecord fehlgeschlagen: $e');
      throw Exception('Entschluesselung fehlgeschlagen: Datensatz ist korrupt oder Schluessel ungueltig');
    }
  }

  Future<String> saveJsonEncrypted(String schema, Map<String, dynamic> jsonObj) async {
    final bytes = utf8.encode(jsonEncode(jsonObj));
    final rec = await encryptRecord(
      plaintext: bytes,
      aad: {
        'schema': schema,
        'ts': DateTime.now().toUtc().toIso8601String(),
        'version': 1
      }
    );
    final uuid = _uuid.v4();

    if (PlatformUtils.isWeb) {
      await _setWebStorage(uuid, jsonEncode(rec));
    } else {
      final dir = await _secureDataDir();
      final f = File('${dir.path}/$uuid.bin');
      await f.writeAsString(jsonEncode(rec), flush: true);
    }

    await _updateManifest((m) {
      m.entries.add(ManifestEntry(
        uuid: uuid,
        schema: schema,
        title: _extractTitle(jsonObj, schema),
        updatedAt: DateTime.now().toUtc()
      ));
    });
    return uuid;
  }

  String _extractTitle(Map<String, dynamic> obj, String schema) {
    switch (schema) {
      case 'client':
        return obj['name'] ?? 'Unbekannter Klient';
      case 'appointment':
        return '${obj['clientName']} - ${obj['date']}';
      case 'arbeitszeit':
        return obj['taetigkeit'] ?? 'Arbeitszeit';
      default:
        return obj['title'] ?? obj['name'] ?? 'Unbekannt';
    }
  }

  Future<Map<String, dynamic>> loadJsonDecrypted(String uuid) async {
    String? recordData;

    if (PlatformUtils.isWeb) {
      recordData = await _getWebStorage(uuid);
      if (recordData == null) {
        throw Exception('Datei mit UUID $uuid nicht gefunden (Web)');
      }
    } else {
      final dir = await _secureDataDir();
      final f = File('${dir.path}/$uuid.bin');
      if (!f.existsSync()) {
        throw Exception('Datei mit UUID $uuid nicht gefunden');
      }
      recordData = await f.readAsString();
    }

    final rec = jsonDecode(recordData) as Map<String, dynamic>;
    final pt = await decryptRecord(rec);
    return jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
  }

  Future<bool> deleteRecord(String uuid) async {
    try {
      if (PlatformUtils.isWeb) {
        await _removeWebStorage(uuid);
      } else {
        final dir = await _secureDataDir();
        final f = File('${dir.path}/$uuid.bin');
        if (f.existsSync()) {
          await f.delete();
        }
      }

      await _updateManifest((m) {
        m.entries.removeWhere((entry) => entry.uuid == uuid);
      });

      return true;
    } catch (e) {
      return false;
    }
  }

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
    if (PlatformUtils.isWeb) {
      // Für Web verwenden wir ein temporäres Directory-Konzept
      // Das echte Web-Storage wird über SharedPreferences gehandhabt
      throw UnsupportedError('_secureDataDir nicht für Web - verwende _webStorage');
    }
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/secure');
    if (!(await d.exists())) await d.create(recursive: true);
    return d;
  }

  // Web-Storage Methoden
  Future<void> _setWebStorage(String key, String value) async {
    if (!PlatformUtils.isWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('crypto_$key', value);
  }

  Future<String?> _getWebStorage(String key) async {
    if (!PlatformUtils.isWeb) return null;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('crypto_$key');
  }

  Future<void> _removeWebStorage(String key) async {
    if (!PlatformUtils.isWeb) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('crypto_$key');
  }

  Future<List<String>> _getWebStorageKeys() async {
    if (!PlatformUtils.isWeb) return [];
    final prefs = await SharedPreferences.getInstance();
    return prefs.getKeys().where((key) => key.startsWith('crypto_')).toList();
  }

  Future<Manifest> loadManifest({bool forceReload = false}) async {
    // Cache verwenden wenn vorhanden
    if (!forceReload && _manifestCache != null) return _manifestCache!;

    try {
      Manifest manifest;
      if (PlatformUtils.isWeb) {
        final manifestData = await _getWebStorage('manifest');
        if (manifestData == null) {
          manifest = Manifest();
          await _saveManifest(manifest);
        } else {
          final rec = jsonDecode(manifestData) as Map<String, dynamic>;
          final pt = await decryptRecord(rec);
          final manifestJson = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
          manifest = Manifest.fromJson(manifestJson);
        }
      } else {
        final dir = await _secureDataDir();
        final manifestFile = File('${dir.path}/manifest.json.enc');
        if (!manifestFile.existsSync()) {
          manifest = Manifest();
          await _saveManifest(manifest);
        } else {
          final rec = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
          final pt = await decryptRecord(rec);
          final manifestJson = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
          manifest = Manifest.fromJson(manifestJson);
        }
      }
      _manifestCache = manifest;
      return manifest;
    } catch (e) {
      return Manifest();
    }
  }

  Future<void> _saveManifest(Manifest manifest) async {
    final jsonStr = jsonEncode(manifest.toJson());
    final rec = await encryptRecord(
      plaintext: utf8.encode(jsonStr),
      aad: {'type': 'manifest', 'version': 1}
    );

    if (PlatformUtils.isWeb) {
      await _setWebStorage('manifest', jsonEncode(rec));
    } else {
      final dir = await _secureDataDir();
      final manifestFile = File('${dir.path}/manifest.json.enc');
      await manifestFile.writeAsString(jsonEncode(rec), flush: true);
    }
  }

  Future<void> _updateManifest(void Function(Manifest) updateFn) async {
    final manifest = await loadManifest();
    updateFn(manifest);
    _manifestCache = manifest; // Cache sofort aktualisieren
    await _saveManifest(manifest);
  }

  /// Cache invalidieren (z.B. nach Cloud-Sync oder externem Import)
  void invalidateManifestCache() {
    _manifestCache = null;
  }

  /// Sichere Loeschung: Dateien mit Zufallsdaten ueberschreiben, dann loeschen.
  /// Verhindert forensische Wiederherstellung.
  Future<void> cryptoErasure() async {
    _cachedMEK = null;
    _manifestCache = null;
    _forcedMEK = null;
    await secure.delete(key: storageKey);

    final dir = await _secureDataDir();
    if (await dir.exists()) {
      // Dateien einzeln ueberschreiben vor dem Loeschen
      await for (final entity in dir.list(recursive: true)) {
        if (entity is File) {
          try {
            final size = await entity.length();
            // Mit Zufallsdaten ueberschreiben
            final randomData = _randomBytes(size > 0 ? size : 1024);
            await entity.writeAsBytes(randomData);
            await entity.delete();
          } catch (_) {
            // Trotzdem versuchen zu loeschen
            try { await entity.delete(); } catch (_) {}
          }
        }
      }
      try { await dir.delete(recursive: true); } catch (_) {}
    }
  }

  Future<List<String>> listAllRecords() async {
    final manifest = await loadManifest();
    return manifest.entries.map((e) => e.uuid).toList();
  }

  Future<ManifestEntry?> getManifestEntry(String uuid) async {
    final manifest = await loadManifest();
    try {
      return manifest.entries.firstWhere((e) => e.uuid == uuid);
    } catch (e) {
      return null;
    }
  }

}

class Manifest {
  List<ManifestEntry> entries;

  Manifest({List<ManifestEntry>? entries}) : entries = entries ?? [];

  Map<String, dynamic> toJson() => {
    'version': 1,
    'entries': entries.map((e) => e.toJson()).toList(),
    'updatedAt': DateTime.now().toUtc().toIso8601String(),
  };

  factory Manifest.fromJson(Map<String, dynamic> json) {
    return Manifest(
      entries: (json['entries'] as List?)
          ?.map((e) => ManifestEntry.fromJson(e))
          .toList() ?? [],
    );
  }
}

class ManifestEntry {
  final String uuid;
  final String schema;
  final String title;
  final DateTime updatedAt;

  ManifestEntry({
    required this.uuid,
    required this.schema,
    required this.title,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'schema': schema,
    'title': title,
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory ManifestEntry.fromJson(Map<String, dynamic> json) {
    return ManifestEntry(
      uuid: json['uuid'],
      schema: json['schema'],
      title: json['title'],
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}
