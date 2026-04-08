import 'package:json_annotation/json_annotation.dart';
import 'dart:io' show Platform;
import 'dart:math';

part 'sync_manifest.g.dart';

@JsonSerializable()
class SyncManifest {
  final String deviceId;
  final String deviceName;
  final String deviceType;
  final DateTime lastSync;
  final String version;
  final Map<String, FileMetadata> files;

  SyncManifest({
    required this.deviceId,
    required this.deviceName,
    required this.deviceType,
    required this.lastSync,
    required this.version,
    required this.files,
  });

  factory SyncManifest.createNew() {
    return SyncManifest(
      deviceId: _generateDeviceId(),
      deviceName: _getDeviceName(),
      deviceType: _getDeviceType(),
      lastSync: DateTime.now(),
      version: '1.0.0',
      files: {},
    );
  }

  static String _generateDeviceId() {
    final random = Random.secure();
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(16, (index) => chars[random.nextInt(chars.length)]).join();
  }

  static String _getDeviceName() {
    try {
      if (Platform.isMacOS) return Platform.localHostname;
      if (Platform.isWindows) return Platform.localHostname;
      if (Platform.isLinux) return Platform.localHostname;
      return 'Unknown Device';
    } catch (e) {
      return 'Flutter Device';
    }
  }

  static String _getDeviceType() {
    try {
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      return 'Unknown';
    } catch (e) {
      return 'Flutter';
    }
  }

  SyncManifest copyWith({
    String? deviceId,
    String? deviceName,
    String? deviceType,
    DateTime? lastSync,
    String? version,
    Map<String, FileMetadata>? files,
  }) {
    return SyncManifest(
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      lastSync: lastSync ?? this.lastSync,
      version: version ?? this.version,
      files: files ?? this.files,
    );
  }

  SyncManifest updateFile(String fileName, FileMetadata metadata) {
    final updatedFiles = Map<String, FileMetadata>.from(files);
    updatedFiles[fileName] = metadata;

    return copyWith(
      files: updatedFiles,
      lastSync: DateTime.now(),
    );
  }

  bool hasConflictWith(SyncManifest other) {
    for (final entry in files.entries) {
      final fileName = entry.key;
      final localFile = entry.value;

      if (other.files.containsKey(fileName)) {
        final remoteFile = other.files[fileName]!;

        // Konflikt wenn beide Dateien nach dem letzten gemeinsamen Sync geändert wurden
        if (localFile.lastModified.isAfter(other.lastSync) &&
            remoteFile.lastModified.isAfter(lastSync)) {
          return true;
        }
      }
    }
    return false;
  }

  List<String> getConflictingFiles(SyncManifest other) {
    final conflicts = <String>[];

    for (final entry in files.entries) {
      final fileName = entry.key;
      final localFile = entry.value;

      if (other.files.containsKey(fileName)) {
        final remoteFile = other.files[fileName]!;

        if (localFile.lastModified.isAfter(other.lastSync) &&
            remoteFile.lastModified.isAfter(lastSync)) {
          conflicts.add(fileName);
        }
      }
    }

    return conflicts;
  }

  factory SyncManifest.fromJson(Map<String, dynamic> json) => _$SyncManifestFromJson(json);
  Map<String, dynamic> toJson() => _$SyncManifestToJson(this);
}

@JsonSerializable()
class FileMetadata {
  final String fileName;
  final String hash;
  final int size;
  final DateTime lastModified;
  final String deviceId;

  FileMetadata({
    required this.fileName,
    required this.hash,
    required this.size,
    required this.lastModified,
    required this.deviceId,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) => _$FileMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);
}

@JsonSerializable()
class ConflictResolution {
  final String fileName;
  final ConflictStrategy strategy;
  final String? selectedDeviceId;
  final DateTime resolvedAt;

  ConflictResolution({
    required this.fileName,
    required this.strategy,
    this.selectedDeviceId,
    required this.resolvedAt,
  });

  factory ConflictResolution.fromJson(Map<String, dynamic> json) => _$ConflictResolutionFromJson(json);
  Map<String, dynamic> toJson() => _$ConflictResolutionToJson(this);
}

enum ConflictStrategy {
  @JsonValue('keep_local')
  keepLocal,

  @JsonValue('keep_remote')
  keepRemote,

  @JsonValue('keep_both')
  keepBoth,

  @JsonValue('manual_merge')
  manualMerge,

  @JsonValue('last_write_wins')
  lastWriteWins,
}