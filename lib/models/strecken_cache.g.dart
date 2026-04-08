// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'strecken_cache.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StreckenCache _$StreckenCacheFromJson(Map<String, dynamic> json) =>
    StreckenCache(
      id: json['id'] as String,
      startStandortId: json['startStandortId'] as String,
      zielStandortId: json['zielStandortId'] as String,
      distanzKm: (json['distanzKm'] as num).toDouble(),
      nutzungsAnzahl: (json['nutzungsAnzahl'] as num).toInt(),
      zuletztGenutzt: DateTime.parse(json['zuletztGenutzt'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$StreckenCacheToJson(StreckenCache instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startStandortId': instance.startStandortId,
      'zielStandortId': instance.zielStandortId,
      'distanzKm': instance.distanzKm,
      'nutzungsAnzahl': instance.nutzungsAnzahl,
      'zuletztGenutzt': instance.zuletztGenutzt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
    };
