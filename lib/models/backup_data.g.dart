// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'backup_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BackupData _$BackupDataFromJson(Map<String, dynamic> json) => BackupData(
  metadata: BackupMetadata.fromJson(json['metadata'] as Map<String, dynamic>),
  clients: (json['clients'] as List<dynamic>)
      .map((e) => Client.fromJson(e as Map<String, dynamic>))
      .toList(),
  appointments: (json['appointments'] as List<dynamic>)
      .map((e) => Appointment.fromJson(e as Map<String, dynamic>))
      .toList(),
  emailTargets: (json['emailTargets'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  settings: AppSettings.fromJson(json['settings'] as Map<String, dynamic>),
  version: json['version'] as String,
);

Map<String, dynamic> _$BackupDataToJson(BackupData instance) =>
    <String, dynamic>{
      'metadata': instance.metadata,
      'clients': instance.clients,
      'appointments': instance.appointments,
      'emailTargets': instance.emailTargets,
      'settings': instance.settings,
      'version': instance.version,
    };

BackupMetadata _$BackupMetadataFromJson(Map<String, dynamic> json) =>
    BackupMetadata(
      backupId: json['backupId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      deviceName: json['deviceName'] as String,
      appVersion: json['appVersion'] as String,
      dataVersion: json['dataVersion'] as String,
    );

Map<String, dynamic> _$BackupMetadataToJson(BackupMetadata instance) =>
    <String, dynamic>{
      'backupId': instance.backupId,
      'createdAt': instance.createdAt.toIso8601String(),
      'deviceName': instance.deviceName,
      'appVersion': instance.appVersion,
      'dataVersion': instance.dataVersion,
    };

BackupInfo _$BackupInfoFromJson(Map<String, dynamic> json) => BackupInfo(
  id: json['id'] as String,
  filename: json['filename'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  deviceName: json['deviceName'] as String,
  clientCount: (json['clientCount'] as num).toInt(),
  appointmentCount: (json['appointmentCount'] as num).toInt(),
  isEncrypted: json['isEncrypted'] as bool,
  fileSizeBytes: (json['fileSizeBytes'] as num).toInt(),
);

Map<String, dynamic> _$BackupInfoToJson(BackupInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'filename': instance.filename,
      'createdAt': instance.createdAt.toIso8601String(),
      'deviceName': instance.deviceName,
      'clientCount': instance.clientCount,
      'appointmentCount': instance.appointmentCount,
      'isEncrypted': instance.isEncrypted,
      'fileSizeBytes': instance.fileSizeBytes,
    };
