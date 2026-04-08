import 'package:json_annotation/json_annotation.dart';

part 'mitarbeiter.g.dart';

enum MitarbeiterBereich {
  @JsonValue('eingliederungshilfe')
  eingliederungshilfe,
  @JsonValue('familienhilfe')
  familienhilfe,
  @JsonValue('jugendhilfe')
  jugendhilfe,
  @JsonValue('sozialhilfe')
  sozialhilfe,
  @JsonValue('betreuung')
  betreuung,
  @JsonValue('verwaltung')
  verwaltung
}

@JsonSerializable()
class Mitarbeiter {
  final String id;
  final String name;
  final String vorname;
  final String email;
  final String telefon;
  final int teamNummer;
  final List<String> teamIds;
  final MitarbeiterBereich bereich;
  final DateTime createdAt;
  final bool isActive;
  final double wochenarbeitszeit;
  final int urlaubstage;

  Mitarbeiter({
    required this.id,
    required this.name,
    required this.vorname,
    required this.email,
    required this.telefon,
    required this.teamNummer,
    this.teamIds = const [],
    required this.bereich,
    required this.createdAt,
    this.isActive = true,
    this.wochenarbeitszeit = 40.0,
    this.urlaubstage = 30,
  });

  Mitarbeiter.create({
    required this.name,
    required this.vorname,
    required this.email,
    required this.telefon,
    required this.teamNummer,
    this.teamIds = const [],
    required this.bereich,
    this.isActive = true,
    this.wochenarbeitszeit = 40.0,
    this.urlaubstage = 30,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = DateTime.now();

  factory Mitarbeiter.fromJson(Map<String, dynamic> json) => _$MitarbeiterFromJson(json);
  Map<String, dynamic> toJson() => _$MitarbeiterToJson(this);

  Mitarbeiter copyWith({
    String? name,
    String? vorname,
    String? email,
    String? telefon,
    int? teamNummer,
    List<String>? teamIds,
    MitarbeiterBereich? bereich,
    bool? isActive,
    double? wochenarbeitszeit,
    int? urlaubstage,
  }) {
    return Mitarbeiter(
      id: id,
      name: name ?? this.name,
      vorname: vorname ?? this.vorname,
      email: email ?? this.email,
      telefon: telefon ?? this.telefon,
      teamNummer: teamNummer ?? this.teamNummer,
      teamIds: teamIds ?? this.teamIds,
      bereich: bereich ?? this.bereich,
      createdAt: createdAt,
      isActive: isActive ?? this.isActive,
      wochenarbeitszeit: wochenarbeitszeit ?? this.wochenarbeitszeit,
      urlaubstage: urlaubstage ?? this.urlaubstage,
    );
  }

  String get vollstaendigerName => '$vorname $name';

  String get bereichDisplayName {
    switch (bereich) {
      case MitarbeiterBereich.eingliederungshilfe:
        return 'Eingliederungshilfe';
      case MitarbeiterBereich.familienhilfe:
        return 'Familienhilfe';
      case MitarbeiterBereich.jugendhilfe:
        return 'Jugendhilfe';
      case MitarbeiterBereich.sozialhilfe:
        return 'Sozialhilfe';
      case MitarbeiterBereich.betreuung:
        return 'Betreuung';
      case MitarbeiterBereich.verwaltung:
        return 'Verwaltung';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Mitarbeiter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}