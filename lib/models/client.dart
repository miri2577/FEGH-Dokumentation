import 'package:json_annotation/json_annotation.dart';
import 'bundesland.dart';

part 'client.g.dart';

enum FachleistungsIntervall {
  @JsonValue('woechentlich')
  woechentlich,
  @JsonValue('monatlich')
  monatlich,
  @JsonValue('jaehrlich')
  jaehrlich
}

extension FachleistungsIntervallExtension on FachleistungsIntervall {
  String get displayName {
    switch (this) {
      case FachleistungsIntervall.woechentlich: return 'pro Woche';
      case FachleistungsIntervall.monatlich: return 'pro Monat';
      case FachleistungsIntervall.jaehrlich: return 'pro Jahr';
    }
  }

  /// Start des aktuellen Abrechnungszeitraums (basierend auf [bezugsDatum]).
  /// Woechentlich = Montag 00:00, monatlich = 1. Tag des Monats, jaehrlich = 1.1.
  DateTime startDesAktuellenZeitraums(DateTime bezugsDatum) {
    switch (this) {
      case FachleistungsIntervall.woechentlich:
        final tag = DateTime(bezugsDatum.year, bezugsDatum.month, bezugsDatum.day);
        return tag.subtract(Duration(days: tag.weekday - 1));
      case FachleistungsIntervall.monatlich:
        return DateTime(bezugsDatum.year, bezugsDatum.month, 1);
      case FachleistungsIntervall.jaehrlich:
        return DateTime(bezugsDatum.year, 1, 1);
    }
  }

  /// Ende (exklusiv) des aktuellen Abrechnungszeitraums.
  DateTime endeDesAktuellenZeitraums(DateTime bezugsDatum) {
    final start = startDesAktuellenZeitraums(bezugsDatum);
    switch (this) {
      case FachleistungsIntervall.woechentlich:
        return start.add(const Duration(days: 7));
      case FachleistungsIntervall.monatlich:
        return DateTime(start.year, start.month + 1, 1);
      case FachleistungsIntervall.jaehrlich:
        return DateTime(start.year + 1, 1, 1);
    }
  }
}

enum HilfeTyp {
  @JsonValue('familienhilfe')
  familienhilfe,
  @JsonValue('eingliederungshilfe')
  eingliederungshilfe
}

@JsonSerializable()
class Client {
  final String id;
  final String? klientenId;
  final String name;
  final String? berufsgruppe;
  final String? eingliederung;
  final DateTime createdAt;
  
  // Neue Stammblatt-Felder
  final String? vorname;
  final String? nachname;
  final DateTime? geburtsdatum;
  final DateTime? betreuungSeit;
  final String? kostenuebernahme;
  final DateTime? kostenuebernahmeVon;
  final DateTime? kostenuebernahmeBis;
  final int? fachleistungsstunden;
  final FachleistungsIntervall? fachleistungsIntervall;
  final HilfeTyp? hilfeTyp;
  final List<String>? icfBereiche;
  final double verbrauchteStunden;
  final double? kalkulationsfaktorOverride;
  final double? stundensatzOverride;
  final String? vertreter1Id;
  final String? vertreter2Id;
  final List<String>? tibZiele;
  final List<String>? individuelleTibZiele;
  final String? rechtsgrundlage;

  // Benutzerdefinierte Kalenderfarbe (Hex-String, z.B. "FF1976D2")
  final String? customColor;

  // DSGVO Art. 9 - Einwilligung zur Verarbeitung von Sozial-/Gesundheitsdaten
  final bool einwilligungVorhanden;
  final DateTime? einwilligungDatum;
  final String? einwilligungUnterschriftVon; // Name des Klienten oder gesetzlichen Vertreters
  final String? einwilligungWiderruflichBis; // Datum oder leer
  final String? einwilligungBemerkung;

  // Bundesland-Override (optional): fuer Grenzfaelle, wenn Klient in
  // anderem Bundesland betreut wird als der Traeger sitzt.
  final Bundesland? bundeslandOverride;

  // Fallnummer/Aktenzeichen pro Kostentraeger - WICHTIG fuer Rechnung!
  // Ein Klient kann bei mehreren Kostentraegern gefuehrt werden und hat
  // dort jeweils eigene Aktenzeichen. Key = Empfaenger-ID, Value = Aktenzeichen.
  final Map<String, String>? kostentraegerFallnummern;

  // Bewilligungsbescheid-Referenz (Geschaeftszeichen/Bescheid-Nummer des
  // zustaendigen Kostentraegers) - auf Rechnung oft verlangt
  final String? bewilligungsbescheidRef;

  // Leistungstyp nach Landesrahmenvertrag (z.B. "B5.01 ABW Erwachsene")
  final String? leistungstypSchluessel;

  Client({
    required this.id,
    this.klientenId,
    required this.name,
    this.berufsgruppe,
    this.eingliederung,
    required this.createdAt,
    this.vorname,
    this.nachname,
    this.geburtsdatum,
    this.betreuungSeit,
    this.kostenuebernahme,
    this.kostenuebernahmeVon,
    this.kostenuebernahmeBis,
    this.fachleistungsstunden,
    this.fachleistungsIntervall,
    this.hilfeTyp,
    this.icfBereiche,
    this.verbrauchteStunden = 0.0,
    this.kalkulationsfaktorOverride,
    this.stundensatzOverride,
    this.vertreter1Id,
    this.vertreter2Id,
    this.tibZiele,
    this.individuelleTibZiele,
    this.rechtsgrundlage,
    this.customColor,
    this.einwilligungVorhanden = false,
    this.einwilligungDatum,
    this.einwilligungUnterschriftVon,
    this.einwilligungWiderruflichBis,
    this.einwilligungBemerkung,
    this.bundeslandOverride,
    this.kostentraegerFallnummern,
    this.bewilligungsbescheidRef,
    this.leistungstypSchluessel,
  });

  Client.create({
    this.klientenId,
    required this.name,
    this.berufsgruppe,
    this.eingliederung,
    this.vorname,
    this.nachname,
    this.geburtsdatum,
    this.betreuungSeit,
    this.kostenuebernahme,
    this.kostenuebernahmeVon,
    this.kostenuebernahmeBis,
    this.fachleistungsstunden,
    this.fachleistungsIntervall,
    this.hilfeTyp,
    this.icfBereiche,
    this.verbrauchteStunden = 0.0,
    this.kalkulationsfaktorOverride,
    this.stundensatzOverride,
    this.vertreter1Id,
    this.vertreter2Id,
    this.tibZiele,
    this.individuelleTibZiele,
    this.rechtsgrundlage,
    this.customColor,
    this.einwilligungVorhanden = false,
    this.einwilligungDatum,
    this.einwilligungUnterschriftVon,
    this.einwilligungWiderruflichBis,
    this.einwilligungBemerkung,
    this.bundeslandOverride,
    this.kostentraegerFallnummern,
    this.bewilligungsbescheidRef,
    this.leistungstypSchluessel,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = DateTime.now();

  /// Gibt das Aktenzeichen fuer einen bestimmten Kostentraeger zurueck.
  /// Faellt auf [klientenId] zurueck, wenn kein spezifisches Aktenzeichen hinterlegt ist.
  String? fallnummerFuer(String empfaengerId) =>
      kostentraegerFallnummern?[empfaengerId] ?? klientenId;

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);
  Map<String, dynamic> toJson() => _$ClientToJson(this);

  Client copyWith({
    String? klientenId,
    String? name,
    String? berufsgruppe,
    String? eingliederung,
    String? vorname,
    String? nachname,
    DateTime? geburtsdatum,
    DateTime? betreuungSeit,
    String? kostenuebernahme,
    DateTime? kostenuebernahmeVon,
    DateTime? kostenuebernahmeBis,
    int? fachleistungsstunden,
    FachleistungsIntervall? fachleistungsIntervall,
    HilfeTyp? hilfeTyp,
    List<String>? icfBereiche,
    double? verbrauchteStunden,
    double? kalkulationsfaktorOverride,
    double? stundensatzOverride,
    String? vertreter1Id,
    String? vertreter2Id,
    List<String>? tibZiele,
    List<String>? individuelleTibZiele,
    String? rechtsgrundlage,
    String? customColor,
    bool? einwilligungVorhanden,
    DateTime? einwilligungDatum,
    String? einwilligungUnterschriftVon,
    String? einwilligungWiderruflichBis,
    String? einwilligungBemerkung,
    Bundesland? bundeslandOverride,
    Map<String, String>? kostentraegerFallnummern,
    String? bewilligungsbescheidRef,
    String? leistungstypSchluessel,
  }) {
    return Client(
      id: id,
      klientenId: klientenId ?? this.klientenId,
      name: name ?? this.name,
      berufsgruppe: berufsgruppe ?? this.berufsgruppe,
      eingliederung: eingliederung ?? this.eingliederung,
      createdAt: createdAt,
      vorname: vorname ?? this.vorname,
      nachname: nachname ?? this.nachname,
      geburtsdatum: geburtsdatum ?? this.geburtsdatum,
      betreuungSeit: betreuungSeit ?? this.betreuungSeit,
      kostenuebernahme: kostenuebernahme ?? this.kostenuebernahme,
      kostenuebernahmeVon: kostenuebernahmeVon ?? this.kostenuebernahmeVon,
      kostenuebernahmeBis: kostenuebernahmeBis ?? this.kostenuebernahmeBis,
      fachleistungsstunden: fachleistungsstunden ?? this.fachleistungsstunden,
      fachleistungsIntervall: fachleistungsIntervall ?? this.fachleistungsIntervall,
      hilfeTyp: hilfeTyp ?? this.hilfeTyp,
      icfBereiche: icfBereiche ?? this.icfBereiche,
      verbrauchteStunden: verbrauchteStunden ?? this.verbrauchteStunden,
      kalkulationsfaktorOverride: kalkulationsfaktorOverride ?? this.kalkulationsfaktorOverride,
      stundensatzOverride: stundensatzOverride ?? this.stundensatzOverride,
      vertreter1Id: vertreter1Id ?? this.vertreter1Id,
      vertreter2Id: vertreter2Id ?? this.vertreter2Id,
      tibZiele: tibZiele ?? this.tibZiele,
      individuelleTibZiele: individuelleTibZiele ?? this.individuelleTibZiele,
      rechtsgrundlage: rechtsgrundlage ?? this.rechtsgrundlage,
      customColor: customColor ?? this.customColor,
      einwilligungVorhanden: einwilligungVorhanden ?? this.einwilligungVorhanden,
      einwilligungDatum: einwilligungDatum ?? this.einwilligungDatum,
      einwilligungUnterschriftVon: einwilligungUnterschriftVon ?? this.einwilligungUnterschriftVon,
      einwilligungWiderruflichBis: einwilligungWiderruflichBis ?? this.einwilligungWiderruflichBis,
      einwilligungBemerkung: einwilligungBemerkung ?? this.einwilligungBemerkung,
      bundeslandOverride: bundeslandOverride ?? this.bundeslandOverride,
      kostentraegerFallnummern: kostentraegerFallnummern ?? this.kostentraegerFallnummern,
      bewilligungsbescheidRef: bewilligungsbescheidRef ?? this.bewilligungsbescheidRef,
      leistungstypSchluessel: leistungstypSchluessel ?? this.leistungstypSchluessel,
    );
  }

  // Hilfsmethoden für Stundenverbrauch
  double get stundenverbrauchProzent {
    if (fachleistungsstunden == null || fachleistungsstunden == 0) return 0.0;
    return (verbrauchteStunden / fachleistungsstunden!) * 100;
  }
  
  double get verfuegbareStunden {
    if (fachleistungsstunden == null) return 0.0;
    return fachleistungsstunden!.toDouble() - verbrauchteStunden;
  }
  
  String get vollstaendigerName {
    if (vorname != null && nachname != null) {
      return '$vorname $nachname';
    }
    return name;
  }

  /// Gibt das effektive Bundesland fuer diesen Klienten zurueck:
  /// [bundeslandOverride] falls gesetzt, sonst [orgBundesland] (meist aus AppSettings).
  Bundesland effektivesBundesland(Bundesland orgBundesland) {
    return bundeslandOverride ?? orgBundesland;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Client &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          berufsgruppe == other.berufsgruppe &&
          eingliederung == other.eingliederung;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      (berufsgruppe?.hashCode ?? 0) ^
      (eingliederung?.hashCode ?? 0);
}