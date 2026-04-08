// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  userName: json['userName'] as String,
  userRole:
      $enumDecodeNullable(_$UserRoleEnumMap, json['userRole']) ??
      UserRole.teamMember,
  speechAvailable: json['speechAvailable'] as bool,
  calendarKeywords: (json['calendarKeywords'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  clientNamePatterns: (json['clientNamePatterns'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  berufsgruppen: (json['berufsgruppen'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  eingliederungsarten: (json['eingliederungsarten'] as List<dynamic>)
      .map((e) => e as String)
      .toList(),
  biometricAuthEnabled: json['biometricAuthEnabled'] as bool,
  autoBackupEnabled: json['autoBackupEnabled'] as bool,
  autoBackupInterval: (json['autoBackupInterval'] as num).toInt(),
  preferredLanguage: json['preferredLanguage'] as String,
  darkModeEnabled: json['darkModeEnabled'] as bool,
  notificationsEnabled: json['notificationsEnabled'] as bool,
  wochenarbeitszeit: (json['wochenarbeitszeit'] as num).toDouble(),
  urlaubstage: (json['urlaubstage'] as num).toInt(),
  hidriveUsername: json['hidriveUsername'] as String,
  hidrivePassword: json['hidrivePassword'] as String,
  organizationId: json['organizationId'] as String,
  teamId: json['teamId'] as String,
  syncPassphrase: json['syncPassphrase'] as String,
  rootSubdirectory: json['rootSubdirectory'] as String,
  auditorCanViewDocs: json['auditorCanViewDocs'] as bool,
  setupCompleted: json['setupCompleted'] as bool? ?? false,
  kalkulationsfaktor: (json['kalkulationsfaktor'] as num?)?.toDouble() ?? 1.33,
  stundensatz: (json['stundensatz'] as num?)?.toDouble() ?? 40.0,
  bueroStandortId: json['bueroStandortId'] as String?,
  openRouteServiceApiKey: json['openRouteServiceApiKey'] as String? ?? '',
  totpSecret: json['totpSecret'] as String? ?? '',
  uiCustomization: json['uiCustomization'] == null
      ? const UICustomization()
      : _uiCustomizationFromJson(
          json['uiCustomization'] as Map<String, dynamic>?,
        ),
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'userName': instance.userName,
      'userRole': _$UserRoleEnumMap[instance.userRole]!,
      'speechAvailable': instance.speechAvailable,
      'calendarKeywords': instance.calendarKeywords,
      'clientNamePatterns': instance.clientNamePatterns,
      'berufsgruppen': instance.berufsgruppen,
      'eingliederungsarten': instance.eingliederungsarten,
      'biometricAuthEnabled': instance.biometricAuthEnabled,
      'autoBackupEnabled': instance.autoBackupEnabled,
      'autoBackupInterval': instance.autoBackupInterval,
      'preferredLanguage': instance.preferredLanguage,
      'darkModeEnabled': instance.darkModeEnabled,
      'notificationsEnabled': instance.notificationsEnabled,
      'wochenarbeitszeit': instance.wochenarbeitszeit,
      'urlaubstage': instance.urlaubstage,
      'hidriveUsername': instance.hidriveUsername,
      'hidrivePassword': instance.hidrivePassword,
      'organizationId': instance.organizationId,
      'teamId': instance.teamId,
      'syncPassphrase': instance.syncPassphrase,
      'rootSubdirectory': instance.rootSubdirectory,
      'auditorCanViewDocs': instance.auditorCanViewDocs,
      'setupCompleted': instance.setupCompleted,
      'kalkulationsfaktor': instance.kalkulationsfaktor,
      'stundensatz': instance.stundensatz,
      'bueroStandortId': instance.bueroStandortId,
      'openRouteServiceApiKey': instance.openRouteServiceApiKey,
      'totpSecret': instance.totpSecret,
      'uiCustomization': _uiCustomizationToJson(instance.uiCustomization),
    };

const _$UserRoleEnumMap = {
  UserRole.orgAdmin: 'org_admin',
  UserRole.pvAdmin: 'pv_admin',
  UserRole.teamLead: 'team_lead',
  UserRole.teamMember: 'team_member',
  UserRole.orgAuditor: 'org_auditor',
};
