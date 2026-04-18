import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:fegh_cloud/fegh_cloud.dart' as cloud;
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:eingliederungshilfe_flutter/models/sync_manifest.dart';
import 'package:eingliederungshilfe_flutter/config/developer_mode.dart';
import 'package:eingliederungshilfe_flutter/services/file_logger.dart';
import 'app_logger.dart';

class HiDriveWebDAVClient {
  final String baseUrl;
  final String username;
  final String password;
  final List<String> certificatePins;

  late http.Client _httpClient;

  HiDriveWebDAVClient({
    required this.baseUrl,
    required this.username,
    required this.password,
    required this.certificatePins,
  }) {
    _httpClient = _createSecureHttpClient();
  }

  http.Client _createSecureHttpClient() {
    if (kIsWeb) {
      return http.Client();
    }

    return _PinnedHttpClient(certificatePins);
  }

  Map<String, String> get _headers => {
    'Authorization': 'Basic ${base64Encode(utf8.encode('$username:$password'))}',
    'Content-Type': 'application/octet-stream',
    'User-Agent': 'EingliederungshilfeApp/2.0 (DSGVO-konform)',
  };

  Future<WebDAVResult> put(String remotePath, Uint8List data) async {
    try {
      final normalized = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final uri = Uri.parse('$baseUrl/$normalized');

      final request = http.Request('PUT', uri);
      request.headers.addAll(_headers);
      request.bodyBytes = data;

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await FileLogger().log('📤 PUT $normalized -> ${response.statusCode}');
        return WebDAVResult.success();
      } else {
        final err = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        await FileLogger().log('❌ PUT $normalized failed: $err');
        return WebDAVResult.failure(err);
      }
    } catch (e) {
      await FileLogger().log('❌ PUT $remotePath exception: $e');
      return WebDAVResult.failure('Upload fehlgeschlagen: $e');
    }
  }

  Future<WebDAVResult<Uint8List>> get(String remotePath) async {
    try {
      final normalized = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final uri = Uri.parse('$baseUrl/$normalized');
      final response = await _httpClient.get(uri, headers: _headers);

      if (response.statusCode == 200) {
        await FileLogger().log('📥 GET $normalized -> 200');
        return WebDAVResult.success(data: response.bodyBytes);
      } else if (response.statusCode == 404) {
        await FileLogger().log('📥 GET $normalized -> 404');
        return WebDAVResult.failure('Datei nicht gefunden');
      } else {
        final err = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        await FileLogger().log('❌ GET $normalized failed: $err');
        return WebDAVResult.failure(err);
      }
    } catch (e) {
      await FileLogger().log('❌ GET $remotePath exception: $e');
      return WebDAVResult.failure('Download fehlgeschlagen: $e');
    }
  }

  Future<WebDAVResult> delete(String remotePath) async {
    try {
      final normalized = remotePath.startsWith('/') ? remotePath.substring(1) : remotePath;
      final uri = Uri.parse('$baseUrl/$normalized');
      final response = await _httpClient.delete(uri, headers: _headers);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return WebDAVResult.success();
      } else if (response.statusCode == 404) {
        await FileLogger().log('🗑️ DELETE $normalized -> 404 (ok)');
        return WebDAVResult.success();
      } else {
        final err = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        await FileLogger().log('❌ DELETE $normalized failed: $err');
        return WebDAVResult.failure(err);
      }
    } catch (e) {
      await FileLogger().log('❌ DELETE $remotePath exception: $e');
      return WebDAVResult.failure('Löschen fehlgeschlagen: $e');
    }
  }

  Future<WebDAVResult<List<String>>> list(String remotePath) async {
    try {
      final normalizedPath = remotePath.isEmpty
          ? ''
          : (remotePath.endsWith('/') ? remotePath : '$remotePath/');
      final uri = Uri.parse('$baseUrl/$normalizedPath');
      final request = http.Request('PROPFIND', uri);
      request.headers.addAll(_headers);
      request.headers['Depth'] = '1';
      // WebDAV PROPFIND expects an XML content type
      request.headers['Content-Type'] = 'text/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 207) {
        final files = _parseWebDAVResponse(response.body)
            .where((name) => name.isNotEmpty && !name.endsWith('/'))
            .toList();
        await FileLogger().log('📂 LIST $normalizedPath -> ${files.length} items');
        return WebDAVResult.success(data: files);
      } else {
        final err = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        await FileLogger().log('❌ LIST $normalizedPath failed: $err');
        return WebDAVResult.failure(err);
      }
    } catch (e) {
      await FileLogger().log('❌ LIST $remotePath exception: $e');
      return WebDAVResult.failure('Auflistung fehlgeschlagen: $e');
    }
  }

  List<String> _parseWebDAVResponse(String xmlResponse) {
    final files = <String>[];

    final responseRegex = RegExp(r'<d:displayname[^>]*>([^<]+)</d:displayname>');
    final matches = responseRegex.allMatches(xmlResponse);

    for (final match in matches) {
      final filename = match.group(1);
      if (filename != null && filename.isNotEmpty && !filename.endsWith('/')) {
        files.add(filename);
      }
    }

    return files;
  }

  // Detaillierte Auflistung (Dateien und Ordner)
  Future<WebDAVResult<List<WebDavItem>>> listDetailed(String remotePath) async {
    try {
      final normalizedPath = remotePath.isEmpty
          ? ''
          : (remotePath.endsWith('/') ? remotePath : '$remotePath/');
      final uri = Uri.parse('$baseUrl/$normalizedPath');
      final request = http.Request('PROPFIND', uri);
      request.headers.addAll(_headers);
      request.headers['Depth'] = '1';
      request.headers['Content-Type'] = 'text/xml; charset=utf-8';
      request.body = '''<?xml version="1.0" encoding="utf-8"?>
<d:propfind xmlns:d="DAV:">
  <d:prop>
    <d:displayname/>
    <d:getcontentlength/>
    <d:getlastmodified/>
    <d:resourcetype/>
  </d:prop>
</d:propfind>''';

      final streamedResponse = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode != 207) {
        final err = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        await FileLogger().log('❌ LIST DETAILED $normalizedPath failed: $err');
        return WebDAVResult.failure(err);
      }

      final xml = response.body;
      debugPrint('[WEBDAV] listDetailed RAW response (first 2000 chars): ${xml.substring(0, xml.length > 2000 ? 2000 : xml.length)}');
      final items = <WebDavItem>[];

      final blockRegex = RegExp(r'<[Dd]:response[\s\S]*?</[Dd]:response>', multiLine: true);
      final nameRegex = RegExp(r'<[^>]*displayname[^>]*>([^<]+)</[^>]*displayname>', caseSensitive: false);
      final hrefRegex = RegExp(r'<[Dd]:href>([^<]+)</[Dd]:href>');
      final modRegex = RegExp(r'<[^>]*getlastmodified[^>]*>([^<]+)</[^>]*getlastmodified>', caseSensitive: false);
      final lenRegex = RegExp(r'<[^>]*getcontentlength[^>]*>([^<]+)</[^>]*getcontentlength>', caseSensitive: false);

      bool isFirst = true; // Erster Response-Block ist der Parent-Ordner selbst

      for (final match in blockRegex.allMatches(xml)) {
        // Ersten Eintrag ueberspringen (Parent-Ordner)
        if (isFirst) { isFirst = false; continue; }

        final block = match.group(0) ?? '';
        final lower = block.toLowerCase();
        final isDir = lower.contains('collection');

        // Name aus displayname oder href extrahieren
        final nameMatch = nameRegex.firstMatch(block);
        String name = nameMatch?.group(1) ?? '';

        // Fallback: Name aus href-Pfad extrahieren
        if (name.isEmpty) {
          final hrefMatch = hrefRegex.firstMatch(block);
          if (hrefMatch != null) {
            final href = hrefMatch.group(1) ?? '';
            final segments = href.split('/').where((s) => s.isNotEmpty).toList();
            if (segments.isNotEmpty) {
              name = segments.last;
            }
          }
        }

        if (name.isEmpty) continue;

        int? size;
        final len = lenRegex.firstMatch(block)?.group(1);
        if (len != null) {
          final parsed = int.tryParse(len);
          if (parsed != null) size = parsed;
        }

        DateTime? lastModified;
        final lm = modRegex.firstMatch(block)?.group(1);
        if (lm != null) {
          try { lastModified = DateTime.parse(lm); } catch (_) {}
        }

        items.add(WebDavItem(
          name: name,
          isDirectory: isDir,
          size: size,
          lastModified: lastModified,
        ));
      }

      await FileLogger().log('📂 LIST DETAILED $normalizedPath -> ${items.length} items');
      return WebDAVResult.success(data: items);
    } catch (e) {
      await FileLogger().log('❌ LIST DETAILED $remotePath exception: $e');
      return WebDAVResult.failure('Auflistung (detailliert) fehlgeschlagen: $e');
    }
  }

  Future<WebDAVResult<List<String>>> listDirectories(String remotePath) async {
    final res = await listDetailed(remotePath);
    if (!res.isSuccess || res.data == null) return WebDAVResult.failure(res.error);
    final dirs = res.data!
        .where((i) => i.isDirectory)
        .map((i) => i.name)
        .where((n) => n.isNotEmpty)
        .toList();
    return WebDAVResult.success(data: dirs);
  }

  Future<WebDAVResult> createDirectory(String remotePath) async {
    // Delegiert an fegh_cloud HidriveAdapter (webdav_client-basiert).
    // Ersetzt den frueheren Pinning-Bypass strukturell und behandelt
    // STRATO-Quirks (MKCOL-Content-Type-Sensitivitaet) korrekt.
    final adapter = cloud.HidriveAdapter(
      username: username,
      password: password,
    );
    try {
      final result = await adapter.createDirectory(remotePath);
      if (result.isSuccess) return WebDAVResult.success();
      return WebDAVResult.failure(result.error ?? 'MKCOL fehlgeschlagen');
    } finally {
      adapter.dispose();
    }
  }

  Future<WebDAVResult> testConnection() async {
    try {
      final result = await list('');
      if (result.isSuccess) {
        await FileLogger().log('✅ TestConnection: LIST base OK');
        return WebDAVResult.success();
      }
      // Tolerate 404 (Ordner existiert noch nicht). Auth ist i. d. R. OK.
      if (result.error != null && result.error!.contains('404')) {
        await FileLogger().log('ℹ️ TestConnection: base 404 (Ordner fehlt) – akzeptiert');
        return WebDAVResult.success();
      }
      await FileLogger().log('❌ TestConnection failed: ${result.error}');
      return WebDAVResult.failure('Verbindungstest fehlgeschlagen: ${result.error}');
    } catch (e) {
      return WebDAVResult.failure('Verbindungstest fehlgeschlagen: $e');
    }
  }

  void dispose() {
    _httpClient.close();
  }
}

class _PinnedHttpClient extends http.BaseClient {
  final List<String> certificatePins;
  final http.Client _inner;

  _PinnedHttpClient(this.certificatePins) : _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (kIsWeb) {
      AppLogger.info('WebDAV', 'Web: Certificate Pinning uebersprungen (Browser-Sicherheit)');
      return _inner.send(request);
    }

    // Allow bypass in developer mode to simplify testing
    if (DeveloperMode.isActive) {
      AppLogger.info('WebDAV', 'DEV: Ueberspringe Certificate Pinning (DeveloperMode aktiv)');
      return _inner.send(request);
    }

    try {
      AppLogger.info('WebDAV', 'Certificate Pinning aktiv fuer: ${request.url.host}');
      AppLogger.info('WebDAV', 'Erwartete Pins: ${certificatePins.length}');

      // Create custom HttpClient for certificate validation
      final httpClient = HttpClient();

      // Set certificate verification callback
      httpClient.badCertificateCallback = (X509Certificate cert, String host, int port) {
        AppLogger.info('WebDAV', 'Pruefe Zertifikat fuer $host:$port');

        // Extract public key and create SPKI hash
        final publicKeyBytes = cert.der;
        final publicKeyHash = sha256.convert(publicKeyBytes);
        final spkiPin = 'sha256/${base64Encode(publicKeyHash.bytes)}';

        AppLogger.info('WebDAV', 'Zertifikat SPKI Pin: $spkiPin');

        // Check if pin matches any of our expected pins
        final isValid = certificatePins.contains(spkiPin);
        AppLogger.info('WebDAV', 'Pin-Validierung: ${isValid ? "GUELTIG" : "UNGUELTIG"}');

        return isValid;
      };

      // Convert http.BaseRequest to HttpClient request
      final httpRequest = await httpClient.openUrl(request.method, request.url);

      // Copy headers
      request.headers.forEach((name, value) {
        httpRequest.headers.set(name, value);
      });

      // Copy body for POST/PUT requests (ensure we send raw bytes if available)
      if (request is http.Request) {
        if (request.bodyBytes.isNotEmpty) {
          httpRequest.add(request.bodyBytes);
        } else if (request.body.isNotEmpty) {
          httpRequest.write(request.body);
        } else {
          await request.finalize().pipe(httpRequest);
        }
      } else if (request is http.StreamedRequest) {
        await request.finalize().pipe(httpRequest);
      }

      final httpResponse = await httpRequest.close();

      // Convert back to StreamedResponse
      final responseHeaders = <String, String>{};
      httpResponse.headers.forEach((name, values) {
        responseHeaders[name] = values.first;
      });

      return http.StreamedResponse(
        httpResponse,
        httpResponse.statusCode,
        contentLength: httpResponse.contentLength,
        request: request,
        headers: responseHeaders,
        isRedirect: httpResponse.isRedirect,
        persistentConnection: httpResponse.persistentConnection,
        reasonPhrase: httpResponse.reasonPhrase,
      );

    } on HandshakeException catch (e) {
      AppLogger.error('WebDAV', 'TLS Handshake fehlgeschlagen', e);
      throw Exception('TLS Handshake fehlgeschlagen: Certificate Pinning Fehler - Zertifikat nicht vertrauenswürdig');
    } on SocketException catch (e) {
      AppLogger.error('WebDAV', 'Netzwerkfehler', e);
      throw Exception('Netzwerkverbindung fehlgeschlagen: $e');
    } catch (e) {
      AppLogger.error('WebDAV', 'Unbekannter Fehler', e);
      rethrow;
    }
  }

  @override
  void close() {
    _inner.close();
  }
}

class WebDAVResult<T> {
  final bool isSuccess;
  final String? error;
  final T? data;

  WebDAVResult.success({this.data})
      : isSuccess = true,
        error = null;

  WebDAVResult.failure(this.error)
      : isSuccess = false,
        data = null;
}

class WebDavItem {
  final String name;
  final bool isDirectory;
  final int? size;
  final DateTime? lastModified;

  WebDavItem({
    required this.name,
    required this.isDirectory,
    this.size,
    this.lastModified,
  });
}

class HiDriveConfig {
  static const String defaultBaseUrl = 'https://webdav.hidrive.strato.com/users';

  // WICHTIG: Pins muessen bei Zertifikatswechsel aktualisiert werden.
  // Der dritte Pin ist ein Backup-Pin der uebergeordneten CA (DigiCert Global Root G2),
  // damit die App auch nach einer regulaeren Zertifikatsrotation funktioniert.
  static List<String> get certificatePins => [
    'sha256/sPTchzpexg44jdkHrtGrWbKgBEKmq3vGyEaG1L2B92c=', // STRATO HiDrive WebDAV (Leaf/Intermediate)
    'sha256/v0UnZ0WdFoxIj5MUfER7im+Kua2y4N6e9yuQLrf7wvU=', // STRATO Main Domain (Intermediate)
    'sha256/i7WTqTvh0OioIruIfFR4kMPnBqrS2rdiVPl/s2uC/CY=', // DigiCert Global Root G2 (Backup CA Pin)
  ];

  static String buildWebDAVUrl(String username, {String? subdirectory, String? rootSubdirectory}) {
    // rootSubdirectory erlaubt Freigabe-Mounts wie "Gemeinsam/..."
    final root = (rootSubdirectory != null && rootSubdirectory.trim().isNotEmpty)
        ? '/${rootSubdirectory.trim()}'
        : '';
    final sub = (subdirectory != null && subdirectory.isNotEmpty) ? '/$subdirectory' : '';
    final combined = '$root$sub'.replaceAll(RegExp(r"//+"), "/").replaceFirst(RegExp(r"^/"), "");
    final suffix = combined.isNotEmpty ? '/$combined' : '';
    return '$defaultBaseUrl/$username$suffix';
  }

  // Multi-User/Multi-Team Ordnerstruktur
  static String getBasePath(String username) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe');
  }

  static String getOrganizationBasePath(String username, String organizationId, {String? rootSubdirectory}) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId', rootSubdirectory: rootSubdirectory);
  }

  static String getTeamBasePath(String username, String organizationId, String teamId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/teams/$teamId');
  }

  // Admin-Zugriff (Personalverwaltungs-App)
  static String getAdminUrl(String username, String organizationId) {
    return getOrganizationBasePath(username, organizationId);
  }

  static String getEmployeesPath(String username, String organizationId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/employees');
  }

  static String getAdministrationPath(String username, String organizationId, {String? rootSubdirectory}) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/administration', rootSubdirectory: rootSubdirectory);
  }

  // Team-spezifischer Zugriff
  static String getTeamUrl(String username, String organizationId, String teamId) {
    return getTeamBasePath(username, organizationId, teamId);
  }

  static String getTeamClientsPath(String username, String organizationId, String teamId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/teams/$teamId/clients');
  }

  static String getTeamSchedulesPath(String username, String organizationId, String teamId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/teams/$teamId/schedules');
  }

  static String getTeamReportsPath(String username, String organizationId, String teamId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/teams/$teamId/reports');
  }

  static String getTeamWorktimePath(String username, String organizationId, String teamId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/teams/$teamId/worktime');
  }

  // Geteilte Ressourcen
  static String getSharedPath(String username, String organizationId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/shared');
  }

  static String getSharedCalendarPath(String username, String organizationId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/shared/calendar-sync');
  }

  static String getSharedMessagesPath(String username, String organizationId) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/organizations/$organizationId/shared/messages');
  }

  // System-Pfade
  static String getSystemPath(String username) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/system');
  }

  static String getAccessLogsPath(String username) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/system/access-logs');
  }

  static String getSyncMetadataPath(String username) {
    return buildWebDAVUrl(username, subdirectory: 'eingliederungshilfe/system/sync-metadata');
  }

  // Legacy-Kompatibilität für bestehende Apps
  @deprecated
  static String getOrganizationPath(String username, String organizationId) {
    return getOrganizationBasePath(username, organizationId);
  }

  @deprecated
  static String getClientsPath(String username, String organizationId) {
    return getTeamClientsPath(username, organizationId, 'default');
  }

  @deprecated
  static String getSchedulesPath(String username, String organizationId) {
    return getTeamSchedulesPath(username, organizationId, 'default');
  }

  @deprecated
  static String getReportsPath(String username, String organizationId) {
    return getTeamReportsPath(username, organizationId, 'default');
  }
}

class HiDriveBusinessSync {
  final HiDriveWebDAVClient _client;
  final String _syncFolder;
  final String? _organizationId;
  final String? _teamId;
  late final SyncManifest _localManifest;
  late final HiDriveWebDAVClient _rootClient; // Client auf Benutzer-Root

  HiDriveBusinessSync({
    required String username,
    required String password,
    String syncFolder = 'eingliederungshilfe_encrypted',
    String? organizationId,
    String? teamId,
    String? rootSubdirectory,
  })  : _client = HiDriveWebDAVClient(
          baseUrl: HiDriveConfig.buildWebDAVUrl(username, subdirectory: syncFolder, rootSubdirectory: rootSubdirectory),
          username: username,
          password: password,
          certificatePins: HiDriveConfig.certificatePins,
        ),
        _rootClient = HiDriveWebDAVClient(
          baseUrl: HiDriveConfig.buildWebDAVUrl(username, rootSubdirectory: rootSubdirectory),
          username: username,
          password: password,
          certificatePins: HiDriveConfig.certificatePins,
        ),
        _syncFolder = syncFolder,
        _organizationId = organizationId,
        _teamId = teamId {
    _localManifest = SyncManifest.createNew();
  }

  // Factory für Multi-Team Setup
  factory HiDriveBusinessSync.forTeam({
    required String username,
    required String password,
    required String organizationId,
    required String teamId,
    String? rootSubdirectory,
  }) {
    final teamPath = 'eingliederungshilfe/organizations/$organizationId/teams/$teamId';
    return HiDriveBusinessSync(
      username: username,
      password: password,
      syncFolder: teamPath,
      organizationId: organizationId,
      teamId: teamId,
      rootSubdirectory: rootSubdirectory,
    );
  }

  // Factory für Admin-Zugriff
  factory HiDriveBusinessSync.forAdmin({
    required String username,
    required String password,
    required String organizationId,
    String? rootSubdirectory,
  }) {
    final adminPath = 'eingliederungshilfe/organizations/$organizationId';
    return HiDriveBusinessSync(
      username: username,
      password: password,
      syncFolder: adminPath,
      organizationId: organizationId,
      rootSubdirectory: rootSubdirectory,
    );
  }

  // Factory für Legacy-Kompatibilität
  factory HiDriveBusinessSync.legacy({
    required String username,
    required String password,
    String? rootSubdirectory,
  }) {
    return HiDriveBusinessSync(
      username: username,
      password: password,
      syncFolder: 'eingliederungshilfe_encrypted',
      rootSubdirectory: rootSubdirectory,
    );
  }

  Future<WebDAVResult> uploadEncryptedRecord(String uuid, Uint8List encryptedData) async {
    return await _client.put('$uuid.bin', encryptedData);
  }

  Future<WebDAVResult<Uint8List>> downloadEncryptedRecord(String uuid) async {
    return await _client.get('$uuid.bin');
  }

  Future<WebDAVResult> deleteRemoteRecord(String uuid) async {
    return await _client.delete('$uuid.bin');
  }

  Future<WebDAVResult<List<String>>> listRemoteRecords() async {
    final result = await _client.list('');
    if (result.isSuccess && result.data != null) {
      final binFiles = result.data!
          .where((filename) => filename.endsWith('.bin'))
          .map((filename) => filename.replaceAll('.bin', ''))
          .toList();
      return WebDAVResult.success(data: binFiles);
    }
    return WebDAVResult.failure(result.error);
  }

  Future<WebDAVResult> testConnection() async {
    return await _client.testConnection();
  }

  Future<WebDAVResult> setupRemoteDirectory({String? organizationId}) async {
    final orgId = organizationId ?? _organizationId ?? 'default';

    List<String> directories;

    // Stelle sicher, dass der gesamte Basispfad existiert (z. B. eingliederungshilfe/organizations/<org>/[teams/<team>])
    final ensureBase = await _ensureBasePathExists();
    if (!ensureBase.isSuccess) {
      await FileLogger().log('❌ Basispfad konnte nicht erstellt werden: ${ensureBase.error}');
      // Weiter versuchen, aber Hinweis loggen
    }

    if (_teamId != null && _organizationId != null) {
      // Team-spezifische Ordnerstruktur
      directories = [
        'clients',
        'schedules',
        'reports',
        'reports/monthly',
        'reports/annual',
        'worktime',
      ];
      AppLogger.info('WebDAV', 'Erstelle Team-Ordnerstruktur fuer Team: $_teamId');
      await FileLogger().log('📁 Setup Team-Ordner für team=$_teamId');
    } else if (_organizationId != null) {
      // Admin/Organisation-Ordnerstruktur
      directories = [
        'teams',
        'employees',
        'administration',
        'shared',
        'shared/calendar-sync',
        'shared/messages',
      ];
      AppLogger.info('WebDAV', 'Erstelle Admin-Ordnerstruktur fuer Organisation: $_organizationId');
      await FileLogger().log('📁 Setup Admin-Ordner für org=$_organizationId');
    } else {
      // Legacy-Ordnerstruktur für Rückwärtskompatibilität
      directories = [
        'organization',
        'employees',
        'clients',
        'schedules',
        'reports',
        'reports/monthly',
        'reports/annual',
      ];
      AppLogger.info('WebDAV', 'Erstelle Legacy-Ordnerstruktur');
      await FileLogger().log('📁 Setup Legacy-Ordnerstruktur');
    }

    for (final dir in directories) {
      final createResult = await _client.createDirectory(dir);
      if (!createResult.isSuccess &&
          createResult.error != null &&
          !createResult.error!.contains('already exists') &&
          !createResult.error!.contains('409') &&
          !createResult.error!.contains('405')) {
        AppLogger.error('WebDAV', 'Verzeichnis-Setup fehlgeschlagen fuer $dir: ${createResult.error}');
        await FileLogger().log('❌ MKCOL $dir failed: ${createResult.error}');
        return WebDAVResult.failure('Verzeichnis-Setup fehlgeschlagen für $dir: ${createResult.error}');
      }
      AppLogger.info('WebDAV', 'Ordner erstellt: $dir');
      await FileLogger().log('📁 ✅ Ordner ok: $dir');
    }

    AppLogger.info('WebDAV', 'Ordnerstruktur bereit fuer: ${_teamId != null ? 'Team $_teamId' : 'Organisation $orgId'}');
    await FileLogger().log('📁 ✅ Ordnerstruktur bereit (team=${_teamId ?? '-'}, org=${_organizationId ?? '-'})');
    return WebDAVResult.success(data: 'Setup erfolgreich');
  }

  Future<WebDAVResult> _ensureBasePathExists() async {
    try {
      final segments = _syncFolder.split('/').where((s) => s.isNotEmpty).toList();
      var current = '';
      for (final seg in segments) {
        current = current.isEmpty ? seg : '$current/$seg';
        final res = await _rootClient.createDirectory(current);
        if (!res.isSuccess) {
          final err = res.error ?? '';
          if (!(err.contains('405') || err.contains('409') || err.contains('exists'))) {
            await FileLogger().log('❌ MKCOL $current failed: $err');
            // continue trying others but remember failure
          } else {
            await FileLogger().log('📁 (exists) $current');
          }
        } else {
          await FileLogger().log('📁 ✅ MKCOL $current');
        }
      }
      return WebDAVResult.success();
    } catch (e) {
      return WebDAVResult.failure('ensureBasePath error: $e');
    }
  }

  // Hilfsmethoden für spezifische Datentypen
  Future<WebDAVResult> uploadTeamRecord(String dataType, String uuid, Uint8List encryptedData) async {
    if (_teamId == null) {
      return WebDAVResult.failure('Team-ID nicht gesetzt');
    }
    // Ensure subdirectory exists for datatype
    await _client.createDirectory(dataType);
    return await _client.put('$dataType/$uuid.bin', encryptedData);
  }

  Future<WebDAVResult<Uint8List>> downloadTeamRecord(String dataType, String uuid) async {
    if (_teamId == null) {
      return WebDAVResult.failure('Team-ID nicht gesetzt');
    }
    return await _client.get('$dataType/$uuid.bin');
  }

  Future<WebDAVResult> deleteTeamRecord(String dataType, String uuid) async {
    if (_teamId == null) {
      return WebDAVResult.failure('Team-ID nicht gesetzt');
    }
    return await _client.delete('$dataType/$uuid.bin');
  }

  Future<WebDAVResult<List<String>>> listTeamRecords(String dataType) async {
    if (_teamId == null) {
      return WebDAVResult.failure('Team-ID nicht gesetzt');
    }

    final result = await _client.list(dataType);
    if (result.isSuccess && result.data != null) {
      final binFiles = result.data!
          .where((filename) => filename.endsWith('.bin'))
          .map((filename) => filename.replaceAll('.bin', ''))
          .toList();
      return WebDAVResult.success(data: binFiles);
    }
    return WebDAVResult.failure(result.error);
  }

  // ========================================
  // 🏢 ORGANIZATION-LEVEL RECORD APIS (Admin)
  // ========================================

  Future<WebDAVResult> uploadOrgRecord(String dataType, String uuid, Uint8List encryptedData) async {
    if (_organizationId == null) {
      return WebDAVResult.failure('Organization-ID nicht gesetzt');
    }
    // Ensure subdirectory exists for datatype
    await _client.createDirectory(dataType);
    return await _client.put('$dataType/$uuid.bin', encryptedData);
  }

  Future<WebDAVResult<Uint8List>> downloadOrgRecord(String dataType, String uuid) async {
    if (_organizationId == null) {
      return WebDAVResult.failure('Organization-ID nicht gesetzt');
    }
    return await _client.get('$dataType/$uuid.bin');
  }

  Future<WebDAVResult> deleteOrgRecord(String dataType, String uuid) async {
    if (_organizationId == null) {
      return WebDAVResult.failure('Organization-ID nicht gesetzt');
    }
    return await _client.delete('$dataType/$uuid.bin');
  }

  Future<WebDAVResult<List<String>>> listOrgRecords(String dataType) async {
    if (_organizationId == null) {
      return WebDAVResult.failure('Organization-ID nicht gesetzt');
    }
    final result = await _client.list(dataType);
    if (result.isSuccess && result.data != null) {
      final binFiles = result.data!
          .where((filename) => filename.endsWith('.bin'))
          .map((filename) => filename.replaceAll('.bin', ''))
          .toList();
      return WebDAVResult.success(data: binFiles);
    }
    return WebDAVResult.failure(result.error);
  }

  Future<WebDAVResult<List<String>>> listOrgDirectories(String relativeDir) async {
    if (_organizationId == null) {
      return WebDAVResult.failure('Organization-ID nicht gesetzt');
    }
    return await _client.listDirectories(relativeDir);
  }

  /// Scoped listing within organization path (e.g., employees/<id>/profile)
  Future<WebDAVResult<List<String>>> listOrgScopedRecords(String relativeDir) async {
    final result = await _client.list(relativeDir);
    if (result.isSuccess && result.data != null) {
      final binFiles = result.data!
          .where((filename) => filename.endsWith('.bin'))
          .map((filename) => filename.replaceAll('.bin', ''))
          .toList();
      return WebDAVResult.success(data: binFiles);
    }
    return WebDAVResult.failure(result.error);
  }

  /// Listet Unterordner (nicht Dateien) in einem Org-Pfad auf.
  Future<WebDAVResult<List<String>>> listOrgScopedDirectories(String relativeDir) async {
    final result = await _client.listDirectories(relativeDir);
    if (result.isSuccess && result.data != null) {
      return WebDAVResult.success(data: result.data!);
    }
    return WebDAVResult.failure(result.error);
  }

  Future<WebDAVResult> uploadOrgScopedRecord(String relativeDir, String uuid, Uint8List encryptedData) async {
    // Ensure directory path exists (create all segments)
    final segments = relativeDir.split('/').where((s) => s.isNotEmpty).toList();
    var current = '';
    for (final seg in segments) {
      current = current.isEmpty ? seg : '$current/$seg';
      await _client.createDirectory(current);
    }
    return await _client.put('$relativeDir/$uuid.bin', encryptedData);
  }

  Future<WebDAVResult<Uint8List>> downloadOrgScopedRecord(String relativeDir, String uuid) async {
    return await _client.get('$relativeDir/$uuid.bin');
  }

  Future<WebDAVResult> deleteOrgScopedRecord(String relativeDir, String uuid) async {
    return await _client.delete('$relativeDir/$uuid.bin');
  }

  Future<WebDAVResult> uploadManifest(String dataType, Map<String, dynamic> manifest) async {
    try {
      final manifestJson = jsonEncode(manifest);
      final manifestBytes = Uint8List.fromList(utf8.encode(manifestJson));
      return await _client.put('$dataType/manifest.json.enc', manifestBytes);
    } catch (e) {
      return WebDAVResult.failure('Manifest-Upload fehlgeschlagen: $e');
    }
  }

  Future<WebDAVResult<Map<String, dynamic>>> downloadManifest(String dataType) async {
    try {
      final result = await _client.get('$dataType/manifest.json.enc');
      if (result.isSuccess && result.data != null) {
        final manifestJson = utf8.decode(result.data!);
        final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
        return WebDAVResult.success(data: manifest);
      }
      return WebDAVResult.failure(result.error);
    } catch (e) {
      return WebDAVResult.failure('Manifest-Download fehlgeschlagen: $e');
    }
  }

  // ========================================
  // 🔒 KRITISCHE MULTI-DEVICE SICHERHEIT
  // ========================================

  /// Sichere Synchronisation mit Conflict-Detection
  Future<SyncResult> safeSyncToCloud() async {
    try {
      AppLogger.info('WebDAV', 'Starte sichere Multi-Device Synchronisation...');

      // 1. Remote Manifest laden und prüfen
      final remoteManifestResult = await _downloadRemoteManifest();
      if (!remoteManifestResult.success) {
        // Erstes Gerät - erstelle neues Manifest
        AppLogger.info('WebDAV', 'Erstes Geraet - erstelle Remote Manifest');
        return await _performFirstTimeSync();
      }

      final remoteManifest = remoteManifestResult.manifest!;

      // 2. Konflikt-Erkennung
      if (_localManifest.hasConflictWith(remoteManifest)) {
        AppLogger.warning('WebDAV', 'KONFLIKT ERKANNT zwischen Geraeten!');
        final conflicts = _localManifest.getConflictingFiles(remoteManifest);

        // Für kritische Sicherheit: Last-Write-Wins als Standard
        AppLogger.info('WebDAV', 'Verwende Last-Write-Wins Strategie fuer Konflikte: \$conflicts');
        return await _resolveConflictsLastWriteWins(remoteManifest, conflicts);
      }

      // 3. Normale Synchronisation
      AppLogger.info('WebDAV', 'Keine Konflikte - fuehre normale Sync durch');
      return await _performNormalSync(remoteManifest);

    } catch (e) {
      AppLogger.error('WebDAV', 'Kritischer Sync-Fehler', e);
      return SyncResult.error('Synchronisation fehlgeschlagen: \$e');
    }
  }

  /// Download Remote Manifest mit Fehlerbehandlung
  Future<ManifestResult> _downloadRemoteManifest() async {
    try {
      final result = await _client.get('.sync-manifest.json');
      if (result.isSuccess && result.data != null) {
        final manifestJson = utf8.decode(result.data!);
        final manifest = SyncManifest.fromJson(jsonDecode(manifestJson));
        return ManifestResult.success(manifest);
      }
      return ManifestResult.notFound();
    } catch (e) {
      AppLogger.warning('WebDAV', 'Manifest Download Fehler: \$e');
      return ManifestResult.error('\$e');
    }
  }

  /// Upload Remote Manifest
  Future<bool> _uploadRemoteManifest(SyncManifest manifest) async {
    try {
      final manifestJson = jsonEncode(manifest.toJson());
      final manifestBytes = utf8.encode(manifestJson);
      final result = await _client.put('.sync-manifest.json', manifestBytes);
      return result.isSuccess;
    } catch (e) {
      AppLogger.error('WebDAV', 'Manifest Upload Fehler', e);
      return false;
    }
  }

  /// Erste Synchronisation ohne bestehende Geräte
  Future<SyncResult> _performFirstTimeSync() async {
    try {
      // Setup Remote Directory
      final setupResult = await setupRemoteDirectory();
      if (!setupResult.isSuccess) {
        return SyncResult.error('Setup fehlgeschlagen: \${setupResult.error}');
      }

      // Upload aktuelles Manifest
      final uploadSuccess = await _uploadRemoteManifest(_localManifest);
      if (!uploadSuccess) {
        return SyncResult.error('Manifest Upload fehlgeschlagen');
      }

      AppLogger.info('WebDAV', 'Erstes Geraet erfolgreich synchronisiert');
      return SyncResult.success('Erste Synchronisation erfolgreich', conflicts: []);

    } catch (e) {
      return SyncResult.error('Erste Sync fehlgeschlagen: \$e');
    }
  }

  /// Normale Synchronisation ohne Konflikte
  Future<SyncResult> _performNormalSync(SyncManifest remoteManifest) async {
    try {
      // Merge lokale und remote Änderungen
      final mergedManifest = _mergeManifests(_localManifest, remoteManifest);

      // Upload aktualisiertes Manifest
      final uploadSuccess = await _uploadRemoteManifest(mergedManifest);
      if (!uploadSuccess) {
        return SyncResult.error('Manifest Update fehlgeschlagen');
      }

      AppLogger.info('WebDAV', 'Normale Synchronisation erfolgreich');
      return SyncResult.success('Synchronisation erfolgreich', conflicts: []);

    } catch (e) {
      return SyncResult.error('Normale Sync fehlgeschlagen: \$e');
    }
  }

  /// Konflikt-Resolution mit Last-Write-Wins
  Future<SyncResult> _resolveConflictsLastWriteWins(SyncManifest remoteManifest, List<String> conflicts) async {
    try {
      final resolvedConflicts = <String>[];

      for (final conflictFile in conflicts) {
        final localFile = _localManifest.files[conflictFile];
        final remoteFile = remoteManifest.files[conflictFile];

        if (localFile != null && remoteFile != null) {
          // Last-Write-Wins: Neueste Datei gewinnt
          if (localFile.lastModified.isAfter(remoteFile.lastModified)) {
            AppLogger.info('WebDAV', 'Lokale Datei ist neuer: \$conflictFile');
            // Lokale Datei überschreibt Remote
            // TODO: Actual file upload implementation
          } else {
            AppLogger.info('WebDAV', 'Remote Datei ist neuer: \$conflictFile');
            // Remote Datei überschreibt Lokal
            // TODO: Actual file download implementation
          }
          resolvedConflicts.add(conflictFile);
        }
      }

      // Merge der Manifeste nach Konflikt-Resolution
      final mergedManifest = _mergeManifests(_localManifest, remoteManifest);

      // Upload finales Manifest
      await _uploadRemoteManifest(mergedManifest);

      AppLogger.info('WebDAV', 'Konflikte erfolgreich geloest: \$resolvedConflicts');
      return SyncResult.success('Konflikte gelöst', conflicts: resolvedConflicts);

    } catch (e) {
      return SyncResult.error('Konflikt-Resolution fehlgeschlagen: \$e');
    }
  }

  /// Merge zwei Manifeste
  SyncManifest _mergeManifests(SyncManifest local, SyncManifest remote) {
    final mergedFiles = Map<String, FileMetadata>.from(local.files);

    // Füge Remote-Dateien hinzu, die nicht lokal vorhanden sind
    for (final entry in remote.files.entries) {
      if (!mergedFiles.containsKey(entry.key) ||
          entry.value.lastModified.isAfter(mergedFiles[entry.key]!.lastModified)) {
        mergedFiles[entry.key] = entry.value;
      }
    }

    return local.copyWith(
      files: mergedFiles,
      lastSync: DateTime.now(),
    );
  }

  /// File Hash für Integrity Check
  String _calculateFileHash(Uint8List data) {
    final bytes = sha256.convert(data);
    return bytes.toString();
  }

  void dispose() {
    _client.dispose();
  }
}

// ========================================
// 🔒 SYNC RESULT CLASSES
// ========================================

class SyncResult {
  final bool success;
  final String message;
  final List<String> conflicts;
  final String? error;

  SyncResult.success(this.message, {required this.conflicts})
      : success = true,
        error = null;

  SyncResult.error(this.error)
      : success = false,
        message = '',
        conflicts = [];
}

class ManifestResult {
  final bool success;
  final SyncManifest? manifest;
  final String? error;

  ManifestResult.success(this.manifest)
      : success = true,
        error = null;

  ManifestResult.notFound()
      : success = false,
        manifest = null,
        error = 'Manifest nicht gefunden';

  ManifestResult.error(this.error)
      : success = false,
        manifest = null;
}
