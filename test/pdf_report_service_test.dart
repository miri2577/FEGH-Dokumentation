import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:eingliederungshilfe_flutter/models/arbeitszeit.dart';
import 'package:eingliederungshilfe_flutter/models/appointment.dart';
import 'package:eingliederungshilfe_flutter/models/client.dart';
import 'package:eingliederungshilfe_flutter/services/pdf_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Asset-Bundle fuer Roboto-Fonts aus dem Dateisystem laden
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      final bytes = File('C:/fegh/$key').readAsBytesSync();
      return ByteData.view(bytes.buffer);
    });
  });

  group('PdfReportService', () {
    test('Arbeitszeiten-Report mit Daten erzeugt valides PDF', () async {
      final bytes = await PdfReportService.generateArbeitszeitenReport(
        arbeitszeiten: [
          Arbeitszeit.create(
            datum: DateTime(2026, 3, 3),
            startzeit: DateTime(2026, 3, 3, 8),
            endzeit: DateTime(2026, 3, 3, 16),
            taetigkeit: 'Kliententermin Herr Mueller',
            typ: ArbeitszeitTyp.betreuung,
            notizen: '',
          ),
          Arbeitszeit.create(
            datum: DateTime(2026, 3, 4),
            startzeit: DateTime(2026, 3, 4, 9),
            endzeit: DateTime(2026, 3, 4, 17),
            taetigkeit: 'Dokumentation',
            typ: ArbeitszeitTyp.dokumentation,
            notizen: '',
          ),
        ],
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
        autor: 'Anna Fachkraft',
      );
      expect(bytes.length, greaterThan(10000));

      // Zum manuellen Begutachten speichern
      File('C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Arbeitszeit.pdf')
          .writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Arbeitszeit-Report: C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Arbeitszeit.pdf (${bytes.length} Bytes)');
    });

    test('Arbeitszeiten-Report mit LEEREN Daten crasht nicht', () async {
      final bytes = await PdfReportService.generateArbeitszeitenReport(
        arbeitszeiten: [],
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );
      expect(bytes.length, greaterThan(5000));
    });

    test('FLS-Report mit Daten erzeugt valides PDF', () async {
      final now = DateTime(2026, 3, 15, 10);
      final bytes = await PdfReportService.generateFachleistungsstundenReport(
        appointments: [
          Appointment.create(
            clientId: 'c1',
            clientName: 'Max Mustermann',
            date: DateTime(2026, 3, 15),
            startTime: now,
            endTime: now.add(const Duration(hours: 2)),
            notes: 'Gespraech',
            recordedText: '',
            berufsgruppe: 'Sozialpaedagoge',
            eingliederung: 'Soziale Teilhabe',
            fachleistungsstunden: 2.0,
          ),
        ],
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 31),
      );
      expect(bytes.length, greaterThan(10000));
      File('C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_FLS.pdf')
          .writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('FLS-Report: C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_FLS.pdf (${bytes.length} Bytes)');
    });

    test('Klienten-Report mit Einwilligungs-Check', () async {
      final bytes = await PdfReportService.generateKlientenReport(
        clients: [
          Client.create(
            name: 'Max Mustermann',
            vorname: 'Max',
            nachname: 'Mustermann',
            fachleistungsstunden: 120,
            verbrauchteStunden: 85,
          ).copyWith(einwilligungVorhanden: true),
          Client.create(
            name: 'Erika Beispiel',
            vorname: 'Erika',
            nachname: 'Beispiel',
            fachleistungsstunden: 80,
            verbrauchteStunden: 76,
          ), // keine Einwilligung
        ],
        autor: 'Anna Fachkraft',
      );
      expect(bytes.length, greaterThan(10000));
      File('C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Klienten.pdf')
          .writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Klienten-Report: C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Klienten.pdf (${bytes.length} Bytes)');
    });

    test('Klienten-Report mit LEERER Liste crasht nicht', () async {
      final bytes = await PdfReportService.generateKlientenReport(clients: []);
      expect(bytes.length, greaterThan(5000));
    });
  });
}
