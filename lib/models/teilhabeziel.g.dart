// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'teilhabeziel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Teilhabeziel _$TeilhabezielFromJson(Map<String, dynamic> json) => Teilhabeziel(
  id: json['id'] as String,
  clientId: json['clientId'] as String,
  titel: json['titel'] as String,
  beschreibung: json['beschreibung'] as String? ?? '',
  spezifisch: json['spezifisch'] as String?,
  messbar: json['messbar'] as String?,
  attraktiv: json['attraktiv'] as String?,
  realistisch: json['realistisch'] as String?,
  terminiert: json['terminiert'] == null
      ? null
      : DateTime.parse(json['terminiert'] as String),
  icfBereich: json['icfBereich'] as String?,
  icfKategorie: json['icfKategorie'] as String?,
  kategorie:
      $enumDecodeNullable(_$TeilhabezielKategorieEnumMap, json['kategorie']) ??
      TeilhabezielKategorie.teilziel,
  status:
      $enumDecodeNullable(_$TeilhabezielStatusEnumMap, json['status']) ??
      TeilhabezielStatus.aktiv,
  prioritaet: (json['prioritaet'] as num?)?.toInt() ?? 3,
  erstelltAm: DateTime.parse(json['erstelltAm'] as String),
  geaendertAm: json['geaendertAm'] == null
      ? null
      : DateTime.parse(json['geaendertAm'] as String),
  erreichtAm: json['erreichtAm'] == null
      ? null
      : DateTime.parse(json['erreichtAm'] as String),
  parentZielId: json['parentZielId'] as String?,
  erstelltVon: json['erstelltVon'] as String?,
);

Map<String, dynamic> _$TeilhabezielToJson(Teilhabeziel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'titel': instance.titel,
      'beschreibung': instance.beschreibung,
      'spezifisch': instance.spezifisch,
      'messbar': instance.messbar,
      'attraktiv': instance.attraktiv,
      'realistisch': instance.realistisch,
      'terminiert': instance.terminiert?.toIso8601String(),
      'icfBereich': instance.icfBereich,
      'icfKategorie': instance.icfKategorie,
      'kategorie': _$TeilhabezielKategorieEnumMap[instance.kategorie]!,
      'status': _$TeilhabezielStatusEnumMap[instance.status]!,
      'prioritaet': instance.prioritaet,
      'erstelltAm': instance.erstelltAm.toIso8601String(),
      'geaendertAm': instance.geaendertAm?.toIso8601String(),
      'erreichtAm': instance.erreichtAm?.toIso8601String(),
      'parentZielId': instance.parentZielId,
      'erstelltVon': instance.erstelltVon,
    };

const _$TeilhabezielKategorieEnumMap = {
  TeilhabezielKategorie.leitziel: 'leitziel',
  TeilhabezielKategorie.teilziel: 'teilziel',
  TeilhabezielKategorie.handlungsziel: 'handlungsziel',
};

const _$TeilhabezielStatusEnumMap = {
  TeilhabezielStatus.aktiv: 'aktiv',
  TeilhabezielStatus.erreicht: 'erreicht',
  TeilhabezielStatus.pausiert: 'pausiert',
  TeilhabezielStatus.abgebrochen: 'abgebrochen',
};
