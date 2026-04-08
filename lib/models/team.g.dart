// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'team.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Team _$TeamFromJson(Map<String, dynamic> json) => Team(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String? ?? '',
  department: json['department'] as String?,
  location: json['location'] as String?,
  teamLeaderId: json['teamLeaderId'] as String?,
  memberIds:
      (json['memberIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  clientIds:
      (json['clientIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  status:
      $enumDecodeNullable(_$TeamStatusEnumMap, json['status']) ??
      TeamStatus.active,
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$TeamToJson(Team instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'department': instance.department,
  'location': instance.location,
  'teamLeaderId': instance.teamLeaderId,
  'memberIds': instance.memberIds,
  'clientIds': instance.clientIds,
  'status': _$TeamStatusEnumMap[instance.status]!,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
};

const _$TeamStatusEnumMap = {
  TeamStatus.active: 'active',
  TeamStatus.inactive: 'inactive',
  TeamStatus.onHold: 'onHold',
};
