import 'dart:typed_data';
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
import '../providers/app_provider.dart';
import 'pdf_generator_service.dart';
import 'package:intl/intl.dart';

class ExportService {
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

  static IconData _getFormatIcon(ExportFormat format) {
    switch (format) {
      case ExportFormat.pdf:
        return Icons.picture_as_pdf;
      case ExportFormat.word:
        return Icons.description;
      case ExportFormat.markdown:
        return Icons.code;
      case ExportFormat.csv:
        return Icons.table_chart;
      case ExportFormat.txt:
        return Icons.text_snippet;
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
          bytes = _generateWord(content);
          break;
        case ExportFormat.markdown:
          bytes = _generateMarkdown(content);
          break;
        case ExportFormat.csv:
          bytes = _generateCSV(arbeitszeiten, appointments, clients);
          break;
        case ExportFormat.txt:
          bytes = Uint8List.fromList(content.codeUnits);
          break;
      }

      if (!context.mounted) return false;
      return await saveAndShare(
        context: context,
        bytes: bytes,
        filename: '$filename.${format.extension}',
        mimeType: format.mimeType,
      );
    } catch (e) {
      debugPrint('Export error: $e');
      return false;
    }
  }

  /// Zentrale Methode zum Speichern und Teilen von exportierten Dateien.
  ///
  /// - **Desktop:** FilePicker → User wählt Speicherort → optional Datei öffnen → grüner SnackBar mit "Ordner öffnen"
  /// - **Mobile:** Temp-Datei → Share-Dialog
  /// - **Web:** Blob-Download
  static Future<bool> saveAndShare({
    required BuildContext context,
    required Uint8List bytes,
    required String filename,
    required String mimeType,
    bool openAfterSave = false,
  }) async {
    try {
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
        // Mobile: Share-Dialog
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/$filename');
        await file.writeAsBytes(bytes);

        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path)],
          ),
        );
        return true;
      }
    } catch (e) {
      debugPrint('saveAndShare error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
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
    // Verwende die neue erweiterte PDF-Generierung
    if (exportType == 'arbeitszeiten' && arbeitszeiten != null && startDate != null && endDate != null) {
      return await PdfGeneratorService.generateArbeitszeitenPDF(content, arbeitszeiten, startDate, endDate);
    } else if (exportType == 'fachleistungsstunden' && appointments != null && startDate != null && endDate != null) {
      return await PdfGeneratorService.generateFachleistungsstundenPDF(content, appointments, startDate, endDate);
    } else if (exportType == 'klienten' && clients != null) {
      return await PdfGeneratorService.generateKlientenPDF(content, clients);
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

  static Uint8List _generateWord(String content) {
    // Vereinfachte Word-Generierung (als RTF)
    String rtfContent = '''
{\\rtf1\\ansi\\deff0 {\\fonttbl {\\f0 Times New Roman;}}
\\f0\\fs24
Eingliederungshilfe Export\\par
\\par
Erstellt: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}\\par
\\par
${content.replaceAll('\n', '\\par\n')}
}''';
    return Uint8List.fromList(rtfContent.codeUnits);
  }

  static Uint8List _generateMarkdown(String content) {
    String markdownContent = '''
# Eingliederungshilfe Export

**Erstellt:** ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}

---

$content
''';
    return Uint8List.fromList(markdownContent.codeUnits);
  }

  static Uint8List _generateCSV(List<Arbeitszeit>? arbeitszeiten, List<Appointment>? appointments, List<Client>? clients) {
    List<String> csvLines = [];

    if (arbeitszeiten != null && arbeitszeiten.isNotEmpty) {
      csvLines.add('=== ARBEITSZEITEN ===');
      csvLines.add('Datum,Startzeit,Endzeit,Tätigkeit,Dauer (Stunden),Notizen');
      for (var az in arbeitszeiten) {
        csvLines.add('"${DateFormat('dd.MM.yyyy').format(az.datum)}",'
            '"${az.formatierteStartzeit}",'
            '"${az.formatierteEndzeit}",'
            '"${az.taetigkeit.replaceAll('"', '""')}",'
            '"${(az.arbeitszeit.inMinutes / 60.0).toStringAsFixed(2)}",'
            '"${az.notizen.replaceAll('"', '""')}"');
      }
      csvLines.add('');
    }

    if (appointments != null && appointments.isNotEmpty) {
      csvLines.add('=== TERMINE ===');
      csvLines.add('Datum,Startzeit,Endzeit,Klient,Berufsgruppe,Fachleistungsstunden,Notizen');
      for (var apt in appointments) {
        csvLines.add('"${DateFormat('dd.MM.yyyy').format(apt.date)}",'
            '"${DateFormat('HH:mm').format(apt.startTime)}",'
            '"${DateFormat('HH:mm').format(apt.endTime)}",'
            '"${apt.clientName.replaceAll('"', '""')}",'
            '"${apt.berufsgruppe.replaceAll('"', '""')}",'
            '"${apt.fachleistungsstunden}",'
            '"${apt.notes.replaceAll('"', '""')}"');
      }
      csvLines.add('');
    }

    if (clients != null && clients.isNotEmpty) {
      csvLines.add('=== KLIENTEN ===');
      csvLines.add('Name,Berufsgruppe,Eingliederung,Kostenübernahme,Betreuung seit,Fachleistungsstunden,Verbrauchte Stunden');
      for (var client in clients) {
        csvLines.add('"${client.vollstaendigerName.replaceAll('"', '""')}",'
            '"${(client.berufsgruppe ?? '').replaceAll('"', '""')}",'
            '"${(client.eingliederung ?? '').replaceAll('"', '""')}",'
            '"${(client.kostenuebernahme ?? '').replaceAll('"', '""')}",'
            '"${client.betreuungSeit != null ? DateFormat('dd.MM.yyyy').format(client.betreuungSeit!) : ''}",'
            '"${client.fachleistungsstunden ?? 0}",'
            '"${client.verbrauchteStunden}"');
      }
    }

    return Uint8List.fromList(csvLines.join('\n').codeUnits);
  }
}