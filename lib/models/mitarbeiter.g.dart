// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mitarbeiter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Mitarbeiter _$MitarbeiterFromJson(Map<String, dynamic> json) => Mitarbeiter(
  id: json['id'] as String,
  name: json['name'] as String,
  vorname: json['vorname'] as String,
  email: json['email'] as String,
  telefon: json['telefon'] as String,
  teamNummer: (json['teamNummer'] as num).toInt(),
  teamIds:
      (json['teamIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  bereich: $enumDecode(_$MitarbeiterBereichEnumMap, json['bereich']),
  createdAt: DateTime.parse(json['createdAt'] as String),
  isActive: json['isActive'] as bool? ?? true,
  wochenarbeitszeit: (json['wochenarbeitszeit'] as num?)?.toDouble() ?? 40.0,
  urlaubstage: (json['urlaubstage'] as num?)?.toInt() ?? 30,
);

Map<String, dynamic> _$MitarbeiterToJson(Mitarbeiter instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'vorname': instance.vorname,
      'email': instance.email,
      'telefon': instance.telefon,
      'teamNummer': instance.teamNummer,
      'teamIds': instance.teamIds,
      'bereich': _$MitarbeiterBereichEnumMap[instance.bereich]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'isActive': instance.isActive,
      'wochenarbeitszeit': instance.wochenarbeitszeit,
      'urlaubstage': instance.urlaubstage,
    };

const _$MitarbeiterBereichEnumMap = {
  MitarbeiterBereich.eingliederungshilfe: 'eingliederungshilfe',
  MitarbeiterBereich.familienhilfe: 'familienhilfe',
  MitarbeiterBereich.jugendhilfe: 'jugendhilfe',
  MitarbeiterBereich.sozialhilfe: 'sozialhilfe',
  MitarbeiterBereich.betreuung: 'betreuung',
  MitarbeiterBereich.verwaltung: 'verwaltung',
};
