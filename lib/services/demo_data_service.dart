import '../models/client.dart';
import '../models/mitarbeiter.dart';
import '../providers/app_provider.dart';

class DemoDataService {
  static Future<void> loadDemoData(AppProvider appProvider) async {
    // Prüfe ob bereits Klienten vorhanden (Demo-Daten nur einmal laden)
    if (appProvider.clients.isNotEmpty) return;

    final now = DateTime.now();

    // 6 fiktive Klienten - Eingliederungshilfe psychisch Kranke, eigene Wohnung
    final demoClients = [
      Client.create(
        name: 'Schmidt, Anna',
        vorname: 'Anna',
        nachname: 'Schmidt',
        geburtsdatum: DateTime(1988, 3, 15),
        betreuungSeit: DateTime(2025, 6, 1),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'Depressive Episode, Unterstützung bei Alltagsstruktur und sozialer Teilhabe',
        fachleistungsstunden: 8,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 42.5,
        kostenuebernahme: 'Bezirksamt Mitte',
        kostenuebernahmeVon: DateTime(2025, 6, 1),
        kostenuebernahmeBis: DateTime(2026, 5, 31),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d230', 'd570', 'd920', 'b152'],
      ),
      Client.create(
        name: 'Yilmaz, Emre',
        vorname: 'Emre',
        nachname: 'Yilmaz',
        geburtsdatum: DateTime(1995, 11, 22),
        betreuungSeit: DateTime(2025, 9, 15),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'Schizophrenie, Begleitung Arztbesuche und Medikamentenmanagement',
        fachleistungsstunden: 6,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 28.0,
        kostenuebernahme: 'Bezirksamt Neukölln',
        kostenuebernahmeVon: DateTime(2025, 9, 15),
        kostenuebernahmeBis: DateTime(2026, 9, 14),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d570', 'd620', 'd860', 'b164'],
      ),
      Client.create(
        name: 'Weber, Christine',
        vorname: 'Christine',
        nachname: 'Weber',
        geburtsdatum: DateTime(1965, 7, 3),
        betreuungSeit: DateTime(2024, 11, 1),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'Bipolare Störung, Unterstützung Finanzen und Behördengänge',
        fachleistungsstunden: 5,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 85.0,
        kostenuebernahme: 'Bezirksamt Charlottenburg-Wilmersdorf',
        kostenuebernahmeVon: DateTime(2024, 11, 1),
        kostenuebernahmeBis: DateTime(2026, 10, 31),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d870', 'd910', 'b126', 'b152'],
      ),
      Client.create(
        name: 'Hoffmann, Markus',
        vorname: 'Markus',
        nachname: 'Hoffmann',
        geburtsdatum: DateTime(2002, 1, 28),
        betreuungSeit: DateTime(2026, 1, 10),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'PTBS und Angststörung, Aufbau Tagesstruktur und Berufsvorbereitung',
        fachleistungsstunden: 10,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 18.0,
        kostenuebernahme: 'Bezirksamt Friedrichshain-Kreuzberg',
        kostenuebernahmeVon: DateTime(2026, 1, 10),
        kostenuebernahmeBis: DateTime(2027, 1, 9),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d230', 'd845', 'd720', 'b144'],
      ),
      Client.create(
        name: 'Petrov, Natalia',
        vorname: 'Natalia',
        nachname: 'Petrov',
        geburtsdatum: DateTime(1978, 9, 12),
        betreuungSeit: DateTime(2025, 3, 1),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'Emotional instabile Persönlichkeitsstörung, Krisenintervention und Alltagsbewältigung',
        fachleistungsstunden: 7,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 56.5,
        kostenuebernahme: 'Bezirksamt Pankow',
        kostenuebernahmeVon: DateTime(2025, 3, 1),
        kostenuebernahmeBis: DateTime(2026, 2, 28),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d710', 'd240', 'b126', 'b152'],
      ),
      Client.create(
        name: 'Braun, Jens',
        vorname: 'Jens',
        nachname: 'Braun',
        geburtsdatum: DateTime(1958, 4, 19),
        betreuungSeit: DateTime(2025, 1, 15),
        hilfeTyp: HilfeTyp.eingliederungshilfe,
        eingliederung: 'Chronische Depression und Suchterkrankung, Wohnraumsicherung und Gesundheitsförderung',
        fachleistungsstunden: 6,
        fachleistungsIntervall: FachleistungsIntervall.woechentlich,
        verbrauchteStunden: 62.0,
        kostenuebernahme: 'Bezirksamt Spandau',
        kostenuebernahmeVon: DateTime(2025, 1, 15),
        kostenuebernahmeBis: DateTime(2026, 1, 14),
        rechtsgrundlage: '§ 113 Abs. 2 Nr. 2 SGB IX',
        icfBereiche: ['d620', 'd570', 'b130', 'b152'],
      ),
    ];

    for (final client in demoClients) {
      await appProvider.addClient(client);
    }

    // 3 fiktive Mitarbeiter
    final demoMitarbeiter = [
      Mitarbeiter.create(
        name: 'Müller',
        vorname: 'Sarah',
        email: 'demo@beispiel.de',
        telefon: '030 12345678',
        teamNummer: 1,
        bereich: MitarbeiterBereich.eingliederungshilfe,
        wochenarbeitszeit: 38.5,
        urlaubstage: 30,
      ),
      Mitarbeiter.create(
        name: 'Nguyen',
        vorname: 'Linh',
        email: 'demo2@beispiel.de',
        telefon: '030 87654321',
        teamNummer: 1,
        bereich: MitarbeiterBereich.eingliederungshilfe,
        wochenarbeitszeit: 30.0,
        urlaubstage: 28,
      ),
      Mitarbeiter.create(
        name: 'Becker',
        vorname: 'Thomas',
        email: 'demo3@beispiel.de',
        telefon: '030 11223344',
        teamNummer: 2,
        bereich: MitarbeiterBereich.eingliederungshilfe,
        wochenarbeitszeit: 40.0,
        urlaubstage: 30,
      ),
    ];

    for (final ma in demoMitarbeiter) {
      await appProvider.addMitarbeiter(ma);
    }
  }
}
