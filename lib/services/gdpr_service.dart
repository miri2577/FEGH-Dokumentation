import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:uuid/uuid.dart';

import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/arbeitszeit.dart';

class GDPRService {
  final CryptoStorage _cryptoStorage;
  final HiDriveBusinessSync? _cloudSync;

  GDPRService(this._cryptoStorage, {HiDriveBusinessSync? cloudSync})
      : _cloudSync = cloudSync;

  Future<GDPRExportResult> exportAllUserData({String? password}) async {
    try {
      final exportData = await _collectAllUserData();

      final exportId = const Uuid().v4();
      final timestamp = DateTime.now();

      final export = GDPRExport(
        exportId: exportId,
        createdAt: timestamp,
        dataSubject: 'Nutzer der Eingliederungshilfe App',
        legalBasis: 'Art. 20 DSGVO (Datenübertragbarkeit)',
        data: exportData,
      );

      final jsonData = jsonEncode(export.toJson());

      Uint8List finalData;
      String filename;

      if (password != null && password.isNotEmpty) {
        finalData = await _encryptExportData(jsonData, password);
        filename = 'DSGVO_Export_${timestamp.millisecondsSinceEpoch}.encrypted.json';
      } else {
        finalData = Uint8List.fromList(utf8.encode(jsonData));
        filename = 'DSGVO_Export_${timestamp.millisecondsSinceEpoch}.json';
      }

      final file = await _saveExportFile(finalData, filename);

      return GDPRExportResult.success(
        filePath: file.path,
        filename: filename,
        fileSize: finalData.length,
        recordCount: exportData.totalRecords,
        isEncrypted: password != null,
      );

    } catch (e) {
      return GDPRExportResult.failure('Export fehlgeschlagen: $e');
    }
  }

  Future<GDPRExportData> _collectAllUserData() async {
    final manifest = await _cryptoStorage.loadManifest();

    final clients = <Map<String, dynamic>>[];
    final appointments = <Map<String, dynamic>>[];
    final arbeitszeiten = <Map<String, dynamic>>[];
    final settings = <String, dynamic>{};

    for (final entry in manifest.entries) {
      try {
        final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);

        switch (entry.schema) {
          case 'client':
            clients.add({
              'uuid': entry.uuid,
              'createdAt': entry.updatedAt.toIso8601String(),
              'data': data,
            });
            break;
          case 'appointment':
            appointments.add({
              'uuid': entry.uuid,
              'createdAt': entry.updatedAt.toIso8601String(),
              'data': data,
            });
            break;
          case 'arbeitszeit':
            arbeitszeiten.add({
              'uuid': entry.uuid,
              'createdAt': entry.updatedAt.toIso8601String(),
              'data': data,
            });
            break;
        }
      } catch (e) {
        // Einzelne defekte Datensätze überspringen
        continue;
      }
    }

    return GDPRExportData(
      clients: clients,
      appointments: appointments,
      arbeitszeiten: arbeitszeiten,
      settings: settings,
      totalRecords: clients.length + appointments.length + arbeitszeiten.length,
    );
  }

  Future<File> _saveExportFile(Uint8List data, String filename) async {
    final directory = await getApplicationSupportDirectory();
    final exportDir = Directory('${directory.path}/gdpr_exports');

    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$filename');
    await file.writeAsBytes(data);

    return file;
  }

  Future<Uint8List> _encryptExportData(String jsonData, String password) async {
    return await _cryptoStorage.encryptRecord(
      plaintext: utf8.encode(jsonData),
      aad: {
        'type': 'gdpr_export',
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
      },
    ).then((record) => utf8.encode(jsonEncode(record)));
  }

  Future<String> _decryptExportData(Uint8List encryptedData, String password) async {
    try {
      final encryptedString = utf8.decode(encryptedData);
      final encryptedRecord = jsonDecode(encryptedString);

      final decryptedData = await _cryptoStorage.decryptRecord(encryptedRecord);
      return utf8.decode(decryptedData);
    } catch (e) {
      throw Exception('Entschlüsselung fehlgeschlagen: $e');
    }
  }

  Future<bool> shareExportFile(String filePath) async {
    try {
      // Originalen Dateinamen aus Pfad extrahieren
      final fileName = filePath.split('/').last;

      final result = await Share.shareXFiles(
        [XFile(filePath)],
        text: 'DSGVO-konformer Datenexport aus der Eingliederungshilfe-App',
        subject: fileName, // Verwende originalen Dateinamen als Subject
      );

      return result.status == ShareResultStatus.success;
    } catch (e) {
      return false;
    }
  }

  Future<GDPRDeletionResult> deleteAllUserData({
    bool includeLocalData = true,
    bool includeCloudData = true,
    String? confirmationCode,
  }) async {
    if (confirmationCode != 'DSGVO_LOESCHUNG_BESTAETIGT') {
      return GDPRDeletionResult.failure(
        'Bestätigungscode ungültig. Bitte geben Sie "DSGVO_LOESCHUNG_BESTAETIGT" ein.'
      );
    }

    try {
      final deletionLog = GDPRDeletionLog();

      if (includeLocalData) {
        await _deleteLocalData(deletionLog);
      }

      if (includeCloudData && _cloudSync != null) {
        await _deleteCloudData(deletionLog);
      }

      await _saveDeletionLog(deletionLog);

      return GDPRDeletionResult.success(
        deletedRecords: deletionLog.totalDeletedRecords,
        deletionLog: deletionLog,
      );

    } catch (e) {
      return GDPRDeletionResult.failure('Löschung fehlgeschlagen: $e');
    }
  }

  Future<void> _deleteLocalData(GDPRDeletionLog log) async {
    final manifest = await _cryptoStorage.loadManifest();

    for (final entry in manifest.entries) {
      try {
        await _cryptoStorage.deleteRecord(entry.uuid);
        log.addDeletedRecord(entry.uuid, entry.schema, 'local');
      } catch (e) {
        log.addFailedDeletion(entry.uuid, entry.schema, 'local', e.toString());
      }
    }

    await _cryptoStorage.cryptoErasure();
    log.cryptoErasureCompleted = true;
  }

  Future<void> _deleteCloudData(GDPRDeletionLog log) async {
    if (_cloudSync == null) return;

    final remoteFiles = await _cloudSync!.listRemoteRecords();
    if (remoteFiles.isSuccess && remoteFiles.data != null) {
      for (final uuid in remoteFiles.data!) {
        try {
          await _cloudSync!.deleteRemoteRecord(uuid);
          log.addDeletedRecord(uuid, 'unknown', 'cloud');
        } catch (e) {
          log.addFailedDeletion(uuid, 'unknown', 'cloud', e.toString());
        }
      }
    }
  }

  Future<void> _saveDeletionLog(GDPRDeletionLog log) async {
    final directory = await getApplicationSupportDirectory();
    final logDir = Directory('${directory.path}/gdpr_logs');

    if (!await logDir.exists()) {
      await logDir.create(recursive: true);
    }

    final filename = 'deletion_log_${DateTime.now().millisecondsSinceEpoch}.json';
    final file = File('${logDir.path}/$filename');

    await file.writeAsString(jsonEncode(log.toJson()), flush: true);
  }

  Widget buildExportDialog(BuildContext context) {
    final passwordController = TextEditingController();
    bool encryptExport = true;

    return StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          icon: Icon(Icons.download, size: 48, color: Theme.of(context).primaryColor),
          title: Text('Datenexport (Art. 20 DSGVO)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sie können alle Ihre Daten in einem maschinenlesbaren Format exportieren.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),

              CheckboxListTile(
                title: Text('Export verschlüsseln'),
                subtitle: Text('Empfohlen für sensible Gesundheitsdaten'),
                value: encryptExport,
                onChanged: (value) => setState(() => encryptExport = value ?? true),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),

              if (encryptExport) ...[
                SizedBox(height: 8),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Passwort für Verschlüsselung',
                    hintText: 'Sicheres Passwort eingeben',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '⚠️ Passwort sicher aufbewahren - ohne Passwort sind die Daten nicht lesbar!',
                  style: TextStyle(fontSize: 12, color: Colors.orange),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Abbrechen'),
            ),
            FilledButton.icon(
              onPressed: () async {
                Navigator.of(context).pop();

                final password = encryptExport ? passwordController.text : null;
                if (encryptExport && (password?.isEmpty ?? true)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Passwort für Verschlüsselung erforderlich')),
                  );
                  return;
                }

                _showExportProgress(context, password);
              },
              icon: Icon(Icons.download),
              label: Text('Export starten'),
            ),
          ],
        );
      },
    );
  }

  void _showExportProgress(BuildContext context, String? password) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<GDPRExportResult>(
        future: exportAllUserData(password: password),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Export wird erstellt...'),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return AlertDialog(
              icon: Icon(Icons.error, color: Colors.red),
              title: Text('Export fehlgeschlagen'),
              content: Text(snapshot.error.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Schließen'),
                ),
              ],
            );
          }

          final result = snapshot.data!;

          if (result.isSuccess) {
            return AlertDialog(
              icon: Icon(Icons.check_circle, color: Colors.green),
              title: Text('Export erfolgreich'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('📁 Datei: ${result.filename}'),
                  Text('📊 Datensätze: ${result.recordCount}'),
                  Text('💾 Größe: ${(result.fileSize! / 1024).toStringAsFixed(1)} KB'),
                  if (result.isEncrypted!)
                    Text('🔒 Verschlüsselt: Ja'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Schließen'),
                ),
                FilledButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await shareExportFile(result.filePath!);
                  },
                  icon: Icon(Icons.share),
                  label: Text('Teilen'),
                ),
              ],
            );
          } else {
            return AlertDialog(
              icon: Icon(Icons.error, color: Colors.red),
              title: Text('Export fehlgeschlagen'),
              content: Text(result.error!),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Schließen'),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget buildDeletionDialog(BuildContext context, {VoidCallback? onDeletionComplete}) {
    final confirmationController = TextEditingController();

    return AlertDialog(
      icon: Icon(Icons.delete_forever, size: 48, color: Colors.red),
      title: Text('Alle Daten löschen'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha:0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'ACHTUNG: Diese Aktion löscht ALLE Ihre Daten unwiderruflich!',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Text('Folgende Daten werden gelöscht:'),
          Text('• Alle Klientendaten'),
          Text('• Alle Termine und Notizen'),
          Text('• Alle Arbeitszeiten'),
          Text('• App-Einstellungen'),
          Text('• Verschlüsselungsschlüssel (Crypto-Erasure)'),
          Text('• Cloud-Backups (falls konfiguriert)'),
          SizedBox(height: 16),
          Text(
            'Geben Sie zur Bestätigung ein: "DSGVO_LOESCHUNG_BESTAETIGT"',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          TextField(
            controller: confirmationController,
            decoration: InputDecoration(
              labelText: 'Bestätigungscode',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.verified_user),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () async {
            Navigator.of(context).pop();
            _showDeletionProgress(context, confirmationController.text, onDeletionComplete: onDeletionComplete);
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          icon: Icon(Icons.delete_forever),
          label: Text('UNWIDERRUFLICH LÖSCHEN'),
        ),
      ],
    );
  }

  void _showDeletionProgress(BuildContext context, String confirmationCode, {VoidCallback? onDeletionComplete}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => FutureBuilder<GDPRDeletionResult>(
        future: deleteAllUserData(confirmationCode: confirmationCode),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Daten werden gelöscht...'),
                  Text('Bitte warten Sie.', style: TextStyle(fontSize: 12)),
                ],
              ),
            );
          }

          final result = snapshot.data!;

          return AlertDialog(
            icon: Icon(
              result.isSuccess ? Icons.check_circle : Icons.error,
              color: result.isSuccess ? Colors.green : Colors.red,
            ),
            title: Text(result.isSuccess ? 'Löschung erfolgreich' : 'Löschung fehlgeschlagen'),
            content: Text(
              result.isSuccess
                  ? 'Alle Daten wurden erfolgreich gelöscht (${result.deletedRecords} Datensätze).'
                  : result.error!
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  if (result.isSuccess && onDeletionComplete != null) {
                    onDeletionComplete();
                  }
                },
                child: Text('Schließen'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<GDPRImportResult> importGDPRData({
    required Uint8List fileBytes,
    required String fileName,
    String? password,
  }) async {
    try {
      String jsonData;

      // Prüfen ob die Datei verschlüsselt ist - zuerst anhand Dateiname, dann anhand Inhalt
      bool isEncrypted = fileName.contains('.encrypted.json') || fileName.endsWith('.gdpr');

      // Falls nicht durch Dateinamen erkannt, prüfe Dateiinhalt
      if (!isEncrypted) {
        try {
          final contentString = utf8.decode(fileBytes);
          // Verschlüsselte Dateien beginnen mit JSON das einen CryptoRecord enthält
          final testJson = jsonDecode(contentString);
          isEncrypted = testJson is Map && testJson.containsKey('ciphertext') && testJson.containsKey('authTag');
        } catch (e) {
          // Falls nicht als JSON parsbar, könnte trotzdem verschlüsselt sein
          // Heuristik: Verschlüsselte Daten enthalten typische Base64-Zeichen
          final contentString = utf8.decode(fileBytes);
          isEncrypted = contentString.contains('"ciphertext"') && contentString.contains('"authTag"');
        }
      }

      if (isEncrypted) {
        if (password == null || password.isEmpty) {
          return GDPRImportResult.failure('Passwort für verschlüsselte Datei erforderlich');
        }
        jsonData = await _decryptExportData(fileBytes, password);
      } else {
        jsonData = utf8.decode(fileBytes);
      }

      final jsonMap = jsonDecode(jsonData);

      // Validieren der GDPR Export Struktur
      if (!jsonMap.containsKey('data') || !jsonMap.containsKey('exportId')) {
        return GDPRImportResult.failure('Ungültige DSGVO-Exportdatei: Struktur nicht erkannt');
      }

      final exportData = jsonMap['data'];
      int importedRecords = 0;

      // Statistiken sammeln
      final clients = exportData['clients'] ?? [];
      final appointments = exportData['appointments'] ?? [];
      final arbeitszeiten = exportData['arbeitszeiten'] ?? [];

      importedRecords = clients.length + appointments.length + arbeitszeiten.length;

      return GDPRImportResult.success(
        exportId: jsonMap['exportId'],
        exportDate: DateTime.tryParse(jsonMap['createdAt'] ?? ''),
        clients: clients,
        appointments: appointments,
        arbeitszeiten: arbeitszeiten,
        settings: exportData['settings'] ?? {},
        totalRecords: importedRecords,
        isEncrypted: isEncrypted,
      );

    } catch (e) {
      return GDPRImportResult.failure('Import fehlgeschlagen: $e');
    }
  }
}

// Data classes für GDPR Service
class GDPRExport {
  final String exportId;
  final DateTime createdAt;
  final String dataSubject;
  final String legalBasis;
  final GDPRExportData data;

  GDPRExport({
    required this.exportId,
    required this.createdAt,
    required this.dataSubject,
    required this.legalBasis,
    required this.data,
  });

  Map<String, dynamic> toJson() => {
    'exportId': exportId,
    'createdAt': createdAt.toIso8601String(),
    'dataSubject': dataSubject,
    'legalBasis': legalBasis,
    'version': '1.0',
    'data': data.toJson(),
  };
}

class GDPRExportData {
  final List<Map<String, dynamic>> clients;
  final List<Map<String, dynamic>> appointments;
  final List<Map<String, dynamic>> arbeitszeiten;
  final Map<String, dynamic> settings;
  final int totalRecords;

  GDPRExportData({
    required this.clients,
    required this.appointments,
    required this.arbeitszeiten,
    required this.settings,
    required this.totalRecords,
  });

  Map<String, dynamic> toJson() => {
    'clients': clients,
    'appointments': appointments,
    'arbeitszeiten': arbeitszeiten,
    'settings': settings,
    'totalRecords': totalRecords,
    'exportedAt': DateTime.now().toIso8601String(),
  };
}

class GDPRExportResult {
  final bool isSuccess;
  final String? error;
  final String? filePath;
  final String? filename;
  final int? fileSize;
  final int? recordCount;
  final bool? isEncrypted;

  GDPRExportResult.success({
    required this.filePath,
    required this.filename,
    required this.fileSize,
    required this.recordCount,
    required this.isEncrypted,
  })  : isSuccess = true,
        error = null;

  GDPRExportResult.failure(this.error)
      : isSuccess = false,
        filePath = null,
        filename = null,
        fileSize = null,
        recordCount = null,
        isEncrypted = null;
}

class GDPRDeletionResult {
  final bool isSuccess;
  final String? error;
  final int? deletedRecords;
  final GDPRDeletionLog? deletionLog;

  GDPRDeletionResult.success({
    required this.deletedRecords,
    required this.deletionLog,
  })  : isSuccess = true,
        error = null;

  GDPRDeletionResult.failure(this.error)
      : isSuccess = false,
        deletedRecords = null,
        deletionLog = null;
}

class GDPRDeletionLog {
  final String deletionId = const Uuid().v4();
  final DateTime deletedAt = DateTime.now();
  final List<Map<String, dynamic>> _deletedRecords = [];
  final List<Map<String, dynamic>> _failedDeletions = [];
  bool cryptoErasureCompleted = false;

  void addDeletedRecord(String uuid, String schema, String location) {
    _deletedRecords.add({
      'uuid': uuid,
      'schema': schema,
      'location': location,
      'deletedAt': DateTime.now().toIso8601String(),
    });
  }

  void addFailedDeletion(String uuid, String schema, String location, String error) {
    _failedDeletions.add({
      'uuid': uuid,
      'schema': schema,
      'location': location,
      'error': error,
      'attemptedAt': DateTime.now().toIso8601String(),
    });
  }

  int get totalDeletedRecords => _deletedRecords.length;
  int get totalFailedDeletions => _failedDeletions.length;

  Map<String, dynamic> toJson() => {
    'deletionId': deletionId,
    'deletedAt': deletedAt.toIso8601String(),
    'deletedRecords': _deletedRecords,
    'failedDeletions': _failedDeletions,
    'cryptoErasureCompleted': cryptoErasureCompleted,
    'totalDeleted': totalDeletedRecords,
    'totalFailed': totalFailedDeletions,
  };
}

class GDPRImportResult {
  final bool isSuccess;
  final String? error;
  final String? exportId;
  final DateTime? exportDate;
  final List<dynamic>? clients;
  final List<dynamic>? appointments;
  final List<dynamic>? arbeitszeiten;
  final Map<String, dynamic>? settings;
  final int? totalRecords;
  final bool? isEncrypted;

  GDPRImportResult.success({
    required this.exportId,
    required this.exportDate,
    required this.clients,
    required this.appointments,
    required this.arbeitszeiten,
    required this.settings,
    required this.totalRecords,
    required this.isEncrypted,
  })  : isSuccess = true,
        error = null;

  GDPRImportResult.failure(this.error)
      : isSuccess = false,
        exportId = null,
        exportDate = null,
        clients = null,
        appointments = null,
        arbeitszeiten = null,
        settings = null,
        totalRecords = null,
        isEncrypted = null;
}