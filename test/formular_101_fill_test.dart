import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:eingliederungshilfe_flutter/models/informationsbericht.dart';
import 'package:eingliederungshilfe_flutter/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Formular 101: Syncfusion-Fuellung produziert ein valides PDF', () async {
    // Asset Bundle in Tests laden
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      final bytes = File('C:/fegh/$key').readAsBytesSync();
      return ByteData.view(bytes.buffer);
    });

    final bericht = Informationsbericht.create(clientId: 'test-client-1').copyWith(
      teilhabefachdienst: 'Friedrichshain-Kreuzberg',
      idKostenuebernahme: '12345-67890',
      berichtszeitraumVon: DateTime(2026, 1, 1),
      berichtszeitraumBis: DateTime(2026, 4, 30),
      leistungstyp: 'Soziale Teilhabe',
      leistungserbringer: 'Sozialtraeger Musterfirma GmbH',
      emailTelNr: 'kontakt@muster.de / 030-12345678',
      strasse: 'Hauptstrasse',
      hausnummer: '1a',
      postleitzahl: '10115',
      ort: 'Berlin',
      anrede: 'Herr',
      familienname: 'Mustermann',
      vorname: 'Max',
      geburtsdatum: DateTime(1985, 5, 14),
      geschlecht: 'maennlich',
      familienstand: 'ledig',
      telefonFestnetz: '030-9876543',
      email: 'm.mustermann@example.de',
      allgemeineInformationen: 'Herr Mustermann wird seit 01.01.2026 in der sozialen Teilhabe '
          'begleitet. Schwerpunkte liegen auf der Foerderung der Selbstbestimmung '
          'im Alltag sowie der sozialen Integration.',
      zusammenfassung: 'Im Berichtszeitraum wurden deutliche Fortschritte in der '
          'selbstaendigen Alltagsbewaeltigung erzielt. Weiterer Unterstuetzungsbedarf besteht.',
      ortDatum: 'Berlin, ${DateTime.now().day.toString().padLeft(2, '0')}.${DateTime.now().month.toString().padLeft(2, '0')}.${DateTime.now().year}',
      leistungserbringerUnterschrift: 'Anna Fachkraft',
      eintragungKlient: 'Ich bin einverstanden. -Max Mustermann-',
    );

    final pdfBytes = await PdfGeneratorService.generateInformationsberichtSyncfusion(bericht);

    expect(pdfBytes, isNotEmpty);
    // Ein ausgefuelltes Template sollte signifikant sein
    expect(pdfBytes.length, greaterThan(500000));

    // Zum manuellen Ansehen speichern
    File('C:/Users/MIRKOR~1/AppData/Local/Temp/formular_101_gefuellt.pdf')
        .writeAsBytesSync(pdfBytes);

    // Pruefen ob die Werte im PDF-Formular gesetzt sind
    final doc = PdfDocument(inputBytes: pdfBytes);
    final form = doc.form;
    int textFelderMitWerten = 0;
    for (int i = 0; i < form.fields.count; i++) {
      final f = form.fields[i];
      if (f is PdfTextBoxField && f.text.isNotEmpty) {
        textFelderMitWerten++;
      }
    }
    // ignore: avoid_print
    print('Gefuellte Textfelder: $textFelderMitWerten von ${form.fields.count}');
    expect(textFelderMitWerten, greaterThan(15),
        reason: 'Mindestens 15 Textfelder sollten befuellt sein');
    doc.dispose();
  });
}
