// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'arbeitszeit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Arbeitszeit _$ArbeitszeitFromJson(Map<String, dynamic> json) => Arbeitszeit(
  id: json['id'] as String,
  datum: DateTime.parse(json['datum'] as String),
  startzeit: DateTime.parse(json['startzeit'] as String),
  endzeit: DateTime.parse(json['endzeit'] as String),
  taetigkeit: json['taetigkeit'] as String,
  notizen: json['notizen'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  clientId: json['clientId'] as String?,
  appointmentId: json['appointmentId'] as String?,
  typ:
      $enumDecodeNullable(_$ArbeitszeitTypEnumMap, json['typ']) ??
      ArbeitszeitTyp.betreuung,
  mitarbeiterId: json['mitarbeiterId'] as String?,
  genehmigungsStatus:
      $enumDecodeNullable(
        _$ArbeitszeitStatusEnumMap,
        json['genehmigungsStatus'],
      ) ??
      ArbeitszeitStatus.eingereicht,
  genehmigungsDatum: json['genehmigungsDatum'] == null
      ? null
      : DateTime.parse(json['genehmigungsDatum'] as String),
  genehmigungsNotiz: json['genehmigungsNotiz'] as String?,
  genehmigtVon: json['genehmigtVon'] as String?,
);

Map<String, dynamic> _$ArbeitszeitToJson(Arbeitszeit instance) =>
    <String, dynamic>{
      'id': instance.id,
      'datum': instance.datum.toIso8601String(),
      'startzeit': instance.startzeit.toIso8601String(),
      'endzeit': instance.endzeit.toIso8601String(),
      'taetigkeit': instance.taetigkeit,
      'notizen': instance.notizen,
      'createdAt': instance.createdAt.toIso8601String(),
      'clientId': instance.clientId,
      'appointmentId': instance.appointmentId,
      'typ': _$ArbeitszeitTypEnumMap[instance.typ]!,
      'mitarbeiterId': instance.mitarbeiterId,
      'genehmigungsStatus':
          _$ArbeitszeitStatusEnumMap[instance.genehmigungsStatus]!,
      'genehmigungsDatum': instance.genehmigungsDatum?.toIso8601String(),
      'genehmigungsNotiz': instance.genehmigungsNotiz,
      'genehmigtVon': instance.genehmigtVon,
    };

const _$ArbeitszeitTypEnumMap = {
  ArbeitszeitTyp.betreuung: 'betreuung',
  ArbeitszeitTyp.buero: 'buero',
  ArbeitszeitTyp.fahrt: 'fahrt',
  ArbeitszeitTyp.dokumentation: 'dokumentation',
  ArbeitszeitTyp.verwaltung: 'verwaltung',
  ArbeitszeitTyp.fortbildung: 'fortbildung',
  ArbeitszeitTyp.teambesprechung: 'teambesprechung',
  ArbeitszeitTyp.sonstige: 'sonstige',
};

const _$ArbeitszeitStatusEnumMap = {
  ArbeitszeitStatus.eingereicht: 'eingereicht',
  ArbeitszeitStatus.genehmigt: 'genehmigt',
  ArbeitszeitStatus.abgelehnt: 'abgelehnt',
  ArbeitszeitStatus.korrektur: 'korrektur',
};
