import 'package:json_annotation/json_annotation.dart';

part 'zielmessung.g.dart';

/// Messzeitpunkt-Typ fuer Laengsschnittmessungen.
enum MesszeitpunktTyp {
  @JsonValue('baseline')
  baseline,        // Erstmessung (Ausgangspunkt)
  @JsonValue('zwischenmessung')
  zwischenmessung, // Regelmaessige Zwischenmessung
  @JsonValue('endmessung')
  endmessung,      // Abschlussmessung
  @JsonValue('adhoc')
  adhoc,           // Spontane Bewertung
}

/// Goal Attainment Scaling (GAS) - 5-Punkte-Skala nach Kiresuk & Sherman 1968.
/// Wissenschaftlicher Standard fuer Zielerreichungsmessung.
enum GasBewertung {
  @JsonValue(-2)
  deutlichSchlechter,  // -2: Deutlich schlechter als erwartet
  @JsonValue(-1)
  schlechter,          // -1: Schlechter als erwartet
  @JsonValue(0)
  wieErwartet,         //  0: Wie erwartet / Ziel erreicht
  @JsonValue(1)
  besser,              // +1: Besser als erwartet
  @JsonValue(2)
  deutlichBesser,      // +2: Deutlich besser als erwartet
}

extension GasBewertungExtension on GasBewertung {
  int get wert {
    switch (this) {
      case GasBewertung.deutlichSchlechter: return -2;
      case GasBewertung.schlechter: return -1;
      case GasBewertung.wieErwartet: return 0;
      case GasBewertung.besser: return 1;
      case GasBewertung.deutlichBesser: return 2;
    }
  }

  String get displayName {
    switch (this) {
      case GasBewertung.deutlichSchlechter: return 'Deutlich schlechter (-2)';
      case GasBewertung.schlechter: return 'Schlechter (-1)';
      case GasBewertung.wieErwartet: return 'Wie erwartet (0)';
      case GasBewertung.besser: return 'Besser (+1)';
      case GasBewertung.deutlichBesser: return 'Deutlich besser (+2)';
    }
  }

  String get kurzBeschreibung {
    switch (this) {
      case GasBewertung.deutlichSchlechter: return 'Viel weniger als erhofft';
      case GasBewertung.schlechter: return 'Weniger als erhofft';
      case GasBewertung.wieErwartet: return 'Ziel erreicht';
      case GasBewertung.besser: return 'Besser als erhofft';
      case GasBewertung.deutlichBesser: return 'Viel besser als erhofft';
    }
  }
}

/// Eine konkrete Messung/Bewertung zu einem Teilhabeziel zu einem Zeitpunkt.
@JsonSerializable()
class Zielmessung {
  final String id;
  final String zielId;
  final String clientId;
  final DateTime messdatum;
  final MesszeitpunktTyp typ;
  final GasBewertung bewertung;
  final String? kommentar;
  final String bewertetVon; // Mitarbeiter-ID
  final DateTime erstelltAm;

  Zielmessung({
    required this.id,
    required this.zielId,
    required this.clientId,
    required this.messdatum,
    required this.typ,
    required this.bewertung,
    this.kommentar,
    required this.bewertetVon,
    required this.erstelltAm,
  });

  Zielmessung.create({
    required this.zielId,
    required this.clientId,
    required this.messdatum,
    required this.typ,
    required this.bewertung,
    this.kommentar,
    required this.bewertetVon,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        erstelltAm = DateTime.now();

  factory Zielmessung.fromJson(Map<String, dynamic> json) => _$ZielmessungFromJson(json);
  Map<String, dynamic> toJson() => _$ZielmessungToJson(this);

  Zielmessung copyWith({
    DateTime? messdatum,
    MesszeitpunktTyp? typ,
    GasBewertung? bewertung,
    String? kommentar,
  }) {
    return Zielmessung(
      id: id,
      zielId: zielId,
      clientId: clientId,
      messdatum: messdatum ?? this.messdatum,
      typ: typ ?? this.typ,
      bewertung: bewertung ?? this.bewertung,
      kommentar: kommentar ?? this.kommentar,
      bewertetVon: bewertetVon,
      erstelltAm: erstelltAm,
    );
  }
}
