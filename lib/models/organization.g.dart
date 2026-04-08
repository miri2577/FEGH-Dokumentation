// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  address: json['address'] as String,
  phone: json['phone'] as String?,
  email: json['email'] as String?,
  website: json['website'] as String?,
  licenseNumber: json['licenseNumber'] as String?,
  type: $enumDecode(_$OrganizationTypeEnumMap, json['type']),
  services:
      (json['services'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  settings: json['settings'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'address': instance.address,
      'phone': instance.phone,
      'email': instance.email,
      'website': instance.website,
      'licenseNumber': instance.licenseNumber,
      'type': _$OrganizationTypeEnumMap[instance.type]!,
      'services': instance.services,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'settings': instance.settings,
    };

const _$OrganizationTypeEnumMap = {
  OrganizationType.residential: 'residential',
  OrganizationType.ambulant: 'ambulant',
  OrganizationType.workshop: 'workshop',
  OrganizationType.daycare: 'daycare',
  OrganizationType.counseling: 'counseling',
  OrganizationType.mixed: 'mixed',
};
