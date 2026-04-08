import 'package:json_annotation/json_annotation.dart';

part 'informationsbericht.g.dart';

@JsonSerializable()
class Informationsbericht {
  final String id;
  final String clientId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool istEntwurf;

  // Kopfdaten
  final String? teilhabefachdienst;
  final String? idKostenuebernahme;
  final DateTime? berichtszeitraumVon;
  final DateTime? berichtszeitraumBis;
  final String? leistungstyp;
  final String? leistungserbringer;
  final String? emailTelNr;
  final String? strasse;
  final String? hausnummer;
  final String? weitererAdresshinweis;
  final String? postleitzahl;
  final String? ort;

  // 1. Angaben zur leistungsberechtigten Person
  final String? anrede;
  final String? titel;
  final String? familienname;
  final String? vorname;
  final String? geburtsname;
  final DateTime? geburtsdatum;
  final String? geburtsort;
  final String? geschlecht;
  final String? familienstand;
  final String? telefonFestnetz;
  final String? telefonMobil;
  final String? email;

  // 2. Allgemeine Informationen
  final String? allgemeineInformationen;

  // 3. Teilhabeziele (Liste von Zielen)
  final List<Teilhabeziel>? teilhabeziele;

  // 4. Zusammenfassung/Ausblick
  final String? weitereAnmerkungen;
  final bool? nachtAssistenz;
  final String? zusammenfassung;

  // 5. Unterschriften
  final String? ortDatum;
  final String? leistungserbringerUnterschrift;

  // 6. Eintragungen der leistungsberechtigten Person
  final String? eintragungKlient;

  Informationsbericht({
    required this.id,
    required this.clientId,
    required this.createdAt,
    required this.updatedAt,
    this.istEntwurf = true,
    this.teilhabefachdienst,
    this.idKostenuebernahme,
    this.berichtszeitraumVon,
    this.berichtszeitraumBis,
    this.leistungstyp,
    this.leistungserbringer,
    this.emailTelNr,
    this.strasse,
    this.hausnummer,
    this.weitererAdresshinweis,
    this.postleitzahl,
    this.ort,
    this.anrede,
    this.titel,
    this.familienname,
    this.vorname,
    this.geburtsname,
    this.geburtsdatum,
    this.geburtsort,
    this.geschlecht,
    this.familienstand,
    this.telefonFestnetz,
    this.telefonMobil,
    this.email,
    this.allgemeineInformationen,
    this.teilhabeziele,
    this.weitereAnmerkungen,
    this.nachtAssistenz,
    this.zusammenfassung,
    this.ortDatum,
    this.leistungserbringerUnterschrift,
    this.eintragungKlient,
  });

  factory Informationsbericht.create({
    required String clientId,
  }) {
    final now = DateTime.now();
    return Informationsbericht(
      id: now.millisecondsSinceEpoch.toString(),
      clientId: clientId,
      createdAt: now,
      updatedAt: now,
      istEntwurf: true,
    );
  }

  factory Informationsbericht.fromJson(Map<String, dynamic> json) =>
      _$InformationsberichtFromJson(json);
  Map<String, dynamic> toJson() => _$InformationsberichtToJson(this);

  Informationsbericht copyWith({
    bool? istEntwurf,
    String? teilhabefachdienst,
    String? idKostenuebernahme,
    DateTime? berichtszeitraumVon,
    DateTime? berichtszeitraumBis,
    String? leistungstyp,
    String? leistungserbringer,
    String? emailTelNr,
    String? strasse,
    String? hausnummer,
    String? weitererAdresshinweis,
    String? postleitzahl,
    String? ort,
    String? anrede,
    String? titel,
    String? familienname,
    String? vorname,
    String? geburtsname,
    DateTime? geburtsdatum,
    String? geburtsort,
    String? geschlecht,
    String? familienstand,
    String? telefonFestnetz,
    String? telefonMobil,
    String? email,
    String? allgemeineInformationen,
    List<Teilhabeziel>? teilhabeziele,
    String? weitereAnmerkungen,
    bool? nachtAssistenz,
    String? zusammenfassung,
    String? ortDatum,
    String? leistungserbringerUnterschrift,
    String? eintragungKlient,
  }) {
    return Informationsbericht(
      id: id,
      clientId: clientId,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      istEntwurf: istEntwurf ?? this.istEntwurf,
      teilhabefachdienst: teilhabefachdienst ?? this.teilhabefachdienst,
      idKostenuebernahme: idKostenuebernahme ?? this.idKostenuebernahme,
      berichtszeitraumVon: berichtszeitraumVon ?? this.berichtszeitraumVon,
      berichtszeitraumBis: berichtszeitraumBis ?? this.berichtszeitraumBis,
      leistungstyp: leistungstyp ?? this.leistungstyp,
      leistungserbringer: leistungserbringer ?? this.leistungserbringer,
      emailTelNr: emailTelNr ?? this.emailTelNr,
      strasse: strasse ?? this.strasse,
      hausnummer: hausnummer ?? this.hausnummer,
      weitererAdresshinweis: weitererAdresshinweis ?? this.weitererAdresshinweis,
      postleitzahl: postleitzahl ?? this.postleitzahl,
      ort: ort ?? this.ort,
      anrede: anrede ?? this.anrede,
      titel: titel ?? this.titel,
      familienname: familienname ?? this.familienname,
      vorname: vorname ?? this.vorname,
      geburtsname: geburtsname ?? this.geburtsname,
      geburtsdatum: geburtsdatum ?? this.geburtsdatum,
      geburtsort: geburtsort ?? this.geburtsort,
      geschlecht: geschlecht ?? this.geschlecht,
      familienstand: familienstand ?? this.familienstand,
      telefonFestnetz: telefonFestnetz ?? this.telefonFestnetz,
      telefonMobil: telefonMobil ?? this.telefonMobil,
      email: email ?? this.email,
      allgemeineInformationen: allgemeineInformationen ?? this.allgemeineInformationen,
      teilhabeziele: teilhabeziele ?? this.teilhabeziele,
      weitereAnmerkungen: weitereAnmerkungen ?? this.weitereAnmerkungen,
      nachtAssistenz: nachtAssistenz ?? this.nachtAssistenz,
      zusammenfassung: zusammenfassung ?? this.zusammenfassung,
      ortDatum: ortDatum ?? this.ortDatum,
      leistungserbringerUnterschrift: leistungserbringerUnterschrift ?? this.leistungserbringerUnterschrift,
      eintragungKlient: eintragungKlient ?? this.eintragungKlient,
    );
  }
}

@JsonSerializable()
class Teilhabeziel {
  final int? leitzielNr;
  final String? leitzielText;
  final int? teilhabezielNr;
  final String? teilhabezielText;
  final String? indikator;
  final ZielerreichungStatus? zielerreichung;
  final bool? abweichendeEinschaetzung;
  final String? erlaeuterung;

  Teilhabeziel({
    this.leitzielNr,
    this.leitzielText,
    this.teilhabezielNr,
    this.teilhabezielText,
    this.indikator,
    this.zielerreichung,
    this.abweichendeEinschaetzung,
    this.erlaeuterung,
  });

  factory Teilhabeziel.fromJson(Map<String, dynamic> json) =>
      _$TeilhabezielFromJson(json);
  Map<String, dynamic> toJson() => _$TeilhabezielToJson(this);
}

enum ZielerreichungStatus {
  @JsonValue('voll_erreicht')
  vollErreicht,
  @JsonValue('teilweise_erreicht')
  teilweiseErreicht,
  @JsonValue('nicht_erreicht')
  nichtErreicht,
  @JsonValue('nicht_beurteilbar')
  nichtBeurteilbar,
}
