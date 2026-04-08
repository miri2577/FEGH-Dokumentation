// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'appointment.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ClientAllocation _$ClientAllocationFromJson(Map<String, dynamic> json) =>
    ClientAllocation(
      clientId: json['clientId'] as String,
      clientName: json['clientName'] as String,
      minuten: (json['minuten'] as num).toInt(),
    );

Map<String, dynamic> _$ClientAllocationToJson(ClientAllocation instance) =>
    <String, dynamic>{
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'minuten': instance.minuten,
    };

Appointment _$AppointmentFromJson(Map<String, dynamic> json) => Appointment(
  id: json['id'] as String,
  clientId: json['clientId'] as String,
  clientName: json['clientName'] as String,
  date: DateTime.parse(json['date'] as String),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  notes: json['notes'] as String,
  recordedText: json['recordedText'] as String,
  berufsgruppe: json['berufsgruppe'] as String,
  eingliederung: json['eingliederung'] as String,
  createdAt: DateTime.parse(json['createdAt'] as String),
  icfBereiche:
      (json['icfBereiche'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  fachleistungsstunden:
      (json['fachleistungsstunden'] as num?)?.toDouble() ?? 0.0,
  familienhilfeKategorien:
      (json['familienhilfeKategorien'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  tibBereiche:
      (json['tibBereiche'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  selectedTibZiele: (json['selectedTibZiele'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  tibZielMinuten: (json['tibZielMinuten'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(k, (e as num).toInt()),
  ),
  fahrwegHinId: json['fahrwegHinId'] as String?,
  fahrwegRueckId: json['fahrwegRueckId'] as String?,
  terminArt: $enumDecodeNullable(_$TerminArtEnumMap, json['terminArt']),
  clientAllocations: (json['clientAllocations'] as List<dynamic>?)
      ?.map((e) => ClientAllocation.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$AppointmentToJson(Appointment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'clientId': instance.clientId,
      'clientName': instance.clientName,
      'date': instance.date.toIso8601String(),
      'startTime': instance.startTime.toIso8601String(),
      'endTime': instance.endTime.toIso8601String(),
      'notes': instance.notes,
      'recordedText': instance.recordedText,
      'berufsgruppe': instance.berufsgruppe,
      'eingliederung': instance.eingliederung,
      'createdAt': instance.createdAt.toIso8601String(),
      'icfBereiche': instance.icfBereiche,
      'fachleistungsstunden': instance.fachleistungsstunden,
      'familienhilfeKategorien': instance.familienhilfeKategorien,
      'tibBereiche': instance.tibBereiche,
      'selectedTibZiele': instance.selectedTibZiele,
      'tibZielMinuten': instance.tibZielMinuten,
      'fahrwegHinId': instance.fahrwegHinId,
      'fahrwegRueckId': instance.fahrwegRueckId,
      'terminArt': _$TerminArtEnumMap[instance.terminArt],
      'clientAllocations': instance.clientAllocations,
    };

const _$TerminArtEnumMap = {
  TerminArt.kliententermin: 'kliententermin',
  TerminArt.buero: 'buero',
  TerminArt.dokumentation: 'dokumentation',
  TerminArt.supervision: 'supervision',
  TerminArt.teamsitzung: 'teamsitzung',
  TerminArt.fortbildung: 'fortbildung',
  TerminArt.fahrtzeit: 'fahrtzeit',
  TerminArt.sonstige: 'sonstige',
};
