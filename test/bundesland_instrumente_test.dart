import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/models/b_e_ni.dart';
import 'package:eingliederungshilfe_flutter/models/bei_bw.dart';
import 'package:eingliederungshilfe_flutter/models/bei_nrw.dart';
import 'package:eingliederungshilfe_flutter/models/bundesland.dart';
import 'package:eingliederungshilfe_flutter/models/generisch_icf.dart';
import 'package:eingliederungshilfe_flutter/models/hmbv.dart';
import 'package:eingliederungshilfe_flutter/models/itp.dart';

void main() {
  group('Bundesland-Profile', () {
    test('Alle 16 Bundeslaender haben ein Profil', () {
      expect(Bundesland.values.length, 16);
      for (final b in Bundesland.values) {
        expect(BundeslandProfile.forLand(b), isNotNull);
      }
    });

    test('Alle 16 Laender sind produktionsreif', () {
      for (final p in BundeslandProfile.alle()) {
        expect(p.implementiert, isTrue,
            reason: '${p.anzeigeName} sollte implementiert: true sein');
      }
    });

    test('Berlin hat Formular 101 und TIB', () {
      final p = BundeslandProfile.forLand(Bundesland.berlin);
      expect(p.informationsberichtBerlin101, isTrue);
      expect(p.tibBereicheVerfuegbar, isTrue);
    });

    test('NRW hat BEI_NRW', () {
      final p = BundeslandProfile.forLand(Bundesland.nordrheinWestfalen);
      expect(p.beiNrwVerfuegbar, isTrue);
    });

    test('BW hat BEI_BW', () {
      final p = BundeslandProfile.forLand(Bundesland.badenWuerttemberg);
      expect(p.beiBwVerfuegbar, isTrue);
    });

    test('ITP-Familie: 6 Laender', () {
      final itpLaender = BundeslandProfile.alle().where((p) => p.itpVerfuegbar).toList();
      expect(itpLaender.length, 6);
      expect(itpLaender.map((p) => p.bundesland), containsAll([
        Bundesland.hessen,
        Bundesland.brandenburg,
        Bundesland.mecklenburgVorpommern,
        Bundesland.sachsen,
        Bundesland.sachsenAnhalt,
        Bundesland.thueringen,
      ]));
    });

    test('HMBV: Hamburg + Bremen', () {
      final hmbv = BundeslandProfile.alle().where((p) => p.hmbvVerfuegbar).toList();
      expect(hmbv.length, 2);
      expect(hmbv.map((p) => p.bundesland), containsAll([
        Bundesland.hamburg,
        Bundesland.bremen,
      ]));
    });

    test('Niedersachsen hat B.E.Ni', () {
      final p = BundeslandProfile.forLand(Bundesland.niedersachsen);
      expect(p.bEniVerfuegbar, isTrue);
    });

    test('Generisch ICF fuer 4 Laender ohne eigenes Instrument', () {
      final gen = BundeslandProfile.alle().where((p) => p.generischIcfVerfuegbar).toList();
      expect(gen.length, 4);
      expect(gen.map((p) => p.bundesland), containsAll([
        Bundesland.bayern,
        Bundesland.rheinlandPfalz,
        Bundesland.saarland,
        Bundesland.schleswigHolstein,
      ]));
    });

    test('Jedes Land hat genau EIN aktives Instrument-Flag', () {
      for (final p in BundeslandProfile.alle()) {
        final flags = [
          p.tibBereicheVerfuegbar,
          p.beiNrwVerfuegbar,
          p.beiBwVerfuegbar,
          p.itpVerfuegbar,
          p.hmbvVerfuegbar,
          p.bEniVerfuegbar,
          p.generischIcfVerfuegbar,
        ];
        final aktiv = flags.where((f) => f).length;
        expect(aktiv, 1,
            reason: '${p.anzeigeName} hat $aktiv aktive Flags, erwartet 1');
      }
    });

    test('Alle Instrumente haben nicht-leere Beschreibung', () {
      for (final p in BundeslandProfile.alle()) {
        expect(p.anzeigeName.isNotEmpty, isTrue);
        expect(p.instrumentName.isNotEmpty, isTrue);
        expect(p.rahmenvertragName.isNotEmpty, isTrue);
      }
    });
  });

  group('BEI_NRW', () {
    test('hat 9 Lebensbereiche mit d1-d9', () {
      expect(BEINRWLebensbereich.values.length, 9);
      for (int i = 0; i < 9; i++) {
        final b = BEINRWLebensbereich.values[i];
        expect(b.icfCode, 'd${i + 1}');
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
      }
    });
  });

  group('BEI_BW', () {
    test('hat 9 Lebensbereiche mit d1-d9', () {
      expect(BEIBWLebensbereich.values.length, 9);
      for (int i = 0; i < 9; i++) {
        final b = BEIBWLebensbereich.values[i];
        expect(b.icfCode, 'd${i + 1}');
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
      }
    });
  });

  group('ITP', () {
    test('hat 9 Lebensbereiche mit d1-d9', () {
      expect(ITPLebensbereich.values.length, 9);
      for (int i = 0; i < 9; i++) {
        final b = ITPLebensbereich.values[i];
        expect(b.icfCode, 'd${i + 1}');
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
      }
    });
  });

  group('B.E.Ni', () {
    test('hat 9 Lebensbereiche mit d1-d9', () {
      expect(BENiLebensbereich.values.length, 9);
      for (int i = 0; i < 9; i++) {
        final b = BENiLebensbereich.values[i];
        expect(b.icfCode, 'd${i + 1}');
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
      }
    });
  });

  group('Generisch ICF', () {
    test('hat 9 Lebensbereiche mit d1-d9', () {
      expect(GenerischIcfLebensbereich.values.length, 9);
      for (int i = 0; i < 9; i++) {
        final b = GenerischIcfLebensbereich.values[i];
        expect(b.icfCode, 'd${i + 1}');
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
      }
    });
  });

  group('HMBV', () {
    test('hat 5 Bereiche mit eindeutigen Kurzcodes', () {
      expect(HMBVBereich.values.length, 5);
      final codes = HMBVBereich.values.map((b) => b.kurzCode).toSet();
      expect(codes.length, 5); // alle unique
      for (final b in HMBVBereich.values) {
        expect(b.displayName.isNotEmpty, isTrue);
        expect(b.kurzBeschreibung.isNotEmpty, isTrue);
        expect(b.kurzCode.isNotEmpty, isTrue);
      }
    });

    test('Unterstuetzungsintensitaet 0-4 numerisch', () {
      expect(HMBVUnterstuetzung.values.length, 5);
      expect(HMBVUnterstuetzung.keine.wert, 0);
      expect(HMBVUnterstuetzung.gering.wert, 1);
      expect(HMBVUnterstuetzung.mittel.wert, 2);
      expect(HMBVUnterstuetzung.hoch.wert, 3);
      expect(HMBVUnterstuetzung.sehrHoch.wert, 4);
    });

    test('Alle Unterstuetzung-Werte haben DisplayName', () {
      for (final u in HMBVUnterstuetzung.values) {
        expect(u.displayName.isNotEmpty, isTrue);
      }
    });
  });
}
