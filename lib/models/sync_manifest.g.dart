// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_manifest.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SyncManifest _$SyncManifestFromJson(Map<String, dynamic> json) => SyncManifest(
  deviceId: json['deviceId'] as String,
  deviceName: json['deviceName'] as String,
  deviceType: json['deviceType'] as String,
  lastSync: DateTime.parse(json['lastSync'] as String),
  version: json['version'] as String,
  files: (json['files'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(k, FileMetadata.fromJson(e as Map<String, dynamic>)),
  ),
);

Map<String, dynamic> _$SyncManifestToJson(SyncManifest instance) =>
    <String, dynamic>{
      'deviceId': instance.deviceId,
      'deviceName': instance.deviceName,
      'deviceType': instance.deviceType,
      'lastSync': instance.lastSync.toIso8601String(),
      'version': instance.version,
      'files': instance.files,
    };

FileMetadata _$FileMetadataFromJson(Map<String, dynamic> json) => FileMetadata(
  fileName: json['fileName'] as String,
  hash: json['hash'] as String,
  size: (json['size'] as num).toInt(),
  lastModified: DateTime.parse(json['lastModified'] as String),
  deviceId: json['deviceId'] as String,
);

Map<String, dynamic> _$FileMetadataToJson(FileMetadata instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'hash': instance.hash,
      'size': instance.size,
      'lastModified': instance.lastModified.toIso8601String(),
      'deviceId': instance.deviceId,
    };

ConflictResolution _$ConflictResolutionFromJson(Map<String, dynamic> json) =>
    ConflictResolution(
      fileName: json['fileName'] as String,
      strategy: $enumDecode(_$ConflictStrategyEnumMap, json['strategy']),
      selectedDeviceId: json['selectedDeviceId'] as String?,
      resolvedAt: DateTime.parse(json['resolvedAt'] as String),
    );

Map<String, dynamic> _$ConflictResolutionToJson(ConflictResolution instance) =>
    <String, dynamic>{
      'fileName': instance.fileName,
      'strategy': _$ConflictStrategyEnumMap[instance.strategy]!,
      'selectedDeviceId': instance.selectedDeviceId,
      'resolvedAt': instance.resolvedAt.toIso8601String(),
    };

const _$ConflictStrategyEnumMap = {
  ConflictStrategy.keepLocal: 'keep_local',
  ConflictStrategy.keepRemote: 'keep_remote',
  ConflictStrategy.keepBoth: 'keep_both',
  ConflictStrategy.manualMerge: 'manual_merge',
  ConflictStrategy.lastWriteWins: 'last_write_wins',
};
