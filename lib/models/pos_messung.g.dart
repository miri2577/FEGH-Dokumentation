// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pos_messung.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosMessung _$PosMessungFromJson(Map<String, dynamic> json) => PosMessung(
  id: json['id'] as String,
  clientId: json['clientId'] as String,
  messdatum: DateTime.parse(json['messdatum'] as String),
  bewertetVon: json['bewertetVon'] as String,
  erstelltAm: DateTime.parse(json['erstelltAm'] as String),
  bewertungen: (json['bewertungen'] as Map<String, dynamic>).map(
    (k, e) => MapEntry(
      k,
      (e as List<dynamic>).map((e) => (e as num).toInt()).toList(),
    ),
  ),
  kommentar: json['kommentar'] as String?,
);

Map<String, dynamic> _$PosMessungToJson(PosMessung instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'messdatum': instance.messdatum.toIso8601String(),
      'bewertetVon': instance.bewertetVon,
      'erstelltAm': instance.erstelltAm.toIso8601String(),
      'kommentar': instance.kommentar,
      'bewertungen': instance.bewertungen,
    };
