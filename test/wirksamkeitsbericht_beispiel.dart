import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eingliederungshilfe_flutter/models/client.dart';
import 'package:eingliederungshilfe_flutter/models/teilhabeziel.dart';
import 'package:eingliederungshilfe_flutter/models/zielmessung.dart';
import 'package:eingliederungshilfe_flutter/models/pos_messung.dart';
import 'package:eingliederungshilfe_flutter/services/wirkungsmessung_service.dart';
import 'package:eingliederungshilfe_flutter/services/wirksamkeitsbericht_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
    ServicesBinding.instance.defaultBinaryMessenger.setMockMessageHandler(
        'flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      final bytes = File('C:/fegh/$key').readAsBytesSync();
      return ByteData.view(bytes.buffer);
    });
  });

  test('Wirksamkeitsbericht als Beispiel-PDF generieren', () async {
    // Klient anlegen
    final client = Client.create(
      name: 'Müller',
      vorname: 'Max',
      nachname: 'Müller',
      geburtsdatum: DateTime(1985, 5, 14),
      klientenId: 'KL-2026-042',
      kostenuebernahme: 'Sozialamt Friedrichshain-Kreuzberg',
      fachleistungsstunden: 120,
      verbrauchteStunden: 85.5,
    ).copyWith(einwilligungVorhanden: true);

    final wmService = WirkungsmessungService();

    // 3 Teilhabeziele mit unterschiedlichem Status
    final ziel1 = Teilhabeziel.create(
      clientId: client.id,
      titel: 'Selbstständig öffentliche Verkehrsmittel nutzen',
      beschreibung: 'Herr Müller soll lernen, selbstständig mit Bus und Bahn '
          'zu Terminen zu fahren, ohne Begleitung.',
      spezifisch: 'Fahrt zum Arzt und zur Werkstatt mit Bus/U-Bahn',
      messbar: 'Eigenständige Nutzung bei mindestens 3 Terminen pro Monat',
      attraktiv: 'Mehr Unabhängigkeit im Alltag, eigene Termine wahrnehmen',
      realistisch: 'Wegstrecke bekannt, keine motorischen Einschränkungen',
      terminiert: DateTime(2026, 9, 30),
      icfBereich: 'd470 Benutzung von Transportmitteln',
      kategorie: TeilhabezielKategorie.teilziel,
      prioritaet: 4,
      erstelltVon: 'Anna Fachkraft',
    );
    final ziel2 = Teilhabeziel.create(
      clientId: client.id,
      titel: 'Eigenen Haushalt strukturiert führen',
      beschreibung: 'Wöchentliches Einkaufen, Kochen, Wäsche - mit '
          'zunehmender Selbstständigkeit.',
      spezifisch: 'Einkaufsliste schreiben, einkaufen, 3 einfache Gerichte kochen',
      messbar: 'Ein Einkauf pro Woche ohne Erinnerung, 2 Gerichte pro Woche',
      attraktiv: 'Gesünderes Essen, Haushaltskosten sparen',
      realistisch: 'Lesen/Schreiben ist vorhanden, Interesse am Kochen da',
      terminiert: DateTime(2026, 12, 31),
      icfBereich: 'd6 Häusliches Leben',
      kategorie: TeilhabezielKategorie.leitziel,
      prioritaet: 5,
      erstelltVon: 'Anna Fachkraft',
    );
    final ziel3 = Teilhabeziel.create(
      clientId: client.id,
      titel: 'Regelmäßige soziale Kontakte pflegen',
      beschreibung: 'Kontakt zu Freund Thomas aus der Werkstatt halten, '
          'einmal monatlich Treffen im Café.',
      spezifisch: 'Monatliches Café-Treffen mit Thomas',
      messbar: 'Mindestens 1 Treffen pro Monat, Dokumentation im Wochengespräch',
      attraktiv: 'Wichtige Freundschaft, wirkt Einsamkeit entgegen',
      realistisch: 'Thomas ist interessiert, Treffpunkt erreichbar',
      terminiert: DateTime(2026, 12, 31),
      icfBereich: 'd7500 Informelle Beziehungen mit Freunden',
      kategorie: TeilhabezielKategorie.handlungsziel,
      prioritaet: 3,
      erstelltVon: 'Anna Fachkraft',
    ).copyWith(status: TeilhabezielStatus.erreicht);
    await wmService.addZiel(ziel1);
    await wmService.addZiel(ziel2);
    await wmService.addZiel(ziel3);

    // Messungen (GAS-Verlauf)
    // Ziel 1: Verbesserung über Zeit
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel1.id, clientId: client.id,
      messdatum: DateTime(2026, 1, 15),
      typ: MesszeitpunktTyp.baseline,
      bewertung: GasBewertung.deutlichSchlechter,
      kommentar: 'Fährt bisher nie allein, große Unsicherheit, keine Erfahrung.',
      bewertetVon: 'Anna Fachkraft',
    ));
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel1.id, clientId: client.id,
      messdatum: DateTime(2026, 2, 15),
      typ: MesszeitpunktTyp.zwischenmessung,
      bewertung: GasBewertung.schlechter,
      kommentar: 'Erste begleitete Fahrten absolviert. Kennt Linienführung zur Werkstatt.',
      bewertetVon: 'Anna Fachkraft',
    ));
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel1.id, clientId: client.id,
      messdatum: DateTime(2026, 3, 20),
      typ: MesszeitpunktTyp.zwischenmessung,
      bewertung: GasBewertung.wieErwartet,
      kommentar: 'Fährt zur Werkstatt selbstständig. Arzttermine noch mit Begleitung.',
      bewertetVon: 'Anna Fachkraft',
    ));
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel1.id, clientId: client.id,
      messdatum: DateTime(2026, 4, 10),
      typ: MesszeitpunktTyp.zwischenmessung,
      bewertung: GasBewertung.besser,
      kommentar: 'Auch Arztbesuche jetzt allein. Fühlt sich sicher.',
      bewertetVon: 'Anna Fachkraft',
    ));

    // Ziel 2: unterschiedlich
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel2.id, clientId: client.id,
      messdatum: DateTime(2026, 1, 15),
      typ: MesszeitpunktTyp.baseline,
      bewertung: GasBewertung.schlechter,
      kommentar: 'Einkauf nur mit Begleitung. Kochen: bislang nicht.',
      bewertetVon: 'Anna Fachkraft',
    ));
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel2.id, clientId: client.id,
      messdatum: DateTime(2026, 3, 15),
      typ: MesszeitpunktTyp.zwischenmessung,
      bewertung: GasBewertung.wieErwartet,
      kommentar: 'Einkauf selbstständig. Erstes einfaches Nudelgericht gelungen.',
      bewertetVon: 'Anna Fachkraft',
    ));

    // Ziel 3: erreicht
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel3.id, clientId: client.id,
      messdatum: DateTime(2026, 1, 15),
      typ: MesszeitpunktTyp.baseline,
      bewertung: GasBewertung.wieErwartet,
      kommentar: 'Kontakt zu Thomas besteht, aber unregelmäßig.',
      bewertetVon: 'Anna Fachkraft',
    ));
    await wmService.addMessung(Zielmessung.create(
      zielId: ziel3.id, clientId: client.id,
      messdatum: DateTime(2026, 4, 5),
      typ: MesszeitpunktTyp.endmessung,
      bewertung: GasBewertung.deutlichBesser,
      kommentar: 'Regelmäßige monatliche Treffen etabliert, inzwischen auch '
          'gemeinsame Wochenend-Aktivitäten.',
      bewertetVon: 'Anna Fachkraft',
    ));

    // POS-Messungen (Baseline + aktuelle)
    final posBaseline = PosMessung.create(
      clientId: client.id,
      messdatum: DateTime(2026, 1, 15),
      bewertetVon: 'Anna Fachkraft',
      bewertungen: {
        'selbstbestimmung': [1, 1, 1, 1, 2, 1],          // 7
        'sozialeTeilhabe': [1, 1, 1, 1, 1, 1],           // 6
        'interpersonelleBeziehungen': [2, 2, 1, 1, 2, 2],// 10
        'rechte': [2, 2, 2, 2, 2, 2],                    // 12
        'emotionalesWohlbefinden': [2, 1, 1, 1, 2, 2],   // 9
        'physischesWohlbefinden': [2, 2, 2, 2, 2, 2],    // 12
        'materiellesWohlbefinden': [2, 2, 1, 2, 1, 2],   // 10
        'persoenlicheEntwicklung': [1, 1, 2, 1, 1, 1],   // 7
      },
      kommentar: 'Baseline-Erhebung zu Beginn der Maßnahme.',
    );
    final posAktuell = PosMessung.create(
      clientId: client.id,
      messdatum: DateTime(2026, 4, 10),
      bewertetVon: 'Anna Fachkraft',
      bewertungen: {
        'selbstbestimmung': [2, 2, 2, 2, 2, 2],          // 12
        'sozialeTeilhabe': [2, 2, 2, 1, 2, 1],           // 10
        'interpersonelleBeziehungen': [3, 3, 2, 2, 3, 3],// 16
        'rechte': [3, 3, 3, 3, 3, 3],                    // 18
        'emotionalesWohlbefinden': [3, 2, 2, 2, 3, 3],   // 15
        'physischesWohlbefinden': [3, 2, 2, 2, 3, 3],    // 15
        'materiellesWohlbefinden': [2, 2, 2, 2, 2, 2],   // 12
        'persoenlicheEntwicklung': [2, 2, 3, 2, 2, 2],   // 13
      },
      kommentar: 'Deutliche Fortschritte in Selbstbestimmung, Beziehungen '
          'und emotionaler Entwicklung.',
    );
    await wmService.addPosMessung(posBaseline);
    await wmService.addPosMessung(posAktuell);

    // Bericht erzeugen
    final service = WirksamkeitsberichtService();
    final bytes = await service.generateClientReport(
      client: client,
      von: DateTime(2026, 1, 1),
      bis: DateTime(2026, 4, 10),
      autor: 'Anna Fachkraft',
    );
    expect(bytes.length, greaterThan(10000));

    final path = 'C:/Users/MIRKOR~1/AppData/Local/Temp/FEGH_Real_Wirksamkeit.pdf';
    File(path).writeAsBytesSync(bytes);
    // ignore: avoid_print
    print('Wirksamkeitsbericht: $path (${bytes.length} Bytes)');
  });
}
