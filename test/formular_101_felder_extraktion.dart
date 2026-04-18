import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

void main() {
  test('Alle IB_S3-Felder extrahieren', () {
    final bytes = File('C:/fegh/assets/informationsbericht_101.pdf').readAsBytesSync();
    final doc = PdfDocument(inputBytes: bytes);
    final form = doc.form;
    final felder = <String>[];
    for (int i = 0; i < form.fields.count; i++) {
      final n = form.fields[i].name;
      if (n != null && n.startsWith('IB_S3_')) {
        felder.add(n);
      }
    }
    felder.sort();
    // ignore: avoid_print
    print('S3-Felder: ${felder.length}');
    // ignore: avoid_print
    for (final f in felder) { print(f); }
    doc.dispose();
  });
}
