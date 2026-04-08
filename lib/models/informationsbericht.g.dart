// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'informationsbericht.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Informationsbericht _$InformationsberichtFromJson(Map<String, dynamic> json) =>
    Informationsbericht(
      id: json['id'] as String,
      clientId: json['clientId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      istEntwurf: json['istEntwurf'] as bool? ?? true,
      teilhabefachdienst: json['teilhabefachdienst'] as String?,
      idKostenuebernahme: json['idKostenuebernahme'] as String?,
      berichtszeitraumVon: json['berichtszeitraumVon'] == null
          ? null
          : DateTime.parse(json['berichtszeitraumVon'] as String),
      berichtszeitraumBis: json['berichtszeitraumBis'] == null
          ? null
          : DateTime.parse(json['berichtszeitraumBis'] as String),
      leistungstyp: json['leistungstyp'] as String?,
      leistungserbringer: json['leistungserbringer'] as String?,
      emailTelNr: json['emailTelNr'] as String?,
      strasse: json['strasse'] as String?,
      hausnummer: json['hausnummer'] as String?,
      weitererAdresshinweis: json['weitererAdresshinweis'] as String?,
      postleitzahl: json['postleitzahl'] as String?,
      ort: json['ort'] as String?,
      anrede: json['anrede'] as String?,
      titel: json['titel'] as String?,
      familienname: json['familienname'] as String?,
      vorname: json['vorname'] as String?,
      geburtsname: json['geburtsname'] as String?,
      geburtsdatum: json['geburtsdatum'] == null
          ? null
          : DateTime.parse(json['geburtsdatum'] as String),
      geburtsort: json['geburtsort'] as String?,
      geschlecht: json['geschlecht'] as String?,
      familienstand: json['familienstand'] as String?,
      telefonFestnetz: json['telefonFestnetz'] as String?,
      telefonMobil: json['telefonMobil'] as String?,
      email: json['email'] as String?,
      allgemeineInformationen: json['allgemeineInformationen'] as String?,
      teilhabeziele: (json['teilhabeziele'] as List<dynamic>?)
          ?.map((e) => Teilhabeziel.fromJson(e as Map<String, dynamic>))
          .toList(),
      weitereAnmerkungen: json['weitereAnmerkungen'] as String?,
      nachtAssistenz: json['nachtAssistenz'] as bool?,
      zusammenfassung: json['zusammenfassung'] as String?,
      ortDatum: json['ortDatum'] as String?,
      leistungserbringerUnterschrift:
          json['leistungserbringerUnterschrift'] as String?,
      eintragungKlient: json['eintragungKlient'] as String?,
    );

Map<String, dynamic> _$InformationsberichtToJson(
  Informationsbericht instance,
) => <String, dynamic>{
  'id': instance.id,
  'clientId': instance.clientId,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'istEntwurf': instance.istEntwurf,
  'teilhabefachdienst': instance.teilhabefachdienst,
  'idKostenuebernahme': instance.idKostenuebernahme,
  'berichtszeitraumVon': instance.berichtszeitraumVon?.toIso8601String(),
  'berichtszeitraumBis': instance.berichtszeitraumBis?.toIso8601String(),
  'leistungstyp': instance.leistungstyp,
  'leistungserbringer': instance.leistungserbringer,
  'emailTelNr': instance.emailTelNr,
  'strasse': instance.strasse,
  'hausnummer': instance.hausnummer,
  'weitererAdresshinweis': instance.weitererAdresshinweis,
  'postleitzahl': instance.postleitzahl,
  'ort': instance.ort,
  'anrede': instance.anrede,
  'titel': instance.titel,
  'familienname': instance.familienname,
  'vorname': instance.vorname,
  'geburtsname': instance.geburtsname,
  'geburtsdatum': instance.geburtsdatum?.toIso8601String(),
  'geburtsort': instance.geburtsort,
  'geschlecht': instance.geschlecht,
  'familienstand': instance.familienstand,
  'telefonFestnetz': instance.telefonFestnetz,
  'telefonMobil': instance.telefonMobil,
  'email': instance.email,
  'allgemeineInformationen': instance.allgemeineInformationen,
  'teilhabeziele': instance.teilhabeziele,
  'weitereAnmerkungen': instance.weitereAnmerkungen,
  'nachtAssistenz': instance.nachtAssistenz,
  'zusammenfassung': instance.zusammenfassung,
  'ortDatum': instance.ortDatum,
  'leistungserbringerUnterschrift': instance.leistungserbringerUnterschrift,
  'eintragungKlient': instance.eintragungKlient,
};

Teilhabeziel _$TeilhabezielFromJson(Map<String, dynamic> json) => Teilhabeziel(
  leitzielNr: (json['leitzielNr'] as num?)?.toInt(),
  leitzielText: json['leitzielText'] as String?,
  teilhabezielNr: (json['teilhabezielNr'] as num?)?.toInt(),
  teilhabezielText: json['teilhabezielText'] as String?,
  indikator: json['indikator'] as String?,
  zielerreichung: $enumDecodeNullable(
    _$ZielerreichungStatusEnumMap,
    json['zielerreichung'],
  ),
  abweichendeEinschaetzung: json['abweichendeEinschaetzung'] as bool?,
  erlaeuterung: json['erlaeuterung'] as String?,
);

Map<String, dynamic> _$TeilhabezielToJson(Teilhabeziel instance) =>
    <String, dynamic>{
      'leitzielNr': instance.leitzielNr,
      'leitzielText': instance.leitzielText,
      'teilhabezielNr': instance.teilhabezielNr,
      'teilhabezielText': instance.teilhabezielText,
      'indikator': instance.indikator,
      'zielerreichung': _$ZielerreichungStatusEnumMap[instance.zielerreichung],
      'abweichendeEinschaetzung': instance.abweichendeEinschaetzung,
      'erlaeuterung': instance.erlaeuterung,
    };

const _$ZielerreichungStatusEnumMap = {
  ZielerreichungStatus.vollErreicht: 'voll_erreicht',
  ZielerreichungStatus.teilweiseErreicht: 'teilweise_erreicht',
  ZielerreichungStatus.nichtErreicht: 'nicht_erreicht',
  ZielerreichungStatus.nichtBeurteilbar: 'nicht_beurteilbar',
};
