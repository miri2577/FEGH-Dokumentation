import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Eintrag in der Dokumentenablage
class StoredDocument {
  final String filename;
  final DateTime createdAt;
  final int sizeBytes;
  final String fullPath;

  StoredDocument({
    required this.filename,
    required this.createdAt,
    required this.sizeBytes,
    required this.fullPath,
  });

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

/// Verwaltung der lokal generierten PDF-Dokumente (DSGVO-konform)
class DocumentStorageService {
  static const _subDir = 'fegh_dokumente';

  /// Liefert den App-spezifischen Dokumentenordner
  Future<Directory> getDocumentDirectory() async {
    if (kIsWeb) throw UnsupportedError('Web wird nicht unterstützt');
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(base.path, _subDir));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Speichert ein PDF und gibt den Dateipfad zurück
  Future<String> saveDocument(List<int> bytes, String filename) async {
    final dir = await getDocumentDirectory();
    final safeName = _sanitizeFilename(filename);
    final file = File(p.join(dir.path, safeName));
    await file.writeAsBytes(bytes);
    return file.path;
  }

  /// Listet alle gespeicherten Dokumente auf
  Future<List<StoredDocument>> listDocuments() async {
    try {
      final dir = await getDocumentDirectory();
      final files = await dir.list().toList();
      final docs = <StoredDocument>[];
      for (final entity in files) {
        if (entity is File && entity.path.endsWith('.pdf')) {
          final stat = await entity.stat();
          docs.add(StoredDocument(
            filename: p.basename(entity.path),
            createdAt: stat.modified,
            sizeBytes: stat.size,
            fullPath: entity.path,
          ));
        }
      }
      docs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return docs;
    } catch (_) {
      return [];
    }
  }

  /// Löscht ein einzelnes Dokument
  Future<void> deleteDocument(String fullPath) async {
    final file = File(fullPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Löscht alle Dokumente, die älter als [days] Tage sind
  Future<int> deleteOlderThan(int days) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final docs = await listDocuments();
    int count = 0;
    for (final doc in docs) {
      if (doc.createdAt.isBefore(cutoff)) {
        await deleteDocument(doc.fullPath);
        count++;
      }
    }
    return count;
  }

  /// Gibt den Pfad des Dokumenten-Ordners als lesbaren String zurück
  Future<String> getDocumentDirectoryPath() async {
    final dir = await getDocumentDirectory();
    return dir.path;
  }

  String _sanitizeFilename(String name) {
    // Sonderzeichen entfernen, Leerzeichen durch Underscores ersetzen
    return name.replaceAll(RegExp(r'[^\w\.\-]'), '_');
  }
}
