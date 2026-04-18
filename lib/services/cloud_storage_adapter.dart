import 'dart:typed_data';
import 'package:fegh_cloud/fegh_cloud.dart' as cloud;
import 'package:flutter/foundation.dart';
import 'hidrive_webdav_client.dart';

/// Abstrakte Schnittstelle fuer austauschbare Cloud-Storage-Backends.
/// Ermoeglicht Wechsel zwischen HiDrive, Nextcloud, S3, etc.
abstract class CloudStorageAdapter {
  /// Verbindung testen.
  Future<bool> testConnection();

  /// Datei hochladen.
  Future<bool> uploadFile(String remotePath, Uint8List data);

  /// Datei herunterladen.
  Future<Uint8List?> downloadFile(String remotePath);

  /// Datei loeschen.
  Future<bool> deleteFile(String remotePath);

  /// Dateien in Ordner auflisten.
  Future<List<String>> listFiles(String remotePath);

  /// Unterordner auflisten.
  Future<List<String>> listDirectories(String remotePath);

  /// Ordner erstellen.
  Future<bool> createDirectory(String remotePath);

  /// Name des Adapters (fuer Anzeige).
  String get adapterName;
}

/// HiDrive-Implementierung des CloudStorageAdapter.
class HiDriveStorageAdapter implements CloudStorageAdapter {
  final HiDriveWebDAVClient _client;

  HiDriveStorageAdapter({
    required String baseUrl,
    required String username,
    required String password,
  }) : _client = HiDriveWebDAVClient(
          baseUrl: baseUrl,
          username: username,
          password: password,
          certificatePins: HiDriveConfig.certificatePins,
        );

  @override
  String get adapterName => 'STRATO HiDrive';

  @override
  Future<bool> testConnection() async {
    final result = await _client.testConnection();
    return result.isSuccess;
  }

  @override
  Future<bool> uploadFile(String remotePath, Uint8List data) async {
    final result = await _client.put(remotePath, data);
    return result.isSuccess;
  }

  @override
  Future<Uint8List?> downloadFile(String remotePath) async {
    final result = await _client.get(remotePath);
    return result.isSuccess ? result.data : null;
  }

  @override
  Future<bool> deleteFile(String remotePath) async {
    final result = await _client.delete(remotePath);
    return result.isSuccess;
  }

  @override
  Future<List<String>> listFiles(String remotePath) async {
    final result = await _client.list(remotePath);
    return result.isSuccess ? (result.data ?? []) : [];
  }

  @override
  Future<List<String>> listDirectories(String remotePath) async {
    final result = await _client.listDirectories(remotePath);
    return result.isSuccess ? (result.data ?? []) : [];
  }

  @override
  Future<bool> createDirectory(String remotePath) async {
    final result = await _client.createDirectory(remotePath);
    return result.isSuccess;
  }
}

/// Nextcloud/ownCloud-Implementierung (WebDAV, fast identisch mit HiDrive).
class NextcloudStorageAdapter implements CloudStorageAdapter {
  final cloud.NextcloudAdapter _client;
  final String _serverName;

  NextcloudStorageAdapter({
    required String serverUrl,
    required String username,
    required String password,
  })  : _client = cloud.NextcloudAdapter(
          serverUrl: serverUrl,
          username: username,
          appToken: password, // appToken oder Login-Passwort
        ),
        _serverName = serverUrl;

  @override
  String get adapterName => 'Nextcloud ($_serverName)';

  @override
  Future<bool> testConnection() async =>
      (await _client.testConnection()).isSuccess;

  @override
  Future<bool> uploadFile(String remotePath, Uint8List data) async =>
      (await _client.upload(remotePath, data)).isSuccess;

  @override
  Future<Uint8List?> downloadFile(String remotePath) async {
    final r = await _client.download(remotePath);
    return r.isSuccess ? r.data : null;
  }

  @override
  Future<bool> deleteFile(String remotePath) async =>
      (await _client.delete(remotePath)).isSuccess;

  @override
  Future<List<String>> listFiles(String remotePath) async {
    final r = await _client.list(remotePath);
    if (!r.isSuccess) return [];
    return r.data!.where((e) => !e.isDirectory).map((e) => e.name).toList();
  }

  @override
  Future<List<String>> listDirectories(String remotePath) async {
    final r = await _client.listDirectories(remotePath);
    if (!r.isSuccess) return [];
    return r.data!.map((e) => e.name).toList();
  }

  @override
  Future<bool> createDirectory(String remotePath) async =>
      (await _client.createDirectory(remotePath)).isSuccess;
}

/// ownCloud-Implementierung (identisch Nextcloud, eigener Display-Name).
class OwncloudStorageAdapter implements CloudStorageAdapter {
  final cloud.OwncloudAdapter _client;
  final String _serverName;

  OwncloudStorageAdapter({
    required String serverUrl,
    required String username,
    required String password,
  })  : _client = cloud.OwncloudAdapter(
          serverUrl: serverUrl,
          username: username,
          appToken: password,
        ),
        _serverName = serverUrl;

  @override
  String get adapterName => 'ownCloud ($_serverName)';

  @override
  Future<bool> testConnection() async =>
      (await _client.testConnection()).isSuccess;

  @override
  Future<bool> uploadFile(String remotePath, Uint8List data) async =>
      (await _client.upload(remotePath, data)).isSuccess;

  @override
  Future<Uint8List?> downloadFile(String remotePath) async {
    final r = await _client.download(remotePath);
    return r.isSuccess ? r.data : null;
  }

  @override
  Future<bool> deleteFile(String remotePath) async =>
      (await _client.delete(remotePath)).isSuccess;

  @override
  Future<List<String>> listFiles(String remotePath) async {
    final r = await _client.list(remotePath);
    if (!r.isSuccess) return [];
    return r.data!.where((e) => !e.isDirectory).map((e) => e.name).toList();
  }

  @override
  Future<List<String>> listDirectories(String remotePath) async {
    final r = await _client.listDirectories(remotePath);
    if (!r.isSuccess) return [];
    return r.data!.map((e) => e.name).toList();
  }

  @override
  Future<bool> createDirectory(String remotePath) async =>
      (await _client.createDirectory(remotePath)).isSuccess;
}

/// Nur-lokaler Adapter (kein Cloud-Sync). Gibt immer Erfolg zurueck.
class LocalOnlyStorageAdapter implements CloudStorageAdapter {
  @override
  String get adapterName => 'Nur lokal (kein Cloud-Sync)';

  @override
  Future<bool> testConnection() async => true;
  @override
  Future<bool> uploadFile(String remotePath, Uint8List data) async => true;
  @override
  Future<Uint8List?> downloadFile(String remotePath) async => null;
  @override
  Future<bool> deleteFile(String remotePath) async => true;
  @override
  Future<List<String>> listFiles(String remotePath) async => [];
  @override
  Future<List<String>> listDirectories(String remotePath) async => [];
  @override
  Future<bool> createDirectory(String remotePath) async => true;
}

/// Factory zum Erstellen des passenden Adapters.
class CloudStorageFactory {
  static CloudStorageAdapter create({
    required String type,
    required String url,
    required String username,
    required String password,
  }) {
    switch (type) {
      case 'hidrive':
        return HiDriveStorageAdapter(
          baseUrl: HiDriveConfig.buildWebDAVUrl(username),
          username: username,
          password: password,
        );
      case 'nextcloud':
        return NextcloudStorageAdapter(
          serverUrl: url,
          username: username,
          password: password,
        );
      case 'owncloud':
        return OwncloudStorageAdapter(
          serverUrl: url,
          username: username,
          password: password,
        );
      case 'local':
        return LocalOnlyStorageAdapter();
      default:
        debugPrint('[CLOUD] Unbekannter Adapter-Typ: $type, nutze lokal');
        return LocalOnlyStorageAdapter();
    }
  }
}
