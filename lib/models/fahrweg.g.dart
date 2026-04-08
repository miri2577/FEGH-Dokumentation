// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fahrweg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Fahrweg _$FahrwegFromJson(Map<String, dynamic> json) => Fahrweg(
  id: json['id'] as String,
  datum: DateTime.parse(json['datum'] as String),
  startStandortId: json['startStandortId'] as String,
  startStandortName: json['startStandortName'] as String,
  zielStandortId: json['zielStandortId'] as String,
  zielStandortName: json['zielStandortName'] as String,
  distanzKm: (json['distanzKm'] as num).toDouble(),
  appointmentId: json['appointmentId'] as String?,
  clientId: json['clientId'] as String?,
  notizen: json['notizen'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
);

Map<String, dynamic> _$FahrwegToJson(Fahrweg instance) => <String, dynamic>{
  'id': instance.id,
  'datum': instance.datum.toIso8601String(),
  'startStandortId': instance.startStandortId,
  'startStandortName': instance.startStandortName,
  'zielStandortId': instance.zielStandortId,
  'zielStandortName': instance.zielStandortName,
  'distanzKm': instance.distanzKm,
  'appointmentId': instance.appointmentId,
  'clientId': instance.clientId,
  'notizen': instance.notizen,
  'createdAt': instance.createdAt.toIso8601String(),
};
