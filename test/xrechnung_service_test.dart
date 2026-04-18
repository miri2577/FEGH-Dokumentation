import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/models/rechnung.dart';
import 'package:eingliederungshilfe_flutter/models/rechnung_empfaenger.dart';
import 'package:eingliederungshilfe_flutter/services/xrechnung_service.dart';

void main() {
  group('XRechnungService - UBL XML Generator', () {
    late XRechnungService service;
    late RechnungEmpfaenger empfaenger;

    setUp(() {
      service = XRechnungService(
        rechnungssteller: const RechnungsstellerDaten(
          name: 'Sozialtraeger Musterfirma GmbH',
          strasse: 'Hauptstrasse 1',
          plz: '10115',
          ort: 'Berlin',
          umsatzsteuerId: 'DE123456789',
          iban: 'DE89370400440532013000',
          bic: 'COBADEFFXXX',
          kontoinhaber: 'Sozialtraeger Musterfirma GmbH',
          email: 'rechnungen@muster.de',
          elektronischeAdresse: 'rechnungen@muster.de',
        ),
      );
      empfaenger = RechnungEmpfaenger(
        id: 'e1',
        name: 'Sozialamt Friedrichshain-Kreuzberg',
        leitwegId: '05314-11001001-01',
        strasse: 'Yorckstr. 4-11',
        plz: '10965',
        ort: 'Berlin',
        land: 'DE',
        erstelltAm: DateTime(2026, 1, 1),
      );
    });

    Rechnung makeRechnung() {
      return Rechnung(
        id: 'r1',
        rechnungsnummer: '2026-0001',
        rechnungsdatum: DateTime(2026, 4, 15),
        leistungsVon: DateTime(2026, 3, 1),
        leistungsBis: DateTime(2026, 3, 31),
        empfaengerId: empfaenger.id,
        positionen: [
          RechnungsPosition(
            id: 'p1',
            bezeichnung: 'Fachleistungsstunden EGH - Max Mustermann',
            menge: 12.5,
            einheit: 'Stunde',
            einzelpreis: 40.0,
            leistungszeitraumVon: '2026-03-01',
            leistungszeitraumBis: '2026-03-31',
            clientName: 'Max Mustermann',
          ),
        ],
        erstelltAm: DateTime(2026, 4, 15),
      );
    }

    test('XML beginnt mit XML-Deklaration', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.startsWith('<?xml version="1.0" encoding="UTF-8"?>'), isTrue);
    });

    test('CustomizationID ist XRechnung 3.0', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_3.0'), isTrue);
    });

    test('Rechnungsnummer ist enthalten', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:ID>2026-0001</cbc:ID>'), isTrue);
    });

    test('Leitweg-ID wird als BuyerReference gesetzt', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:BuyerReference>05314-11001001-01</cbc:BuyerReference>'), isTrue);
    });

    test('Rechnungsdatum ist ISO-Format', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:IssueDate>2026-04-15</cbc:IssueDate>'), isTrue);
    });

    test('Empfaenger-Adresse ist enthalten', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:StreetName>Yorckstr. 4-11</cbc:StreetName>'), isTrue);
      expect(xml.contains('<cbc:PostalZone>10965</cbc:PostalZone>'), isTrue);
      expect(xml.contains('<cbc:CityName>Berlin</cbc:CityName>'), isTrue);
    });

    test('Seller USt-ID ist enthalten', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:CompanyID>DE123456789</cbc:CompanyID>'), isTrue);
    });

    test('IBAN und BIC sind in PaymentMeans', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('DE89370400440532013000'), isTrue);
      expect(xml.contains('COBADEFFXXX'), isTrue);
    });

    test('Leistungszeitraum (InvoicePeriod) ist enthalten', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:StartDate>2026-03-01</cbc:StartDate>'), isTrue);
      expect(xml.contains('<cbc:EndDate>2026-03-31</cbc:EndDate>'), isTrue);
    });

    test('Betrag 12.5 * 40 = 500,00 EUR ist Netto und Brutto (0% USt)', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:LineExtensionAmount currencyID="EUR">500.00</cbc:LineExtensionAmount>'), isTrue);
      expect(xml.contains('<cbc:PayableAmount currencyID="EUR">500.00</cbc:PayableAmount>'), isTrue);
    });

    test('Menge 12.5 mit HUR-Einheit (Stunde)', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:InvoicedQuantity unitCode="HUR">12.50</cbc:InvoicedQuantity>'), isTrue);
    });

    test('Steuerkategorie E (Exempt) bei 0% mit Befreiungsgrund', () {
      final xml = service.buildXml(rechnung: makeRechnung(), empfaenger: empfaenger);
      expect(xml.contains('<cbc:ID>E</cbc:ID>'), isTrue);
      // VATEX-DE-HE ist der Code fuer §4 Nr. 16 h UStG (Soziale Einrichtungen / EGH)
      expect(xml.contains('VATEX-DE-HE'), isTrue);
    });

    test('Special-Characters werden escaped', () {
      final r = Rechnung(
        id: 'r1',
        rechnungsnummer: '2026-0002',
        rechnungsdatum: DateTime(2026, 4, 15),
        empfaengerId: 'e1',
        positionen: [
          RechnungsPosition(
            id: 'p1',
            bezeichnung: 'Test & <Hinweis> "Escape"',
            menge: 1.0,
            einheit: 'Stueck',
            einzelpreis: 10.0,
          ),
        ],
        erstelltAm: DateTime(2026, 4, 15),
      );
      final xml = service.buildXml(rechnung: r, empfaenger: empfaenger);
      expect(xml.contains('Test &amp; &lt;Hinweis&gt; &quot;Escape&quot;'), isTrue);
    });

    test('Mehrere Positionen - Summen stimmen', () {
      final r = Rechnung(
        id: 'r1',
        rechnungsnummer: '2026-0003',
        rechnungsdatum: DateTime(2026, 4, 15),
        empfaengerId: 'e1',
        positionen: [
          RechnungsPosition(id: 'p1', bezeichnung: 'A', menge: 2, einheit: 'h', einzelpreis: 50),
          RechnungsPosition(id: 'p2', bezeichnung: 'B', menge: 3, einheit: 'h', einzelpreis: 40),
        ],
        erstelltAm: DateTime(2026, 4, 15),
      );
      expect(r.gesamtNetto, 220.0);
      final xml = service.buildXml(rechnung: r, empfaenger: empfaenger);
      expect(xml.contains('<cbc:PayableAmount currencyID="EUR">220.00</cbc:PayableAmount>'), isTrue);
    });
  });

  group('Rechnung - Berechnungen', () {
    test('nettoBetrag = menge * einzelpreis', () {
      final p = RechnungsPosition(id: 'x', bezeichnung: 'T', menge: 12.5, einheit: 'h', einzelpreis: 40);
      expect(p.nettoBetrag, 500.0);
    });

    test('bruttoBetrag bei 19% USt', () {
      final p = RechnungsPosition(
        id: 'x', bezeichnung: 'T', menge: 10, einheit: 'h',
        einzelpreis: 100, steuerprozent: 19,
      );
      expect(p.nettoBetrag, 1000.0);
      expect(p.steuerBetrag, 190.0);
      expect(p.bruttoBetrag, 1190.0);
    });

    test('Faelligkeit = Rechnungsdatum + Zahlungsziel', () {
      final r = Rechnung(
        id: 'r1', rechnungsnummer: 'X', rechnungsdatum: DateTime(2026, 4, 1),
        empfaengerId: 'e', positionen: [], zahlungszielTage: 14,
        erstelltAm: DateTime(2026, 4, 1),
      );
      expect(r.faelligkeit, DateTime(2026, 4, 15));
    });
  });

  group('RechnungEmpfaenger - Leitweg-ID-Validierung', () {
    test('gueltige Leitweg-IDs', () {
      final e1 = RechnungEmpfaenger(
        id: '1', name: 'T', leitwegId: '05314-11001001-01',
        strasse: 'x', plz: '1', ort: 'Y', erstelltAm: DateTime.now(),
      );
      expect(e1.leitwegIdGueltig, isTrue);
      final e2 = RechnungEmpfaenger(
        id: '2', name: 'T', leitwegId: '04011-12345-99',
        strasse: 'x', plz: '1', ort: 'Y', erstelltAm: DateTime.now(),
      );
      expect(e2.leitwegIdGueltig, isTrue);
    });

    test('ungueltige Leitweg-ID', () {
      final e = RechnungEmpfaenger(
        id: '1', name: 'T', leitwegId: '!invalid!',
        strasse: 'x', plz: '1', ort: 'Y', erstelltAm: DateTime.now(),
      );
      expect(e.leitwegIdGueltig, isFalse);
    });
  });
}
