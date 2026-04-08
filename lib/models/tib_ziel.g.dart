// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tib_ziel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TIBZiel _$TIBZielFromJson(Map<String, dynamic> json) => TIBZiel(
  id: json['id'] as String,
  bereich: $enumDecode(_$TIBBereichEnumMap, json['bereich']),
  beschreibung: json['beschreibung'] as String,
  messbareKriterien: json['messbareKriterien'] as String,
  erstelltAm: DateTime.parse(json['erstelltAm'] as String),
  zielTermin: json['zielTermin'] == null
      ? null
      : DateTime.parse(json['zielTermin'] as String),
  status:
      $enumDecodeNullable(_$ZielStatusEnumMap, json['status']) ??
      ZielStatus.aktiv,
  prioritaet: (json['prioritaet'] as num?)?.toInt() ?? 3,
  fortschritte:
      (json['fortschritte'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
);

Map<String, dynamic> _$TIBZielToJson(TIBZiel instance) => <String, dynamic>{
  'id': instance.id,
  'bereich': _$TIBBereichEnumMap[instance.bereich]!,
  'beschreibung': instance.beschreibung,
  'messbareKriterien': instance.messbareKriterien,
  'erstelltAm': instance.erstelltAm.toIso8601String(),
  'zielTermin': instance.zielTermin?.toIso8601String(),
  'status': _$ZielStatusEnumMap[instance.status]!,
  'prioritaet': instance.prioritaet,
  'fortschritte': instance.fortschritte,
};

const _$TIBBereichEnumMap = {
  TIBBereich.lernenWissen: 'lernen_wissen',
  TIBBereich.aufgabenAnforderungen: 'aufgaben_anforderungen',
  TIBBereich.kommunikation: 'kommunikation',
  TIBBereich.mobilitat: 'mobilitat',
  TIBBereich.selbstversorgung: 'selbstversorgung',
  TIBBereich.hauslichesLeben: 'hausliches_leben',
  TIBBereich.interaktionenBeziehungen: 'interaktionen_beziehungen',
  TIBBereich.lebensbereiche: 'lebensbereiche',
  TIBBereich.gemeinschaftsleben: 'gemeinschaftsleben',
};

const _$ZielStatusEnumMap = {
  ZielStatus.aktiv: 'aktiv',
  ZielStatus.erreicht: 'erreicht',
  ZielStatus.pausiert: 'pausiert',
  ZielStatus.abgebrochen: 'abgebrochen',
};
