import 'dart:convert';
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' hide Key;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:universal_io/io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../utils/platform_utils.dart';

class BackupData {
  final BackupMetadata metadata;
  final List<Client> clients;
  final List<Appointment> appointments;
  final List<String> emailTargets;
  final AppSettings settings;
  final String version;

  BackupData({
    required this.clients,
    required this.appointments,
    required this.emailTargets,
    required this.settings,
  }) : metadata = BackupMetadata(),
        version = '2.1.0';

  Map<String, dynamic> toJson() => {
    'metadata': metadata.toJson(),
    'clients': clients.map((c) => c.toJson()).toList(),
    'appointments': appointments.map((a) => a.toJson()).toList(),
    'emailTargets': emailTargets,
    'settings': settings.toJson(),
    'version': version,
  };

  factory BackupData.fromJson(Map<String, dynamic> json) => BackupData(
    clients: (json['clients'] as List)
        .map((c) => Client.fromJson(c))
        .toList(),
    appointments: (json['appointments'] as List)
        .map((a) => Appointment.fromJson(a))
        .toList(),
    emailTargets: List<String>.from(json['emailTargets']),
    settings: AppSettings.fromJson(json['settings']),
  );
}

class BackupMetadata {
  final String backupId;
  final DateTime createdAt;
  final String deviceName;
  final String appVersion;
  final String dataVersion;

  BackupMetadata()
      : backupId = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now(),
        deviceName = _getDeviceName(),
        appVersion = '2.1.0',
        dataVersion = '1.0.0';

  static String _getDeviceName() {
    if (PlatformUtils.isWeb) return 'Web Browser';
    if (PlatformUtils.isAndroid) return 'Android Device';
    if (PlatformUtils.isIOS) return 'iOS Device';
    if (PlatformUtils.isMacOS) return 'macOS';
    if (PlatformUtils.isWindows) return 'Windows';
    if (PlatformUtils.isLinux) return 'Linux';
    return 'Unknown Device';
  }

  Map<String, dynamic> toJson() => {
    'backupId': backupId,
    'createdAt': createdAt.toIso8601String(),
    'deviceName': deviceName,
    'appVersion': appVersion,
    'dataVersion': dataVersion,
  };

  factory BackupMetadata.fromJson(Map<String, dynamic> json) =>
      BackupMetadata(); // Simplified for this implementation
}

class BackupInfo {
  final String id;
  final String filename;
  final DateTime createdAt;
  final int size;
  final int clientCount;
  final int appointmentCount;
  final bool isEncrypted;
  final String deviceName;

  BackupInfo({
    required this.id,
    required this.filename,
    required this.createdAt,
    required this.size,
    required this.clientCount,
    required this.appointmentCount,
    required this.isEncrypted,
    required this.deviceName,
  });

  String get formattedSize {
    if (size < 1024) return '${size} B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} Tage alt';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} Stunden alt';
    } else {
      return '${difference.inMinutes} Minuten alt';
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'filename': filename,
    'createdAt': createdAt.toIso8601String(),
    'size': size,
    'clientCount': clientCount,
    'appointmentCount': appointmentCount,
    'isEncrypted': isEncrypted,
    'deviceName': deviceName,
  };

  factory BackupInfo.fromJson(Map<String, dynamic> json) => BackupInfo(
    id: json['id'],
    filename: json['filename'],
    createdAt: DateTime.parse(json['createdAt']),
    size: json['size'],
    clientCount: json['clientCount'],
    appointmentCount: json['appointmentCount'],
    isEncrypted: json['isEncrypted'],
    deviceName: json['deviceName'],
  );
}

class BackupService {
  static const String _saltPrefix = 'eingliederungshilfe_salt_';

  Future<BackupResult> createBackup({
    required List<Client> clients,
    required List<Appointment> appointments,
    required List<String> emailTargets,
    required AppSettings settings,
    String? password,
    bool includeSettings = true,
  }) async {
    try {
      final backupData = BackupData(
        clients: clients,
        appointments: appointments,
        emailTargets: emailTargets,
        settings: includeSettings ? settings : AppSettings.defaultSettings(),
      );

      final jsonData = jsonEncode(backupData.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'EingliederungshilfeBackup_$timestamp';

      Uint8List finalData;
      String finalFilename;
      bool isEncrypted = password != null;

      if (password != null) {
        finalData = await _encryptData(jsonData, password);
        finalFilename = '$filename.ehbackup';
      } else {
        finalData = utf8.encode(jsonData);
        finalFilename = '$filename.json';
      }

      final backupInfo = BackupInfo(
        id: backupData.metadata.backupId,
        filename: finalFilename,
        createdAt: backupData.metadata.createdAt,
        size: finalData.length,
        clientCount: clients.length,
        appointmentCount: appointments.length,
        isEncrypted: isEncrypted,
        deviceName: backupData.metadata.deviceName,
      );

      if (PlatformUtils.isWeb) {
        return await _saveBackupWeb(finalData, finalFilename, backupInfo);
      } else {
        return await _saveBackupNative(finalData, finalFilename, backupInfo);
      }
    } catch (e) {
      return BackupResult.failure('Backup-Erstellung fehlgeschlagen: $e');
    }
  }

  Future<RestoreResult> restoreBackupFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    String? password,
    bool restoreSettings = true,
  }) async {
    try {
      String jsonData;
      final isEncrypted = fileName.endsWith('.ehbackup');

      if (isEncrypted) {
        if (password == null) {
          return RestoreResult.failure('Passwort erforderlich für verschlüsselte Backup');
        }
        jsonData = await _decryptData(fileBytes, password);
      } else {
        jsonData = utf8.decode(fileBytes);
      }

      final jsonMap = jsonDecode(jsonData) as Map<String, dynamic>;

      return await _processRestoreData(jsonMap, restoreSettings);
    } catch (e) {
      return RestoreResult.failure('Backup-Wiederherstellung fehlgeschlagen: $e');
    }
  }

  Future<RestoreResult> restoreBackup({
    required String filePath,
    String? password,
    bool restoreSettings = true,
  }) async {
    try {
      Uint8List fileData;
      
      if (PlatformUtils.isWeb) {
        return RestoreResult.failure('Für Web verwende restoreBackupFromBytes');
      } else {
        final file = File(filePath);
        if (!file.existsSync()) {
          return RestoreResult.failure('Backup-Datei nicht gefunden');
        }
        fileData = file.readAsBytesSync();
      }

      String jsonData;
      final isEncrypted = filePath.endsWith('.ehbackup');

      if (isEncrypted) {
        if (password == null) {
          return RestoreResult.failure('Passwort erforderlich für verschlüsselte Backup');
        }
        jsonData = await _decryptData(fileData, password);
      } else {
        jsonData = utf8.decode(fileData);
      }

      final jsonMap = jsonDecode(jsonData) as Map<String, dynamic>;
      
      return await _processRestoreData(jsonMap, restoreSettings);
    } catch (e) {
      return RestoreResult.failure('Wiederherstellung fehlgeschlagen: $e');
    }
  }

  Future<RestoreResult> _processRestoreData(Map<String, dynamic> jsonMap, bool restoreSettings) async {
    try {
      // Check if this is an iOS backup by looking for iOS-specific format
      final isIOSBackup = _isIOSBackup(jsonMap);
      
      BackupData backupData;
      if (isIOSBackup) {
        backupData = _convertIOSBackup(jsonMap);
      } else {
        backupData = BackupData.fromJson(jsonMap);
      }

      return RestoreResult.success(
        clients: backupData.clients,
        appointments: backupData.appointments,
        emailTargets: backupData.emailTargets,
        settings: restoreSettings ? backupData.settings : null,
      );
    } catch (e) {
      return RestoreResult.failure('Datenverarbeitung fehlgeschlagen: $e');
    }
  }

  Future<bool> shareBackup(String filePath) async {
    try {
      if (PlatformUtils.isWeb) {
        // Web sharing implementation
        return await _shareBackupWeb(filePath);
      } else {
        final result = await Share.shareXFiles(
          [XFile(filePath)],
          text: 'Eingliederungshilfe Backup',
        );
        return result.status == ShareResultStatus.success;
      }
    } catch (e) {
      return false;
    }
  }

  Future<List<BackupInfo>> getAvailableBackups() async {
    if (PlatformUtils.isWeb) {
      return []; // Web kann keine lokalen Backups auflisten
    }

    try {
      final directory = await getApplicationSupportDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!backupDir.existsSync()) {
        return [];
      }

      final files = backupDir.listSync()
          .where((file) => file is File && 
              (file.path.endsWith('.json') || file.path.endsWith('.ehbackup')))
          .cast<File>()
          .toList();

      final backups = <BackupInfo>[];
      for (final file in files) {
        final backupInfo = await _createBackupInfoFromFile(file);
        if (backupInfo != null) {
          backups.add(backupInfo);
        }
      }

      backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return backups;
    } catch (e) {
      return [];
    }
  }

  Future<bool> deleteBackup(BackupInfo backup) async {
    try {
      if (PlatformUtils.isWeb) {
        return false; // Web kann keine lokalen Dateien löschen
      }

      final directory = await getApplicationSupportDirectory();
      final file = File('${directory.path}/backups/${backup.filename}');
      
      if (file.existsSync()) {
        file.deleteSync();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Private Helper Methods

  /// Check if the backup JSON is from iOS app
  bool _isIOSBackup(Map<String, dynamic> json) {
    // iOS backup has metadata with different structure
    if (json.containsKey('metadata')) {
      final metadata = json['metadata'] as Map<String, dynamic>;
      // iOS uses deviceName "iPhone" and has backupId as UUID
      if (metadata.containsKey('deviceName') && 
          metadata.containsKey('backupId') &&
          metadata['deviceName'] == 'iPhone') {
        return true;
      }
    }
    
    // Check for Unix timestamp format in appointments (iOS uses double, Flutter uses ISO string)
    if (json.containsKey('appointments') && json['appointments'] is List) {
      final appointments = json['appointments'] as List;
      if (appointments.isNotEmpty) {
        final firstAppointment = appointments.first as Map<String, dynamic>;
        if (firstAppointment.containsKey('createdAt') && 
            firstAppointment['createdAt'] is double) {
          return true;
        }
      }
    }
    
    return false;
  }

  /// Convert iOS backup format to Flutter format
  BackupData _convertIOSBackup(Map<String, dynamic> iosBackup) {
    // Convert clients
    final iosClients = (iosBackup['clients'] as List? ?? []).cast<Map<String, dynamic>>();
    final clients = iosClients.map((iosClient) {
      return Client(
        id: iosClient['id'] as String,
        name: iosClient['name'] as String,
        berufsgruppe: iosClient['berufsgruppe'] as String? ?? 'Sozialpädagoge',
        eingliederung: iosClient['eingliederung'] as String? ?? 'Soziale Teilhabe',
        createdAt: _convertIOSTimestamp(iosClient['createdAt']),
      );
    }).toList();

    // Convert appointments
    final iosAppointments = (iosBackup['appointments'] as List? ?? []).cast<Map<String, dynamic>>();
    final appointments = iosAppointments.map((iosAppointment) {
      return Appointment(
        id: iosAppointment['id'] as String,
        clientId: iosAppointment['clientId'] as String,
        clientName: iosAppointment['clientName'] as String,
        date: _convertIOSTimestamp(iosAppointment['date']),
        startTime: _convertIOSTimestamp(iosAppointment['startTime']),
        endTime: _convertIOSTimestamp(iosAppointment['endTime']),
        notes: iosAppointment['notes'] as String? ?? '',
        recordedText: iosAppointment['recordedText'] as String? ?? '',
        berufsgruppe: iosAppointment['berufsgruppe'] as String? ?? 'Sozialpädagoge',
        eingliederung: iosAppointment['eingliederung'] as String? ?? 'Soziale Teilhabe',
        createdAt: _convertIOSTimestamp(iosAppointment['createdAt']),
      );
    }).toList();

    // Convert email targets
    final emailTargets = (iosBackup['emailTargets'] as List? ?? []).cast<String>();

    // Convert settings
    final iosSettings = iosBackup['settings'] as Map<String, dynamic>? ?? {};
    final settings = AppSettings.defaultSettings().copyWith(
      userName: iosSettings['userName'] as String? ?? '',
    );

    return BackupData(
      clients: clients,
      appointments: appointments,
      emailTargets: emailTargets,
      settings: settings,
    );
  }

  /// Convert iOS timestamp (NSTimeInterval since 2001-01-01) to DateTime
  DateTime _convertIOSTimestamp(dynamic timestamp) {
    if (timestamp is double) {
      // iOS NSTimeInterval: seconds since 1 January 2001 GMT
      // Convert to Unix timestamp by adding the offset (978307200 seconds)
      const iosEpochOffset = 978307200; // Seconds between 1970-01-01 and 2001-01-01
      final unixTimestamp = timestamp + iosEpochOffset;
      return DateTime.fromMillisecondsSinceEpoch((unixTimestamp * 1000).round());
    } else if (timestamp is int) {
      // Same conversion for int
      const iosEpochOffset = 978307200;
      final unixTimestamp = timestamp + iosEpochOffset;
      return DateTime.fromMillisecondsSinceEpoch(unixTimestamp * 1000);
    } else if (timestamp is String) {
      // Try to parse as ISO string first (Flutter format)
      try {
        return DateTime.parse(timestamp);
      } catch (e) {
        // If that fails, try to parse as timestamp with iOS offset
        final timestampDouble = double.tryParse(timestamp);
        if (timestampDouble != null) {
          const iosEpochOffset = 978307200;
          final unixTimestamp = timestampDouble + iosEpochOffset;
          return DateTime.fromMillisecondsSinceEpoch((unixTimestamp * 1000).round());
        }
      }
    }
    
    // Fallback to current time
    return DateTime.now();
  }

  Future<Uint8List> _encryptData(String data, String password) async {
    final iv = IV.fromSecureRandom(16);

    // Create password-derived key
    final passwordBytes = utf8.encode(password + _saltPrefix);
    final hashedPassword = sha256.convert(passwordBytes);
    final finalKey = encrypt.Key(Uint8List.fromList(hashedPassword.bytes));
    
    final finalEncrypter = Encrypter(AES(finalKey));
    final encrypted = finalEncrypter.encrypt(data, iv: iv);

    // Combine IV + encrypted data
    final result = Uint8List(iv.bytes.length + encrypted.bytes.length);
    result.setRange(0, iv.bytes.length, iv.bytes);
    result.setRange(iv.bytes.length, result.length, encrypted.bytes);

    return result;
  }

  Future<String> _decryptData(Uint8List data, String password) async {
    try {
      // Extract IV and encrypted data
      final iv = IV(data.sublist(0, 16));
      final encryptedBytes = data.sublist(16);

      // Create password-derived key
      final passwordBytes = utf8.encode(password + _saltPrefix);
      final hashedPassword = sha256.convert(passwordBytes);
      final key = encrypt.Key(Uint8List.fromList(hashedPassword.bytes));

      final encrypter = Encrypter(AES(key));
      final encrypted = Encrypted(encryptedBytes);
      
      return encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Entschlüsselung fehlgeschlagen: Falsches Passwort?');
    }
  }

  Future<BackupResult> _saveBackupWeb(
      Uint8List data, String filename, BackupInfo backupInfo) async {
    if (kIsWeb) {
      try {
        // Web download
        final dataString = String.fromCharCodes(data);
        final blob = html.Blob([dataString]);
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', filename)
          ..click();
        html.Url.revokeObjectUrl(url);
        
        return BackupResult.success(backupInfo: backupInfo);
      } catch (e) {
        return BackupResult.failure('Web-Download fehlgeschlagen: $e');
      }
    }
    return BackupResult.failure('Web-Plattform nicht verfügbar');
  }

  Future<BackupResult> _saveBackupNative(
      Uint8List data, String filename, BackupInfo backupInfo) async {
    try {
      final directory = await getApplicationSupportDirectory();
      final backupDir = Directory('${directory.path}/backups');
      
      if (!backupDir.existsSync()) {
        backupDir.createSync();
      }

      final file = File('${backupDir.path}/$filename');
      await file.writeAsBytes(data);

      return BackupResult.success(
        backupInfo: backupInfo,
        filePath: file.path,
      );
    } catch (e) {
      return BackupResult.failure('Datei speichern fehlgeschlagen: $e');
    }
  }

  Future<bool> _shareBackupWeb(String filePath) async {
    if (kIsWeb) {
      try {
        // Web sharing would use Web Share API if available
        return true;
      } catch (e) {
        return false;
      }
    }
    return false;
  }

  Future<BackupInfo?> _createBackupInfoFromFile(File file) async {
    try {
      final stat = file.statSync();
      final filename = file.uri.pathSegments.last;
      final isEncrypted = filename.endsWith('.ehbackup');

      if (!isEncrypted) {
        // Try to read unencrypted backup to get details
        try {
          final content = file.readAsStringSync();
          final json = jsonDecode(content);
          final backupData = BackupData.fromJson(json);

          return BackupInfo(
            id: backupData.metadata.backupId,
            filename: filename,
            createdAt: stat.modified,
            size: stat.size,
            clientCount: backupData.clients.length,
            appointmentCount: backupData.appointments.length,
            isEncrypted: false,
            deviceName: backupData.metadata.deviceName,
          );
        } catch (e) {
          // If JSON parsing fails, create basic info
        }
      }

      // For encrypted files or failed JSON parsing
      return BackupInfo(
        id: filename.replaceAll(RegExp(r'[^0-9]'), ''),
        filename: filename,
        createdAt: stat.modified,
        size: stat.size,
        clientCount: 0,
        appointmentCount: 0,
        isEncrypted: isEncrypted,
        deviceName: 'Unbekannt',
      );
    } catch (e) {
      return null;
    }
  }
}

class BackupResult {
  final bool success;
  final String? error;
  final BackupInfo? backupInfo;
  final String? filePath;

  BackupResult.success({this.backupInfo, this.filePath})
      : success = true,
        error = null;

  BackupResult.failure(this.error)
      : success = false,
        backupInfo = null,
        filePath = null;
}

class RestoreResult {
  final bool success;
  final String? error;
  final List<Client>? clients;
  final List<Appointment>? appointments;
  final List<String>? emailTargets;
  final AppSettings? settings;

  RestoreResult.success({
    this.clients,
    this.appointments,
    this.emailTargets,
    this.settings,
  })  : success = true,
        error = null;

  RestoreResult.failure(this.error)
      : success = false,
        clients = null,
        appointments = null,
        emailTargets = null,
        settings = null;
}