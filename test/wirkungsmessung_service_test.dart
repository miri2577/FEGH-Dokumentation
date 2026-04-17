import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eingliederungshilfe_flutter/models/teilhabeziel.dart';
import 'package:eingliederungshilfe_flutter/models/zielmessung.dart';
import 'package:eingliederungshilfe_flutter/models/pos_messung.dart';
import 'package:eingliederungshilfe_flutter/services/wirkungsmessung_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('WirkungsmessungService - Teilhabeziele', () {
    test('addZiel + loadZiele runden sauber', () async {
      final service = WirkungsmessungService();
      final ziel = Teilhabeziel.create(
        clientId: 'c1',
        titel: 'Schwimmen lernen',
        beschreibung: 'Grundkenntnisse Schwimmen bis Sommer',
        spezifisch: 'Bruststil 25m',
        messbar: '25m ohne Pause',
        kategorie: TeilhabezielKategorie.teilziel,
      );
      expect(await service.addZiel(ziel), isTrue);
      final geladen = await service.loadZiele();
      expect(geladen.length, 1);
      expect(geladen.first.titel, 'Schwimmen lernen');
      expect(geladen.first.spezifisch, 'Bruststil 25m');
    });

    test('zieleFuerClient filtert korrekt', () async {
      final service = WirkungsmessungService();
      await service.addZiel(Teilhabeziel.create(clientId: 'a', titel: 'A'));
      await service.addZiel(Teilhabeziel.create(clientId: 'b', titel: 'B'));
      await service.addZiel(Teilhabeziel.create(clientId: 'a', titel: 'C'));
      final aZiele = await service.zieleFuerClient('a');
      expect(aZiele.length, 2);
      expect(aZiele.map((z) => z.titel).toSet(), {'A', 'C'});
    });

    test('updateZiel aendert bestehendes Ziel', () async {
      final service = WirkungsmessungService();
      final ziel = Teilhabeziel.create(clientId: 'c1', titel: 'Alt');
      await service.addZiel(ziel);
      final updated = ziel.copyWith(
        titel: 'Neu',
        status: TeilhabezielStatus.erreicht,
      );
      expect(await service.updateZiel(updated), isTrue);
      final geladen = await service.loadZiele();
      expect(geladen.first.titel, 'Neu');
      expect(geladen.first.status, TeilhabezielStatus.erreicht);
    });

    test('deleteZiel entfernt Ziel und alle Messungen', () async {
      final service = WirkungsmessungService();
      final ziel = Teilhabeziel.create(clientId: 'c1', titel: 'X');
      await service.addZiel(ziel);
      await service.addMessung(Zielmessung.create(
        zielId: ziel.id,
        clientId: 'c1',
        messdatum: DateTime(2026, 1, 1),
        typ: MesszeitpunktTyp.baseline,
        bewertung: GasBewertung.wieErwartet,
        bewertetVon: 'tester',
      ));
      await service.addMessung(Zielmessung.create(
        zielId: ziel.id,
        clientId: 'c1',
        messdatum: DateTime(2026, 2, 1),
        typ: MesszeitpunktTyp.zwischenmessung,
        bewertung: GasBewertung.besser,
        bewertetVon: 'tester',
      ));
      expect((await service.messungenFuerZiel(ziel.id)).length, 2);
      await service.deleteZiel(ziel.id);
      expect((await service.loadZiele()).length, 0);
      expect((await service.messungenFuerZiel(ziel.id)).length, 0);
    });
  });

  group('WirkungsmessungService - GAS-Messungen', () {
    test('messungenFuerZiel sortiert nach Datum aufsteigend', () async {
      final service = WirkungsmessungService();
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime(2026, 3, 1),
        typ: MesszeitpunktTyp.zwischenmessung,
        bewertung: GasBewertung.besser, bewertetVon: 't',
      ));
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime(2026, 1, 1),
        typ: MesszeitpunktTyp.baseline,
        bewertung: GasBewertung.wieErwartet, bewertetVon: 't',
      ));
      final sortiert = await service.messungenFuerZiel('z1');
      expect(sortiert.first.messdatum, DateTime(2026, 1, 1));
      expect(sortiert.last.messdatum, DateTime(2026, 3, 1));
    });

    test('durchschnittGas berechnet korrekt', () async {
      final service = WirkungsmessungService();
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime(2026, 1, 1),
        typ: MesszeitpunktTyp.baseline,
        bewertung: GasBewertung.schlechter, bewertetVon: 't',
      )); // -1
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime(2026, 2, 1),
        typ: MesszeitpunktTyp.zwischenmessung,
        bewertung: GasBewertung.besser, bewertetVon: 't',
      )); // +1
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime(2026, 3, 1),
        typ: MesszeitpunktTyp.zwischenmessung,
        bewertung: GasBewertung.deutlichBesser, bewertetVon: 't',
      )); // +2
      expect(await service.durchschnittGas('z1'), closeTo(2 / 3, 0.0001));
    });

    test('durchschnittGas gibt null bei leeren Messungen', () async {
      final service = WirkungsmessungService();
      expect(await service.durchschnittGas('leer'), isNull);
    });

    test('zwischenmessungFaellig: true ohne Messung', () async {
      final service = WirkungsmessungService();
      expect(await service.zwischenmessungFaellig('unbekannt'), isTrue);
    });

    test('zwischenmessungFaellig: true bei >90 Tagen', () async {
      final service = WirkungsmessungService();
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime.now().subtract(const Duration(days: 100)),
        typ: MesszeitpunktTyp.baseline,
        bewertung: GasBewertung.wieErwartet, bewertetVon: 't',
      ));
      expect(await service.zwischenmessungFaellig('z1'), isTrue);
    });

    test('zwischenmessungFaellig: false bei <90 Tagen', () async {
      final service = WirkungsmessungService();
      await service.addMessung(Zielmessung.create(
        zielId: 'z1', clientId: 'c1',
        messdatum: DateTime.now().subtract(const Duration(days: 30)),
        typ: MesszeitpunktTyp.baseline,
        bewertung: GasBewertung.wieErwartet, bewertetVon: 't',
      ));
      expect(await service.zwischenmessungFaellig('z1'), isFalse);
    });
  });

  group('WirkungsmessungService - POS', () {
    test('addPosMessung + posMessungenFuerClient runden sauber', () async {
      final service = WirkungsmessungService();
      final msg = PosMessung.create(
        clientId: 'c1',
        messdatum: DateTime(2026, 1, 1),
        bewertetVon: 't',
        bewertungen: PosMessung.leereBewertungen(),
      );
      await service.addPosMessung(msg);
      final geladen = await service.posMessungenFuerClient('c1');
      expect(geladen.length, 1);
      expect(geladen.first.clientId, 'c1');
    });

    test('PosMessung.gesamtPunkte berechnet korrekt', () {
      final bewertungen = {
        for (final d in PosDomaene.values) d.name: [3, 3, 3, 3, 3, 3], // 18 pro Domaene
      };
      final m = PosMessung.create(
        clientId: 'c1',
        messdatum: DateTime.now(),
        bewertetVon: 't',
        bewertungen: bewertungen,
      );
      expect(m.gesamtPunkte, 144); // 8 * 18
      expect(m.gesamtProzent, 100.0);
    });

    test('PosMessung.domaenePunkte isoliert einzelne Domaene', () {
      final bewertungen = PosMessung.leereBewertungen();
      bewertungen[PosDomaene.selbstbestimmung.name] = [3, 3, 3, 2, 2, 1]; // = 14
      final m = PosMessung.create(
        clientId: 'c1',
        messdatum: DateTime.now(),
        bewertetVon: 't',
        bewertungen: bewertungen,
      );
      expect(m.domaenePunkte(PosDomaene.selbstbestimmung), 14);
      expect(m.domaenePunkte(PosDomaene.rechte), 0);
      expect(m.domaeneProzent(PosDomaene.selbstbestimmung), closeTo(14 / 18 * 100, 0.001));
    });

    test('PosMessung.leereBewertungen hat 8 Domaenen mit je 6 Items', () {
      final leer = PosMessung.leereBewertungen();
      expect(leer.length, 8);
      for (final werte in leer.values) {
        expect(werte.length, 6);
        expect(werte.every((v) => v == 0), isTrue);
      }
    });

    test('updatePosMessung aendert bestehende Messung', () async {
      final service = WirkungsmessungService();
      final m = PosMessung.create(
        clientId: 'c1',
        messdatum: DateTime(2026, 1, 1),
        bewertetVon: 't',
        bewertungen: PosMessung.leereBewertungen(),
      );
      await service.addPosMessung(m);
      final neueBewertungen = PosMessung.leereBewertungen();
      neueBewertungen[PosDomaene.rechte.name] = [3, 3, 3, 3, 3, 3];
      final updated = m.copyWith(bewertungen: neueBewertungen);
      expect(await service.updatePosMessung(updated), isTrue);
      final geladen = await service.posMessungenFuerClient('c1');
      expect(geladen.first.domaenePunkte(PosDomaene.rechte), 18);
    });

    test('deletePosMessung entfernt Messung', () async {
      final service = WirkungsmessungService();
      final m = PosMessung.create(
        clientId: 'c1',
        messdatum: DateTime.now(),
        bewertetVon: 't',
        bewertungen: PosMessung.leereBewertungen(),
      );
      await service.addPosMessung(m);
      await service.deletePosMessung(m.id);
      expect((await service.posMessungenFuerClient('c1')).length, 0);
    });
  });

  group('Teilhabeziel - Modell', () {
    test('istUeberfaellig: true wenn Termin in Vergangenheit und nicht erreicht', () {
      final z = Teilhabeziel.create(
        clientId: 'c1',
        titel: 'X',
        terminiert: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(z.istUeberfaellig, isTrue);
    });

    test('istUeberfaellig: false wenn erreicht', () {
      final z = Teilhabeziel.create(
        clientId: 'c1',
        titel: 'X',
        terminiert: DateTime.now().subtract(const Duration(days: 10)),
      ).copyWith(status: TeilhabezielStatus.erreicht);
      expect(z.istUeberfaellig, isFalse);
    });

    test('istUeberfaellig: false ohne Termin', () {
      final z = Teilhabeziel.create(clientId: 'c1', titel: 'X');
      expect(z.istUeberfaellig, isFalse);
    });

    test('JSON-Serialisierung round-trip', () {
      final z = Teilhabeziel.create(
        clientId: 'c1',
        titel: 'Test',
        spezifisch: 'S',
        messbar: 'M',
        icfBereich: 'd170',
        prioritaet: 4,
      );
      final json = z.toJson();
      final restored = Teilhabeziel.fromJson(json);
      expect(restored.titel, z.titel);
      expect(restored.spezifisch, 'S');
      expect(restored.icfBereich, 'd170');
      expect(restored.prioritaet, 4);
    });
  });

  group('GasBewertung - Extension', () {
    test('wert gibt numerische Punkte zurueck', () {
      expect(GasBewertung.deutlichSchlechter.wert, -2);
      expect(GasBewertung.schlechter.wert, -1);
      expect(GasBewertung.wieErwartet.wert, 0);
      expect(GasBewertung.besser.wert, 1);
      expect(GasBewertung.deutlichBesser.wert, 2);
    });

    test('displayName ist deutscher Text', () {
      for (final b in GasBewertung.values) {
        expect(b.displayName, isNotEmpty);
        expect(b.kurzBeschreibung, isNotEmpty);
      }
    });
  });
}
