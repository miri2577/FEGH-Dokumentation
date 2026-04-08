import 'package:json_annotation/json_annotation.dart';
import 'client.dart';
import 'appointment.dart';
import 'app_settings.dart';

part 'backup_data.g.dart';

@JsonSerializable()
class BackupData {
  final BackupMetadata metadata;
  final List<Client> clients;
  final List<Appointment> appointments;
  final List<String> emailTargets;
  final AppSettings settings;
  final String version;

  BackupData({
    required this.metadata,
    required this.clients,
    required this.appointments,
    required this.emailTargets,
    required this.settings,
    required this.version,
  });

  BackupData.create({
    required this.clients,
    required this.appointments,
    required this.emailTargets,
    required this.settings,
  }) : metadata = BackupMetadata.create(),
       version = "2.1.0";

  factory BackupData.fromJson(Map<String, dynamic> json) => _$BackupDataFromJson(json);
  Map<String, dynamic> toJson() => _$BackupDataToJson(this);
}

@JsonSerializable()
class BackupMetadata {
  final String backupId;
  final DateTime createdAt;
  final String deviceName;
  final String appVersion;
  final String dataVersion;

  BackupMetadata({
    required this.backupId,
    required this.createdAt,
    required this.deviceName,
    required this.appVersion,
    required this.dataVersion,
  });

  BackupMetadata.create()
      : backupId = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now(),
        deviceName = "Flutter Device", // TODO: Get actual device name
        appVersion = "2.1.0",
        dataVersion = "1.0.0";

  factory BackupMetadata.fromJson(Map<String, dynamic> json) => _$BackupMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$BackupMetadataToJson(this);
}

@JsonSerializable()
class BackupInfo {
  final String id;
  final String filename;
  final DateTime createdAt;
  final String deviceName;
  final int clientCount;
  final int appointmentCount;
  final bool isEncrypted;
  final int fileSizeBytes;

  BackupInfo({
    required this.id,
    required this.filename,
    required this.createdAt,
    required this.deviceName,
    required this.clientCount,
    required this.appointmentCount,
    required this.isEncrypted,
    required this.fileSizeBytes,
  });

  factory BackupInfo.fromJson(Map<String, dynamic> json) => _$BackupInfoFromJson(json);
  Map<String, dynamic> toJson() => _$BackupInfoToJson(this);

  String get formattedFileSize {
    if (fileSizeBytes < 1024) return '${fileSizeBytes} B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}