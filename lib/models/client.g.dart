// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'client.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Client _$ClientFromJson(Map<String, dynamic> json) => Client(
  id: json['id'] as String,
  klientenId: json['klientenId'] as String?,
  name: json['name'] as String,
  berufsgruppe: json['berufsgruppe'] as String?,
  eingliederung: json['eingliederung'] as String?,
  createdAt: DateTime.parse(json['createdAt'] as String),
  vorname: json['vorname'] as String?,
  nachname: json['nachname'] as String?,
  geburtsdatum: json['geburtsdatum'] == null
      ? null
      : DateTime.parse(json['geburtsdatum'] as String),
  betreuungSeit: json['betreuungSeit'] == null
      ? null
      : DateTime.parse(json['betreuungSeit'] as String),
  kostenuebernahme: json['kostenuebernahme'] as String?,
  kostenuebernahmeVon: json['kostenuebernahmeVon'] == null
      ? null
      : DateTime.parse(json['kostenuebernahmeVon'] as String),
  kostenuebernahmeBis: json['kostenuebernahmeBis'] == null
      ? null
      : DateTime.parse(json['kostenuebernahmeBis'] as String),
  fachleistungsstunden: (json['fachleistungsstunden'] as num?)?.toInt(),
  fachleistungsIntervall: $enumDecodeNullable(
    _$FachleistungsIntervallEnumMap,
    json['fachleistungsIntervall'],
  ),
  hilfeTyp: $enumDecodeNullable(_$HilfeTypEnumMap, json['hilfeTyp']),
  icfBereiche: (json['icfBereiche'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  verbrauchteStunden: (json['verbrauchteStunden'] as num?)?.toDouble() ?? 0.0,
  kalkulationsfaktorOverride: (json['kalkulationsfaktorOverride'] as num?)
      ?.toDouble(),
  stundensatzOverride: (json['stundensatzOverride'] as num?)?.toDouble(),
  vertreter1Id: json['vertreter1Id'] as String?,
  vertreter2Id: json['vertreter2Id'] as String?,
  tibZiele: (json['tibZiele'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  individuelleTibZiele: (json['individuelleTibZiele'] as List<dynamic>?)
      ?.map((e) => e as String)
      .toList(),
  rechtsgrundlage: json['rechtsgrundlage'] as String?,
  customColor: json['customColor'] as String?,
  einwilligungVorhanden: json['einwilligungVorhanden'] as bool? ?? false,
  einwilligungDatum: json['einwilligungDatum'] == null
      ? null
      : DateTime.parse(json['einwilligungDatum'] as String),
  einwilligungUnterschriftVon: json['einwilligungUnterschriftVon'] as String?,
  einwilligungWiderruflichBis: json['einwilligungWiderruflichBis'] as String?,
  einwilligungBemerkung: json['einwilligungBemerkung'] as String?,
  bundeslandOverride: $enumDecodeNullable(
    _$BundeslandEnumMap,
    json['bundeslandOverride'],
  ),
  kostentraegerFallnummern:
      (json['kostentraegerFallnummern'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
  bewilligungsbescheidRef: json['bewilligungsbescheidRef'] as String?,
  leistungstypSchluessel: json['leistungstypSchluessel'] as String?,
);

Map<String, dynamic> _$ClientToJson(Client instance) => <String, dynamic>{
  'id': instance.id,
  'klientenId': instance.klientenId,
  'name': instance.name,
  'berufsgruppe': instance.berufsgruppe,
  'eingliederung': instance.eingliederung,
  'createdAt': instance.createdAt.toIso8601String(),
  'vorname': instance.vorname,
  'nachname': instance.nachname,
  'geburtsdatum': instance.geburtsdatum?.toIso8601String(),
  'betreuungSeit': instance.betreuungSeit?.toIso8601String(),
  'kostenuebernahme': instance.kostenuebernahme,
  'kostenuebernahmeVon': instance.kostenuebernahmeVon?.toIso8601String(),
  'kostenuebernahmeBis': instance.kostenuebernahmeBis?.toIso8601String(),
  'fachleistungsstunden': instance.fachleistungsstunden,
  'fachleistungsIntervall':
      _$FachleistungsIntervallEnumMap[instance.fachleistungsIntervall],
  'hilfeTyp': _$HilfeTypEnumMap[instance.hilfeTyp],
  'icfBereiche': instance.icfBereiche,
  'verbrauchteStunden': instance.verbrauchteStunden,
  'kalkulationsfaktorOverride': instance.kalkulationsfaktorOverride,
  'stundensatzOverride': instance.stundensatzOverride,
  'vertreter1Id': instance.vertreter1Id,
  'vertreter2Id': instance.vertreter2Id,
  'tibZiele': instance.tibZiele,
  'individuelleTibZiele': instance.individuelleTibZiele,
  'rechtsgrundlage': instance.rechtsgrundlage,
  'customColor': instance.customColor,
  'einwilligungVorhanden': instance.einwilligungVorhanden,
  'einwilligungDatum': instance.einwilligungDatum?.toIso8601String(),
  'einwilligungUnterschriftVon': instance.einwilligungUnterschriftVon,
  'einwilligungWiderruflichBis': instance.einwilligungWiderruflichBis,
  'einwilligungBemerkung': instance.einwilligungBemerkung,
  'bundeslandOverride': _$BundeslandEnumMap[instance.bundeslandOverride],
  'kostentraegerFallnummern': instance.kostentraegerFallnummern,
  'bewilligungsbescheidRef': instance.bewilligungsbescheidRef,
  'leistungstypSchluessel': instance.leistungstypSchluessel,
};

const _$FachleistungsIntervallEnumMap = {
  FachleistungsIntervall.woechentlich: 'woechentlich',
  FachleistungsIntervall.monatlich: 'monatlich',
  FachleistungsIntervall.jaehrlich: 'jaehrlich',
};

const _$HilfeTypEnumMap = {
  HilfeTyp.familienhilfe: 'familienhilfe',
  HilfeTyp.eingliederungshilfe: 'eingliederungshilfe',
};

const _$BundeslandEnumMap = {
  Bundesland.badenWuerttemberg: 'baden-wuerttemberg',
  Bundesland.bayern: 'bayern',
  Bundesland.berlin: 'berlin',
  Bundesland.brandenburg: 'brandenburg',
  Bundesland.bremen: 'bremen',
  Bundesland.hamburg: 'hamburg',
  Bundesland.hessen: 'hessen',
  Bundesland.mecklenburgVorpommern: 'mecklenburg-vorpommern',
  Bundesland.niedersachsen: 'niedersachsen',
  Bundesland.nordrheinWestfalen: 'nordrhein-westfalen',
  Bundesland.rheinlandPfalz: 'rheinland-pfalz',
  Bundesland.saarland: 'saarland',
  Bundesland.sachsen: 'sachsen',
  Bundesland.sachsenAnhalt: 'sachsen-anhalt',
  Bundesland.schleswigHolstein: 'schleswig-holstein',
  Bundesland.thueringen: 'thueringen',
};
