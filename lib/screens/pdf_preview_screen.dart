import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

/// Generischer PDF-Vorschau-Screen mit Druck- und Speicherfunktionen.
class PdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;
  final String title;
  final String fileName;

  const PdfPreviewScreen({
    super.key,
    required this.pdfBytes,
    required this.title,
    required this.fileName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        canChangePageFormat: true,
        canChangeOrientation: true,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: fileName,
        useActions: true,
        loadingWidget: const Center(child: CircularProgressIndicator()),
        previewPageMargin: const EdgeInsets.all(16),
      ),
    );
  }
}
