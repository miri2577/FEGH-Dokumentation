// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'standort.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Standort _$StandortFromJson(Map<String, dynamic> json) => Standort(
  id: json['id'] as String,
  name: json['name'] as String,
  typ: $enumDecode(_$StandortTypEnumMap, json['typ']),
  clientId: json['clientId'] as String?,
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$StandortToJson(Standort instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'typ': _$StandortTypEnumMap[instance.typ]!,
  'clientId': instance.clientId,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'createdAt': instance.createdAt.toIso8601String(),
};

const _$StandortTypEnumMap = {
  StandortTyp.buero: 'buero',
  StandortTyp.klient: 'klient',
  StandortTyp.amt: 'amt',
  StandortTyp.sonstige: 'sonstige',
};
