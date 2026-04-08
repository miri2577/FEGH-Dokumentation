import 'package:json_annotation/json_annotation.dart';

part 'tib_ziel.g.dart';

enum TIBBereich {
  @JsonValue('lernen_wissen')
  lernenWissen,
  @JsonValue('aufgaben_anforderungen')
  aufgabenAnforderungen,
  @JsonValue('kommunikation')
  kommunikation,
  @JsonValue('mobilitat')
  mobilitat,
  @JsonValue('selbstversorgung')
  selbstversorgung,
  @JsonValue('hausliches_leben')
  hauslichesLeben,
  @JsonValue('interaktionen_beziehungen')
  interaktionenBeziehungen,
  @JsonValue('lebensbereiche')
  lebensbereiche,
  @JsonValue('gemeinschaftsleben')
  gemeinschaftsleben
}

enum ZielStatus {
  @JsonValue('aktiv')
  aktiv,
  @JsonValue('erreicht')
  erreicht,
  @JsonValue('pausiert')
  pausiert,
  @JsonValue('abgebrochen')
  abgebrochen
}

@JsonSerializable()
class TIBZiel {
  final String id;
  final TIBBereich bereich;
  final String beschreibung;
  final String messbareKriterien;
  final DateTime erstelltAm;
  final DateTime? zielTermin;
  final ZielStatus status;
  final int prioritaet; // 1-5
  final List<String> fortschritte;

  TIBZiel({
    required this.id,
    required this.bereich,
    required this.beschreibung,
    required this.messbareKriterien,
    required this.erstelltAm,
    this.zielTermin,
    this.status = ZielStatus.aktiv,
    this.prioritaet = 3,
    this.fortschritte = const [],
  });

  TIBZiel.create({
    required this.bereich,
    required this.beschreibung,
    required this.messbareKriterien,
    this.zielTermin,
    this.prioritaet = 3,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       erstelltAm = DateTime.now(),
       status = ZielStatus.aktiv,
       fortschritte = const [];

  factory TIBZiel.fromJson(Map<String, dynamic> json) => _$TIBZielFromJson(json);
  Map<String, dynamic> toJson() => _$TIBZielToJson(this);

  TIBZiel copyWith({
    TIBBereich? bereich,
    String? beschreibung,
    String? messbareKriterien,
    DateTime? zielTermin,
    ZielStatus? status,
    int? prioritaet,
    List<String>? fortschritte,
  }) {
    return TIBZiel(
      id: id,
      bereich: bereich ?? this.bereich,
      beschreibung: beschreibung ?? this.beschreibung,
      messbareKriterien: messbareKriterien ?? this.messbareKriterien,
      erstelltAm: erstelltAm,
      zielTermin: zielTermin ?? this.zielTermin,
      status: status ?? this.status,
      prioritaet: prioritaet ?? this.prioritaet,
      fortschritte: fortschritte ?? this.fortschritte,
    );
  }

  String get bereichsName {
    switch (bereich) {
      case TIBBereich.lernenWissen:
        return 'Lernen und Wissensanwendung';
      case TIBBereich.aufgabenAnforderungen:
        return 'Allgemeine Aufgaben und Anforderungen';
      case TIBBereich.kommunikation:
        return 'Kommunikation';
      case TIBBereich.mobilitat:
        return 'Mobilität';
      case TIBBereich.selbstversorgung:
        return 'Selbstversorgung';
      case TIBBereich.hauslichesLeben:
        return 'Häusliches Leben';
      case TIBBereich.interaktionenBeziehungen:
        return 'Interpersonelle Interaktionen und Beziehungen';
      case TIBBereich.lebensbereiche:
        return 'Bedeutende Lebensbereiche';
      case TIBBereich.gemeinschaftsleben:
        return 'Gemeinschafts-, soziales und staatsbürgerliches Leben';
    }
  }

  String get statusName {
    switch (status) {
      case ZielStatus.aktiv:
        return 'Aktiv';
      case ZielStatus.erreicht:
        return 'Erreicht';
      case ZielStatus.pausiert:
        return 'Pausiert';
      case ZielStatus.abgebrochen:
        return 'Abgebrochen';
    }
  }
}