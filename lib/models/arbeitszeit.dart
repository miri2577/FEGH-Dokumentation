import 'package:json_annotation/json_annotation.dart';

part 'arbeitszeit.g.dart';

@JsonSerializable()
class Arbeitszeit {
  final String id;
  final DateTime datum;
  final DateTime startzeit;
  final DateTime endzeit;
  final String taetigkeit;
  final String notizen;
  final DateTime createdAt;
  final String? clientId; // Optional: Verknüpfung zu einem Klienten
  final String? appointmentId; // Optional: Verknüpfung zu einem Termin
  final ArbeitszeitTyp typ; // Betreuung, Büro, Fahrt, etc.

  Arbeitszeit({
    required this.id,
    required this.datum,
    required this.startzeit,
    required this.endzeit,
    required this.taetigkeit,
    required this.notizen,
    required this.createdAt,
    this.clientId,
    this.appointmentId,
    this.typ = ArbeitszeitTyp.betreuung,
  });

  Arbeitszeit.create({
    required this.datum,
    required this.startzeit,
    required this.endzeit,
    required this.taetigkeit,
    required this.notizen,
    this.clientId,
    this.appointmentId,
    this.typ = ArbeitszeitTyp.betreuung,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = DateTime.now();

  factory Arbeitszeit.fromJson(Map<String, dynamic> json) => _$ArbeitszeitFromJson(json);
  Map<String, dynamic> toJson() => _$ArbeitszeitToJson(this);

  Arbeitszeit copyWith({
    DateTime? datum,
    DateTime? startzeit,
    DateTime? endzeit,
    String? taetigkeit,
    String? notizen,
    String? clientId,
    String? appointmentId,
    ArbeitszeitTyp? typ,
  }) {
    return Arbeitszeit(
      id: id,
      datum: datum ?? this.datum,
      startzeit: startzeit ?? this.startzeit,
      endzeit: endzeit ?? this.endzeit,
      taetigkeit: taetigkeit ?? this.taetigkeit,
      notizen: notizen ?? this.notizen,
      createdAt: createdAt,
      clientId: clientId ?? this.clientId,
      appointmentId: appointmentId ?? this.appointmentId,
      typ: typ ?? this.typ,
    );
  }

  // Berechnung der Arbeitszeit
  Duration get arbeitszeit => endzeit.difference(startzeit);
  
  String get formatierteArbeitszeit {
    final duration = arbeitszeit;
    final stunden = duration.inHours;
    final minuten = duration.inMinutes.remainder(60);
    return '${stunden}h ${minuten}m';
  }

  double get arbeitszeitInStunden {
    return arbeitszeit.inMinutes / 60.0;
  }

  String get formatiertesDatum {
    return '${datum.day}.${datum.month}.${datum.year}';
  }

  String get formatierteStartzeit {
    return '${startzeit.hour.toString().padLeft(2, '0')}:${startzeit.minute.toString().padLeft(2, '0')}';
  }

  String get formatierteEndzeit {
    return '${endzeit.hour.toString().padLeft(2, '0')}:${endzeit.minute.toString().padLeft(2, '0')}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Arbeitszeit &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          datum == other.datum;

  @override
  int get hashCode => id.hashCode ^ datum.hashCode;
}

// Vordefinierte Tätigkeiten für Berlin
class ArbeitszeitTaetigkeiten {
  static const List<String> standard = [
    'Klientengespräch',
    'Hausbesuch',
    'Dokumentation',
    'Telefonate',
    'Beratung',
    'Begleitung zu Terminen',
    'Verwaltung',
    'Fortbildung',
    'Teambesprechung',
    'Fallbesprechung',
    'Krisenintervention',
    'Netzwerkarbeit',
    'Sonstige',
  ];

  static const List<String> familienhilfe = [
    'Hausbesuch Familie',
    'Einzelgespräch mit Erziehungsberechtigten',
    'Gespräch mit Kind/Jugendlichem',
    'Familientherapeut. Gespräch',
    'Begleitung zu Ämtern',
    'Begleitung zu Arztterminen',
    'Schulbesuch',
    'Kindergartenbesuch',
    'Krisenintervention Familie',
    'Dokumentation SGB VIII',
    'Hilfeplanung',
    'Netzwerkkonferenz',
    ...standard,
  ];

  static const List<String> eingliederungshilfe = [
    'Einzelbetreuung',
    'Gruppentätigkeit',
    'Assistenz bei Alltagsaktivitäten',
    'Begleitung zu Therapien',
    'Teilhabeplanung',
    'ICF-Dokumentation',
    'Bedarfsermittlung',
    'Angehörigenberatung',
    'Sozialraumarbeit',
    'Freizeitgestaltung',
    'Arbeitsplatzbegleitung',
    'Wohntraining',
    ...standard,
  ];
}

enum ArbeitszeitTyp {
  betreuung,
  buero,
  fahrt,
  dokumentation,
  verwaltung,
  fortbildung,
  teambesprechung,
  sonstige,
}

extension ArbeitszeitTypExtension on ArbeitszeitTyp {
  String get displayName {
    switch (this) {
      case ArbeitszeitTyp.betreuung:
        return 'Betreuung';
      case ArbeitszeitTyp.buero:
        return 'Bürozeiten';
      case ArbeitszeitTyp.fahrt:
        return 'Fahrtzeiten';
      case ArbeitszeitTyp.dokumentation:
        return 'Dokumentation';
      case ArbeitszeitTyp.verwaltung:
        return 'Verwaltung';
      case ArbeitszeitTyp.fortbildung:
        return 'Fortbildung';
      case ArbeitszeitTyp.teambesprechung:
        return 'Teambesprechung';
      case ArbeitszeitTyp.sonstige:
        return 'Sonstige';
    }
  }
}