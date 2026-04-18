import 'dart:math';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/arbeitszeit.dart';
import '../models/mitarbeiter.dart';
import '../models/freizeit_antrag.dart';
import '../providers/app_provider.dart';

/// Generiert umfangreiche Testdaten: 4 Teams, 25 Mitarbeiter, Klienten, Termine, AZ.
class TestDataGenerator {
  static final _rng = Random(42);

  static const _vornamen = [
    'Max', 'Anna', 'Thomas', 'Sarah', 'Michael', 'Julia', 'Stefan', 'Lisa',
    'Christian', 'Laura', 'Daniel', 'Marie', 'Jan', 'Sophie', 'Tim', 'Lena',
    'Andreas', 'Katharina', 'Martin', 'Eva', 'Florian', 'Nina', 'Patrick',
    'Sandra', 'Oliver',
  ];
  static const _nachnamen = [
    'Mueller', 'Schmidt', 'Schneider', 'Fischer', 'Weber', 'Meyer', 'Wagner',
    'Becker', 'Schulz', 'Hoffmann', 'Koch', 'Richter', 'Klein', 'Wolf',
    'Schroeder', 'Neumann', 'Braun', 'Werner', 'Schwarz', 'Zimmermann',
    'Krause', 'Peters', 'Lang', 'Berger', 'Frank',
  ];
  static const _teamNamen = ['Team Nord', 'Team Sued', 'Team Ost', 'Team West'];
  static const _taetigkeiten = [
    'Klientengespraech', 'Hausbesuch', 'Dokumentation', 'Begleitung',
    'Beratung', 'Telefonate', 'Netzwerkarbeit', 'Krisenintervention',
  ];

  static Future<void> generate(AppProvider app) async {
    // 1. Mitarbeiter (25)
    final mitarbeiter = <Mitarbeiter>[];
    for (int i = 0; i < 25; i++) {
      final ma = Mitarbeiter.create(
        name: _nachnamen[i],
        vorname: _vornamen[i],
        email: '${_vornamen[i].toLowerCase()}.${_nachnamen[i].toLowerCase()}@fegh.de',
        telefon: '030-${1000000 + _rng.nextInt(9000000)}',
        teamNummer: (i ~/ 7) + 1,
        teamIds: [_teamNamen[i ~/ 7].replaceAll(' ', '-').toLowerCase()],
        bereich: MitarbeiterBereich.eingliederungshilfe,
        wochenarbeitszeit: [35.0, 38.5, 40.0][_rng.nextInt(3)],
        urlaubstage: 30,
      );
      mitarbeiter.add(ma);
      await app.addMitarbeiter(ma);
    }

    // 2. Klienten (40, verteilt auf Teams)
    final klientenVornamen = [
      'Peter', 'Helga', 'Klaus', 'Renate', 'Juergen', 'Ingrid', 'Wolfgang',
      'Monika', 'Herbert', 'Erika', 'Dieter', 'Ursula', 'Heinz', 'Gertrud',
      'Werner', 'Hannelore', 'Horst', 'Elfriede', 'Manfred', 'Christa',
      'Guenther', 'Margarete', 'Siegfried', 'Hildegard', 'Rolf', 'Irmgard',
      'Karl', 'Edith', 'Heinrich', 'Ruth', 'Walter', 'Ilse', 'Ludwig',
      'Anneliese', 'Friedrich', 'Brunhilde', 'Ernst', 'Lieselotte', 'Otto', 'Martha',
    ];
    final rechtsgrundlagen = ['§53 SGB IX', '§78 SGB IX', '§99 SGB IX', '§113 SGB IX'];
    final hilfeTypen = [HilfeTyp.eingliederungshilfe, HilfeTyp.familienhilfe];
    final farben = ['FF1976D2', 'FFE91E63', 'FF4CAF50', 'FFFF9800', 'FF9C27B0',
                     'FF00BCD4', 'FFCDDC39', 'FFFF5722', 'FF795548', 'FF607D8B'];

    for (int i = 0; i < 40; i++) {
      final client = Client.create(
        name: '${klientenVornamen[i]} ${_nachnamen[i % _nachnamen.length]}',
        vorname: klientenVornamen[i],
        nachname: _nachnamen[i % _nachnamen.length],
        klientenId: 'KL-${2000 + i}',
        geburtsdatum: DateTime(1950 + _rng.nextInt(50), _rng.nextInt(12) + 1, _rng.nextInt(28) + 1),
        betreuungSeit: DateTime(2022 + _rng.nextInt(3), _rng.nextInt(12) + 1, 1),
        kostenuebernahme: ['Bezirksamt Mitte', 'Bezirksamt Neukoelln', 'Bezirksamt Pankow', 'Senatsverwaltung'][_rng.nextInt(4)],
        kostenuebernahmeVon: DateTime(2025, 1, 1),
        kostenuebernahmeBis: DateTime(2026, 12, 31),
        fachleistungsstunden: 30 + _rng.nextInt(120),
        fachleistungsIntervall: FachleistungsIntervall.monatlich,
        hilfeTyp: hilfeTypen[_rng.nextInt(2)],
        verbrauchteStunden: _rng.nextDouble() * 80,
        rechtsgrundlage: rechtsgrundlagen[_rng.nextInt(rechtsgrundlagen.length)],
        customColor: farben[i % farben.length],
        einwilligungVorhanden: _rng.nextBool(),
        einwilligungDatum: _rng.nextBool() ? DateTime(2025, _rng.nextInt(12) + 1, _rng.nextInt(28) + 1) : null,
      );
      await app.addClient(client);
    }

    // 3. Termine (200, verteilt ueber 3 Monate)
    final clients = app.clients;
    for (int i = 0; i < 200; i++) {
      final client = clients[_rng.nextInt(clients.length)];
      final daysAgo = _rng.nextInt(90);
      final datum = DateTime.now().subtract(Duration(days: daysAgo));
      final startHour = 8 + _rng.nextInt(8);
      final durationMinutes = [30, 45, 60, 90, 120][_rng.nextInt(5)];

      final apt = Appointment(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
        clientId: client.id,
        clientName: client.name,
        date: datum,
        startTime: DateTime(datum.year, datum.month, datum.day, startHour, 0),
        endTime: DateTime(datum.year, datum.month, datum.day, startHour, durationMinutes),
        notes: 'Testdokumentation fuer ${client.vorname}: ${_taetigkeiten[_rng.nextInt(_taetigkeiten.length)]}. '
            'Verlauf positiv, naechster Termin in einer Woche geplant.',
        berufsgruppe: 'Sozialpaedagoge/in',
        eingliederung: 'Soziale Teilhabe',
        createdAt: datum,
        recordedText: '',
      );
      await app.addAppointment(apt);
    }

    // 4. Arbeitszeiten (150, mit verschiedenen Status)
    final statusWerte = [
      ArbeitszeitStatus.eingereicht,
      ArbeitszeitStatus.eingereicht,
      ArbeitszeitStatus.genehmigt,
      ArbeitszeitStatus.genehmigt,
      ArbeitszeitStatus.genehmigt,
      ArbeitszeitStatus.abgelehnt,
    ];
    for (int i = 0; i < 150; i++) {
      final ma = mitarbeiter[_rng.nextInt(mitarbeiter.length)];
      final daysAgo = _rng.nextInt(60);
      final datum = DateTime.now().subtract(Duration(days: daysAgo));
      final startHour = 7 + _rng.nextInt(3);
      final endHour = startHour + 7 + _rng.nextInt(2);
      final status = statusWerte[_rng.nextInt(statusWerte.length)];

      final az = Arbeitszeit(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_az$i',
        datum: datum,
        startzeit: DateTime(datum.year, datum.month, datum.day, startHour, 0),
        endzeit: DateTime(datum.year, datum.month, datum.day, endHour, 0),
        taetigkeit: _taetigkeiten[_rng.nextInt(_taetigkeiten.length)],
        notizen: 'Arbeitszeit ${ma.vorname} ${ma.name}',
        createdAt: datum,
        typ: ArbeitszeitTyp.values[_rng.nextInt(ArbeitszeitTyp.values.length)],
        mitarbeiterId: ma.id,
        genehmigungsStatus: status,
        genehmigungsDatum: status == ArbeitszeitStatus.genehmigt ? datum : null,
        genehmigtVon: status == ArbeitszeitStatus.genehmigt ? 'Admin' : null,
      );
      await app.addArbeitszeit(az);
    }

    // 5. Freizeit-Antraege (20)
    final freizeitTypen = FreizeitTyp.values;
    final antragStatusWerte = [AntragStatus.beantragt, AntragStatus.beantragt,
                                AntragStatus.genehmigt, AntragStatus.abgelehnt];
    for (int i = 0; i < 20; i++) {
      final ma = mitarbeiter[_rng.nextInt(mitarbeiter.length)];
      final startDays = _rng.nextInt(60);
      final dauer = 1 + _rng.nextInt(14);
      final von = DateTime.now().add(Duration(days: startDays - 30));
      final bis = von.add(Duration(days: dauer));
      final typ = freizeitTypen[_rng.nextInt(freizeitTypen.length)];
      final status = antragStatusWerte[_rng.nextInt(antragStatusWerte.length)];

      final antrag = FreizeitAntrag(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_fa$i',
        mitarbeiterId: ma.id,
        typ: typ,
        vonDatum: von,
        bisDatum: bis,
        grund: typ == FreizeitTyp.urlaub ? 'Jahresurlaub' :
               typ == FreizeitTyp.krankmeldung ? 'Krankmeldung' :
               typ == FreizeitTyp.fortbildung ? 'Fachfortbildung Eingliederungshilfe' :
               'Antrag ${ma.vorname}',
        status: status,
        antragsDatum: DateTime.now().subtract(Duration(days: 5 + _rng.nextInt(30))),
        genehmigungsDatum: status == AntragStatus.genehmigt ? DateTime.now() : null,
        genehmigungsNotiz: status == AntragStatus.genehmigt ? 'Genehmigt' :
                           status == AntragStatus.abgelehnt ? 'Leider nicht moeglich' : null,
      );
      await app.addFreizeitAntrag(antrag);
    }
  }
}
