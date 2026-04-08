// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'freizeit_antrag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FreizeitAntrag _$FreizeitAntragFromJson(Map<String, dynamic> json) =>
    FreizeitAntrag(
      id: json['id'] as String,
      mitarbeiterId: json['mitarbeiterId'] as String,
      typ: $enumDecode(_$FreizeitTypEnumMap, json['typ']),
      vonDatum: DateTime.parse(json['vonDatum'] as String),
      bisDatum: DateTime.parse(json['bisDatum'] as String),
      grund: json['grund'] as String,
      bemerkung: json['bemerkung'] as String?,
      status:
          $enumDecodeNullable(_$AntragStatusEnumMap, json['status']) ??
          AntragStatus.beantragt,
      antragsDatum: DateTime.parse(json['antragsDatum'] as String),
      genehmigungsDatum: json['genehmigungsDatum'] == null
          ? null
          : DateTime.parse(json['genehmigungsDatum'] as String),
      genehmigungsNotiz: json['genehmigungsNotiz'] as String?,
      stunden: (json['stunden'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$FreizeitAntragToJson(FreizeitAntrag instance) =>
    <String, dynamic>{
      'id': instance.id,
      'mitarbeiterId': instance.mitarbeiterId,
      'typ': _$FreizeitTypEnumMap[instance.typ]!,
      'vonDatum': instance.vonDatum.toIso8601String(),
      'bisDatum': instance.bisDatum.toIso8601String(),
      'grund': instance.grund,
      'bemerkung': instance.bemerkung,
      'status': _$AntragStatusEnumMap[instance.status]!,
      'antragsDatum': instance.antragsDatum.toIso8601String(),
      'genehmigungsDatum': instance.genehmigungsDatum?.toIso8601String(),
      'genehmigungsNotiz': instance.genehmigungsNotiz,
      'stunden': instance.stunden,
    };

const _$FreizeitTypEnumMap = {
  FreizeitTyp.urlaub: 'urlaub',
  FreizeitTyp.freizeitausgleich: 'freizeitausgleich',
  FreizeitTyp.sonderurlaub: 'sonderurlaub',
  FreizeitTyp.fortbildung: 'fortbildung',
  FreizeitTyp.krankmeldung: 'krankmeldung',
  FreizeitTyp.unbezahlt: 'unbezahlt',
};

const _$AntragStatusEnumMap = {
  AntragStatus.beantragt: 'beantragt',
  AntragStatus.genehmigt: 'genehmigt',
  AntragStatus.abgelehnt: 'abgelehnt',
  AntragStatus.zurueckgezogen: 'zurueckgezogen',
};
