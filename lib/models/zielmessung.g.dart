// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'zielmessung.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Zielmessung _$ZielmessungFromJson(Map<String, dynamic> json) => Zielmessung(
  id: json['id'] as String,
  zielId: json['zielId'] as String,
  clientId: json['clientId'] as String,
  messdatum: DateTime.parse(json['messdatum'] as String),
  typ: $enumDecode(_$MesszeitpunktTypEnumMap, json['typ']),
  bewertung: $enumDecode(_$GasBewertungEnumMap, json['bewertung']),
  kommentar: json['kommentar'] as String?,
  bewertetVon: json['bewertetVon'] as String,
  erstelltAm: DateTime.parse(json['erstelltAm'] as String),
);

Map<String, dynamic> _$ZielmessungToJson(Zielmessung instance) =>
    <String, dynamic>{
      'id': instance.id,
      'zielId': instance.zielId,
      'clientId': instance.clientId,
      'messdatum': instance.messdatum.toIso8601String(),
      'typ': _$MesszeitpunktTypEnumMap[instance.typ]!,
      'bewertung': _$GasBewertungEnumMap[instance.bewertung]!,
      'kommentar': instance.kommentar,
      'bewertetVon': instance.bewertetVon,
      'erstelltAm': instance.erstelltAm.toIso8601String(),
    };

const _$MesszeitpunktTypEnumMap = {
  MesszeitpunktTyp.baseline: 'baseline',
  MesszeitpunktTyp.zwischenmessung: 'zwischenmessung',
  MesszeitpunktTyp.endmessung: 'endmessung',
  MesszeitpunktTyp.adhoc: 'adhoc',
};

const _$GasBewertungEnumMap = {
  GasBewertung.deutlichSchlechter: -2,
  GasBewertung.schlechter: -1,
  GasBewertung.wieErwartet: 0,
  GasBewertung.besser: 1,
  GasBewertung.deutlichBesser: 2,
};
