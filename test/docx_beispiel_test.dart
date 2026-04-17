import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/models/arbeitszeit.dart';
import 'package:eingliederungshilfe_flutter/models/client.dart';
import 'package:eingliederungshilfe_flutter/services/docx_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DOCX-Arbeitszeit-Beispiel', () async {
    final bytes = await DocxReportService.generateArbeitszeitenDocx(
      arbeitszeiten: [
        Arbeitszeit.create(
          datum: DateTime(2026, 3, 3),
          startzeit: DateTime(2026, 3, 3, 8),
          endzeit: DateTime(2026, 3, 3, 16, 30),
          taetigkeit: 'Kliententermin Frau Müller (Beratungsgespräch)',
          typ: ArbeitszeitTyp.betreuung,
          notizen: '',
        ),
        Arbeitszeit.create(
          datum: DateTime(2026, 3, 4),
          startzeit: DateTime(2026, 3, 4, 9),
          endzeit: DateTime(2026, 3, 4, 17),
          taetigkeit: 'Dokumentation und Bericht',
          typ: ArbeitszeitTyp.dokumentation,
          notizen: '',
        ),
        Arbeitszeit.create(
          datum: DateTime(2026, 3, 5),
          startzeit: DateTime(2026, 3, 5, 10),
          endzeit: DateTime(2026, 3, 5, 14),
          taetigkeit: 'Supervision',
          typ: ArbeitszeitTyp.fortbildung,
          notizen: '',
        ),
      ],
      startDate: DateTime(2026, 3, 1),
      endDate: DateTime(2026, 3, 31),
      autor: 'Anna Fachkraft',
      aktenzeichen: 'AZ-2026/03-FEGH',
    );
    expect(bytes.length, greaterThan(1000));
    File('C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Arbeitszeit.docx')
        .writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Arbeitszeit-DOCX: ${bytes.length} Bytes');
  });

  test('DOCX-Klienten-Beispiel', () async {
    final bytes = await DocxReportService.generateKlientenDocx(
      clients: [
        Client.create(
          name: 'Max Müller',
          vorname: 'Max',
          nachname: 'Müller',
          kostenuebernahme: 'Sozialamt Friedrichshain-Kreuzberg',
          fachleistungsstunden: 120,
          verbrauchteStunden: 85,
        ).copyWith(einwilligungVorhanden: true),
        Client.create(
          name: 'Erika Schröder',
          vorname: 'Erika',
          nachname: 'Schröder',
          kostenuebernahme: 'LAGeSo Eingliederungshilfe',
          fachleistungsstunden: 80,
          verbrauchteStunden: 76,
        ), // keine Einwilligung
      ],
      autor: 'Anna Fachkraft',
    );
    expect(bytes.length, greaterThan(1000));
    File('C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Klienten.docx')
        .writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Klienten-DOCX: ${bytes.length} Bytes');
  });
}
