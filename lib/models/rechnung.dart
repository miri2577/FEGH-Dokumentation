import 'package:json_annotation/json_annotation.dart';

part 'rechnung.g.dart';

/// Eine einzelne Leistungsposition (z.B. 1 Fachleistungsstunde).
@JsonSerializable()
class RechnungsPosition {
  final String id;
  final String bezeichnung;     // "Fachleistungsstunde Eingliederungshilfe"
  final double menge;           // z.B. 12.5
  final String einheit;         // "Stunde", "Stueck"
  final double einzelpreis;     // in EUR
  final double steuerprozent;   // meist 0 (Behoerdenleistung, §4 Nr. 25 UStG) oder 19
  final String? leistungszeitraumVon; // ISO-Datum, fuer rechnungszeile
  final String? leistungszeitraumBis;
  final String? clientId;       // Bezug zum Klienten (intern)
  final String? clientName;     // Anzeigename fuer Rechnung
  final String? hinweis;        // optionale Zusatzinfo

  RechnungsPosition({
    required this.id,
    required this.bezeichnung,
    required this.menge,
    required this.einheit,
    required this.einzelpreis,
    this.steuerprozent = 0.0,
    this.leistungszeitraumVon,
    this.leistungszeitraumBis,
    this.clientId,
    this.clientName,
    this.hinweis,
  });

  RechnungsPosition.create({
    required this.bezeichnung,
    required this.menge,
    required this.einheit,
    required this.einzelpreis,
    this.steuerprozent = 0.0,
    this.leistungszeitraumVon,
    this.leistungszeitraumBis,
    this.clientId,
    this.clientName,
    this.hinweis,
  }) : id = DateTime.now().microsecondsSinceEpoch.toString();

  factory RechnungsPosition.fromJson(Map<String, dynamic> json) =>
      _$RechnungsPositionFromJson(json);
  Map<String, dynamic> toJson() => _$RechnungsPositionToJson(this);

  double get nettoBetrag => menge * einzelpreis;
  double get steuerBetrag => nettoBetrag * steuerprozent / 100.0;
  double get bruttoBetrag => nettoBetrag + steuerBetrag;
}

/// Eine Rechnung mit Leitweg-ID fuer XRechnung-Konformitaet.
@JsonSerializable()
class Rechnung {
  final String id;
  final String rechnungsnummer;       // eigene Nummer
  final DateTime rechnungsdatum;
  final DateTime? leistungsVon;       // Zeitraum gesamt (min aus Positionen)
  final DateTime? leistungsBis;       // Zeitraum gesamt (max aus Positionen)
  final String empfaengerId;          // verweist auf RechnungEmpfaenger
  final List<RechnungsPosition> positionen;
  final double skontoProzent;         // 0 = kein Skonto
  final int zahlungszielTage;         // 30 Standard
  final String? bestellnummer;        // BT-13 Buyer Reference
  final String? vertragsnummer;       // BT-12 Contract Reference
  final String? projektnummer;        // BT-11 Project Reference
  final String? bemerkung;
  final String waehrung;              // "EUR"
  final RechnungStatus status;
  final DateTime erstelltAm;

  Rechnung({
    required this.id,
    required this.rechnungsnummer,
    required this.rechnungsdatum,
    this.leistungsVon,
    this.leistungsBis,
    required this.empfaengerId,
    required this.positionen,
    this.skontoProzent = 0.0,
    this.zahlungszielTage = 30,
    this.bestellnummer,
    this.vertragsnummer,
    this.projektnummer,
    this.bemerkung,
    this.waehrung = 'EUR',
    this.status = RechnungStatus.entwurf,
    required this.erstelltAm,
  });

  Rechnung.create({
    required this.rechnungsnummer,
    required this.rechnungsdatum,
    this.leistungsVon,
    this.leistungsBis,
    required this.empfaengerId,
    required this.positionen,
    this.skontoProzent = 0.0,
    this.zahlungszielTage = 30,
    this.bestellnummer,
    this.vertragsnummer,
    this.projektnummer,
    this.bemerkung,
    this.waehrung = 'EUR',
    this.status = RechnungStatus.entwurf,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        erstelltAm = DateTime.now();

  factory Rechnung.fromJson(Map<String, dynamic> json) => _$RechnungFromJson(json);
  Map<String, dynamic> toJson() => _$RechnungToJson(this);

  Rechnung copyWith({
    String? rechnungsnummer,
    DateTime? rechnungsdatum,
    DateTime? leistungsVon,
    DateTime? leistungsBis,
    String? empfaengerId,
    List<RechnungsPosition>? positionen,
    double? skontoProzent,
    int? zahlungszielTage,
    String? bestellnummer,
    String? vertragsnummer,
    String? projektnummer,
    String? bemerkung,
    String? waehrung,
    RechnungStatus? status,
  }) {
    return Rechnung(
      id: id,
      rechnungsnummer: rechnungsnummer ?? this.rechnungsnummer,
      rechnungsdatum: rechnungsdatum ?? this.rechnungsdatum,
      leistungsVon: leistungsVon ?? this.leistungsVon,
      leistungsBis: leistungsBis ?? this.leistungsBis,
      empfaengerId: empfaengerId ?? this.empfaengerId,
      positionen: positionen ?? this.positionen,
      skontoProzent: skontoProzent ?? this.skontoProzent,
      zahlungszielTage: zahlungszielTage ?? this.zahlungszielTage,
      bestellnummer: bestellnummer ?? this.bestellnummer,
      vertragsnummer: vertragsnummer ?? this.vertragsnummer,
      projektnummer: projektnummer ?? this.projektnummer,
      bemerkung: bemerkung ?? this.bemerkung,
      waehrung: waehrung ?? this.waehrung,
      status: status ?? this.status,
      erstelltAm: erstelltAm,
    );
  }

  double get gesamtNetto => positionen.fold(0.0, (s, p) => s + p.nettoBetrag);
  double get gesamtSteuer => positionen.fold(0.0, (s, p) => s + p.steuerBetrag);
  double get gesamtBrutto => positionen.fold(0.0, (s, p) => s + p.bruttoBetrag);

  DateTime get faelligkeit => rechnungsdatum.add(Duration(days: zahlungszielTage));
}

enum RechnungStatus {
  @JsonValue('entwurf')
  entwurf,
  @JsonValue('versendet')
  versendet,
  @JsonValue('bezahlt')
  bezahlt,
  @JsonValue('storniert')
  storniert,
}
