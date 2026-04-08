import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'hidrive_webdav_client.dart';

/// Optimistic Locking fuer Dokumente auf HiDrive.
/// Erstellt .lock-Dateien um gleichzeitige Bearbeitung zu erkennen.
class DocumentLockService {
  final HiDriveBusinessSync _sync;
  final String _currentUser;
  final String _deviceName;

  /// Auto-Unlock nach dieser Dauer (Minuten)
  static const int lockTimeoutMinutes = 15;

  DocumentLockService({
    required HiDriveBusinessSync sync,
    required String currentUser,
    required String deviceName,
  })  : _sync = sync,
        _currentUser = currentUser,
        _deviceName = deviceName;

  /// Prueft ob ein Dokument gesperrt ist.
  /// Gibt null zurueck wenn frei, sonst die Lock-Info.
  Future<DocumentLock?> checkLock(String documentPath) async {
    try {
      final lockPath = _lockPath(documentPath);
      final result = await _sync.downloadOrgScopedRecord(
        _dirPart(lockPath),
        _filePart(lockPath),
      );
      if (!result.isSuccess || result.data == null) return null;

      final lockJson = jsonDecode(utf8.decode(result.data!));
      final lock = DocumentLock.fromJson(lockJson);

      // Abgelaufene Locks ignorieren
      if (lock.isExpired) {
        await releaseLock(documentPath);
        return null;
      }

      // Eigener Lock = frei
      if (lock.user == _currentUser && lock.device == _deviceName) {
        return null;
      }

      return lock;
    } catch (_) {
      return null; // Im Fehlerfall: kein Lock angenommen
    }
  }

  /// Sperrt ein Dokument fuer den aktuellen Benutzer.
  Future<bool> acquireLock(String documentPath) async {
    try {
      // Erst pruefen ob bereits gesperrt
      final existing = await checkLock(documentPath);
      if (existing != null) return false;

      final lock = DocumentLock(
        user: _currentUser,
        device: _deviceName,
        since: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(minutes: lockTimeoutMinutes)),
      );

      final lockBytes = Uint8List.fromList(utf8.encode(jsonEncode(lock.toJson())));
      final lockPath = _lockPath(documentPath);
      final result = await _sync.uploadOrgScopedRecord(
        _dirPart(lockPath),
        _filePart(lockPath),
        lockBytes,
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('[LOCK] acquireLock failed: $e');
      return false;
    }
  }

  /// Gibt die Sperre eines Dokuments frei.
  Future<bool> releaseLock(String documentPath) async {
    try {
      final lockPath = _lockPath(documentPath);
      final result = await _sync.deleteOrgScopedRecord(
        _dirPart(lockPath),
        _filePart(lockPath),
      );
      return result.isSuccess;
    } catch (e) {
      debugPrint('[LOCK] releaseLock failed: $e');
      return false;
    }
  }

  /// Erneuert die Sperre (verlaengert Timeout).
  Future<bool> renewLock(String documentPath) async {
    await releaseLock(documentPath);
    return acquireLock(documentPath);
  }

  // Lock-Datei liegt neben dem Dokument mit .lock Suffix
  String _lockPath(String documentPath) => '$documentPath.lock';

  String _dirPart(String path) {
    final lastSlash = path.lastIndexOf('/');
    return lastSlash > 0 ? path.substring(0, lastSlash) : '';
  }

  String _filePart(String path) {
    final lastSlash = path.lastIndexOf('/');
    return lastSlash >= 0 ? path.substring(lastSlash + 1) : path;
  }
}

/// Informationen ueber eine Dokumentsperre.
class DocumentLock {
  final String user;
  final String device;
  final DateTime since;
  final DateTime expiresAt;

  DocumentLock({
    required this.user,
    required this.device,
    required this.since,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get activeSince => DateTime.now().difference(since);

  String get displayText =>
      '$user bearbeitet seit ${since.hour}:${since.minute.toString().padLeft(2, '0')} '
      '($device)';

  factory DocumentLock.fromJson(Map<String, dynamic> json) => DocumentLock(
        user: json['user'] ?? '',
        device: json['device'] ?? '',
        since: DateTime.parse(json['since']),
        expiresAt: DateTime.parse(json['expiresAt']),
      );

  Map<String, dynamic> toJson() => {
        'user': user,
        'device': device,
        'since': since.toIso8601String(),
        'expiresAt': expiresAt.toIso8601String(),
      };
}
