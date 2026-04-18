import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:universal_html/html.dart' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/export_format.dart';
import '../models/arbeitszeit.dart';
import '../models/appointment.dart';
import '../models/client.dart';
import 'dart:convert' show utf8;
import 'docx_report_service.dart';
import 'pdf_report_service.dart';
import 'package:intl/intl.dart';

class ExportService {
  /// Zeigt den Format-Dialog (PDF/Word/CSV). Speichern-Pfad ist Default.
  static Future<ExportFormat?> showFormatSelectionDialog(BuildContext context) async {
    return showDialog<ExportFormat>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export-Format wählen'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ExportFormat.values.map((format) =>
            ListTile(
              leading: Icon(_getFormatIcon(format)),
              title: Text(format.displayName),
              subtitle: Text('.${format.extension}'),
              onTap: () => Navigator.of(context).pop(format),
            ),
          ).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );
  }

  /// Kombi-Dialog: waehlt Format UND Ziel (speichern vs. senden).
  /// Rueckgabe: null bei Abbruch, sonst (Format, ExportZiel).
  static Future<ExportOptions?> showFormatAndDestinationDialog(BuildContext context) async {
    return showDialog<ExportOptions>(
      context: context,
      builder: (context) => _FormatAndDestinationDialog(),
    );
  }

  static IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.word:
        return Icons.description;
      case ExportFormat.csv:
        return Icons.table_chart;
    }
  }

  static Future<String?> selectSaveLocation(BuildContext context, String filename, ExportFormat format) async {
    if (kIsWeb) {
      return null; // Web verwendet automatischen Download
    }

    try {
      String? outputFile = await FilePicker.platform.saveFile(
        dialogTitle: 'Speicherort wählen',
        fileName: '$filename.${format.extension}',
        type: FileType.custom,
        allowedExtensions: [format.extension],
      );
      return outputFile;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> exportData({
    required BuildContext context,
    required String content,
    required String filename,
    required ExportFormat format,
    ExportZiel ziel = ExportZiel.speichern,
    List<Arbeitszeit>? arbeitszeiten,
    List<Appointment>? appointments,
    List<Client>? clients,
    DateTime? startDate,
    DateTime? endDate,
    String? exportType,
  }) async {
    try {
      Uint8List bytes;

      switch (format) {
        case ExportFormat.pdf:
          bytes = await _generatePDF(
            content,
            arbeitszeiten,
            appointments,
            clients,
            startDate,
            endDate,
            exportType,
          );
          break;
        case ExportFormat.word:
          bytes = await _generateDocx(
            arbeitszeiten,
            appointments,
            clients,
            startDate,
            endDate,
            exportType,
          );
          break;
        case ExportFormat.csv:
          // Aufrufer liefert bereits Semikolon-CSV; mit UTF-8-BOM verpacken
          final bom = [0xEF, 0xBB, 0xBF];
          bytes = Uint8List.fromList([...bom, ...utf8.encode(content)]);
          break;
      }

      if (!context.mounted) return false;
      return await saveAndShare(
        context: context,
        bytes: bytes,
        filename: '$filename.${format.extension}',
        mimeType: format.mimeType,
        ziel: ziel,
      );
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }

  /// Zentrale Methode zum Speichern UND/ODER Teilen von exportierten Dateien.
  ///
  /// [ziel] steuert das Verhalten:
  /// - `speichern`: Desktop zeigt FilePicker, Web loest Download aus
  /// - `teilen`: OS-Share-Dialog (E-Mail, Cloud, ...) auf allen Plattformen
  static Future<bool> saveAndShare({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    bool openAfterSave = false,
    ExportZiel ziel = ExportZiel.speichern,
  }) async {
    try {
      // TEILEN: OS-Share-Dialog (E-Mail, Messenger, Cloud etc.)
      if (ziel == ExportZiel.teilen) {
        if (kIsWeb) {
          _downloadWeb(bytes, filename, mimeType);
          return true;
        }
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
            subject: 'Export aus FEGH-Dokumentation',
          ),
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Bereit zum Teilen: ${p.basename(filename)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return true;
      }

      // SPEICHERN
      if (kIsWeb) {
        _downloadWeb(bytes, filename, mimeType);
        return true;
      }

      if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
        // Desktop: FilePicker
        final ext = p.extension(filename).replaceFirst('.', '');
        String? savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Speicherort wählen',
          fileName: filename,
          type: FileType.custom,
          allowedExtensions: [if (ext.isNotEmpty) ext],
        );
        if (savePath == null) return false; // Abgebrochen

        await File(savePath).writeAsBytes(bytes);

        if (openAfterSave) {
          await _openFile(savePath);
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Datei gespeichert: ${p.basename(savePath)}'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Ordner öffnen',
                textColor: Colors.white,
                onPressed: () => _openFolder(savePath),
              ),
            ),
          );
        }
        return true;
      } else {
        // Mobile: Share-Dialog auch bei "speichern" (Mobile hat keinen FilePicker)
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);

        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)]),
        );
        return true;
      }
    } catch (e) {
      debugPrint('saveAndShare error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return false;
    }
  }

  static Future<void> _openFile(String filePath) async {
    if (Platform.isMacOS) {
      await Process.run('open', [filePath]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', filePath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [filePath]);
    }
  }

  static Future<void> _openFolder(String filePath) async {
    final folder = p.dirname(filePath);
    if (Platform.isMacOS) {
      await Process.run('open', [folder]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', [folder]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [folder]);
    }
  }

  static void _downloadWeb(Uint8List bytes, String filename, String mimeType) {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = filename;
    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  static Future<Uint8List> _generatePDF(
    String content,
    List<Arbeitszeit>? arbeitszeiten,
    List<Appointment>? appointments,
    List<Client>? clients,
    DateTime? startDate,
    DateTime? endDate,
    String? exportType,
  ) async {
    // Neuer Hybrid-Report-Service (einheitliches Design-System)
    if (exportType == 'arbeitszeiten' && arbeitszeiten != null && startDate != null && endDate != null) {
      return await PdfReportService.generateArbeitszeitenReport(
        arbeitszeiten: arbeitszeiten, startDate: startDate, endDate: endDate);
    } else if (exportType == 'fachleistungsstunden' && appointments != null && startDate != null && endDate != null) {
      return await PdfReportService.generateFachleistungsstundenReport(
        appointments: appointments, startDate: startDate, endDate: endDate);
    } else if (exportType == 'klienten' && clients != null) {
      return await PdfReportService.generateKlientenReport(clients: clients);
    } else {
      // Fallback für einfache PDF-Generierung
      final pdf = pw.Document();

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          build: (pw.Context context) {
            return [
              pw.Header(
                level: 0,
                child: pw.Text(
                  'Eingliederungshilfe Export',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Paragraph(
                text: 'Erstellt: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 20),
              pw.Text(content, style: const pw.TextStyle(fontSize: 10)),
            ];
          },
        ),
      );

      return pdf.save();
    }
  }

  /// Echtes DOCX (OpenXML) via DocxReportService im Hybrid-Design.
  static Future<Uint8List> _generateDocx(
    List<Arbeitszeit>? arbeitszeiten,
    List<Appointment>? appointments,
    List<Client>? clients,
    DateTime? startDate,
    DateTime? endDate,
    String? exportType,
  ) async {
    if (exportType == 'arbeitszeiten' && arbeitszeiten != null && startDate != null && endDate != null) {
      return await DocxReportService.generateArbeitszeitenDocx(
        arbeitszeiten: arbeitszeiten, startDate: startDate, endDate: endDate);
    } else if (exportType == 'fachleistungsstunden' && appointments != null && startDate != null && endDate != null) {
      return await DocxReportService.generateFachleistungsstundenDocx(
        appointments: appointments, startDate: startDate, endDate: endDate);
    } else if (exportType == 'klienten' && clients != null) {
      return await DocxReportService.generateKlientenDocx(clients: clients);
    }
    // Fallback: leeres Dokument mit Hinweis
    return await DocxReportService.generateKlientenDocx(clients: []);
  }

}

/// Wohin soll der Export gehen?
enum ExportZiel {
  /// Lokale Datei speichern (Desktop: FilePicker, Web: Download)
  speichern,

  /// OS-Share-Dialog oeffnen (E-Mail, Cloud, Messenger ...)
  teilen,
}

/// Ergebnis der Format-Auswahl mit Ziel.
class ExportOptions {
  final ExportFormat format;
  final ExportZiel ziel;
  const ExportOptions({required this.format, required this.ziel});
}

/// Kombinierter Dialog fuer Format + Ziel.
class _FormatAndDestinationDialog extends StatefulWidget {
  @override
  State<_FormatAndDestinationDialog> createState() =>
      _FormatAndDestinationDialogState();
}

class _FormatAndDestinationDialogState
    extends State<_FormatAndDestinationDialog> {
  ExportFormat _format = ExportFormat.pdf;
  ExportZiel _ziel = ExportZiel.speichern;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Format',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: ExportFormat.values.map((f) {
              final selected = _format == f;
              return ChoiceChip(
                label: Text(f.displayName),
                avatar: Icon(ExportService._getFormatIcon(f), size: 16),
                selected: selected,
                onSelected: (_) => setState(() => _format = f),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          const Text('Ziel',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 6),
          RadioGroup<ExportZiel>(
            groupValue: _ziel,
            onChanged: (v) => setState(() => _ziel = v!),
            child: const Column(
              children: [
                RadioListTile<ExportZiel>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ExportZiel.speichern,
                  title: Text('Lokal speichern'),
                  subtitle: Text('Speicherort wählen',
                      style: TextStyle(fontSize: 12)),
                  secondary: Icon(Icons.save_alt, size: 20),
                ),
                RadioListTile<ExportZiel>(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: ExportZiel.teilen,
                  title: Text('Teilen / Per E-Mail'),
                  subtitle: Text('Öffnet Teilen-Dialog des Systems',
                      style: TextStyle(fontSize: 12)),
                  secondary: Icon(Icons.share, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Abbrechen'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(
            context,
            ExportOptions(format: _format, ziel: _ziel),
          ),
          icon: Icon(_ziel == ExportZiel.teilen ? Icons.share : Icons.save_alt),
          label: Text(_ziel == ExportZiel.teilen ? 'Teilen' : 'Speichern'),
        ),
      ],
    );
  }
}