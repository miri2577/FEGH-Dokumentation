import 'package:json_annotation/json_annotation.dart';

part 'teilhabeziel.g.dart';

enum TeilhabezielStatus {
  @JsonValue('aktiv')
  aktiv,
  @JsonValue('erreicht')
  erreicht,
  @JsonValue('pausiert')
  pausiert,
  @JsonValue('abgebrochen')
  abgebrochen,
}

enum TeilhabezielKategorie {
  @JsonValue('leitziel')
  leitziel,
  @JsonValue('teilziel')
  teilziel,
  @JsonValue('handlungsziel')
  handlungsziel,
}

/// Teilhabeziel nach ICF/TIB - strukturiert erfasst mit SMART-Kriterien.
/// Wird fuer Wirksamkeitsnachweis nach §128 SGB IX genutzt.
@JsonSerializable()
class Teilhabeziel {
  final String id;
  final String clientId;
  final String titel;
  final String beschreibung;

  // SMART-Kriterien
  final String? spezifisch;    // S - was genau?
  final String? messbar;       // M - woran erkennbar?
  final String? attraktiv;     // A - warum wichtig fuer Klient?
  final String? realistisch;   // R - was ist moeglich?
  final DateTime? terminiert;  // T - bis wann?

  // ICF-Verknuepfung
  final String? icfBereich;    // z.B. "d170 Schreiben"
  final String? icfKategorie;  // z.B. "Aktivitaeten und Teilhabe"

  // Status & Klassifikation
  final TeilhabezielKategorie kategorie;
  final TeilhabezielStatus status;
  final int prioritaet;        // 1 (niedrig) bis 5 (hoch)

  // Zeitstempel
  final DateTime erstelltAm;
  final DateTime? geaendertAm;
  final DateTime? erreichtAm;

  // Zielhierarchie
  final String? parentZielId;  // Fuer Teilziele

  // Ersteller
  final String? erstelltVon;

  Teilhabeziel({
    required this.id,
    required this.clientId,
    required this.titel,
    this.beschreibung = '',
    this.spezifisch,
    this.messbar,
    this.attraktiv,
    this.realistisch,
    this.terminiert,
    this.icfBereich,
    this.icfKategorie,
    this.kategorie = TeilhabezielKategorie.teilziel,
    this.status = TeilhabezielStatus.aktiv,
    this.prioritaet = 3,
    required this.erstelltAm,
    this.geaendertAm,
    this.erreichtAm,
    this.parentZielId,
    this.erstelltVon,
  });

  Teilhabeziel.create({
    required this.clientId,
    required this.titel,
    this.beschreibung = '',
    this.spezifisch,
    this.messbar,
    this.attraktiv,
    this.realistisch,
    this.terminiert,
    this.icfBereich,
    this.icfKategorie,
    this.kategorie = TeilhabezielKategorie.teilziel,
    this.status = TeilhabezielStatus.aktiv,
    this.prioritaet = 3,
    this.parentZielId,
    this.erstelltVon,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        erstelltAm = DateTime.now(),
        geaendertAm = null,
        erreichtAm = null;

  factory Teilhabeziel.fromJson(Map<String, dynamic> json) => _$TeilhabezielFromJson(json);
  Map<String, dynamic> toJson() => _$TeilhabezielToJson(this);

  Teilhabeziel copyWith({
    String? titel,
    String? beschreibung,
    String? spezifisch,
    String? messbar,
    String? attraktiv,
    String? realistisch,
    DateTime? terminiert,
    String? icfBereich,
    String? icfKategorie,
    TeilhabezielKategorie? kategorie,
    TeilhabezielStatus? status,
    int? prioritaet,
    DateTime? geaendertAm,
    DateTime? erreichtAm,
    String? parentZielId,
  }) {
    return Teilhabeziel(
      id: id,
      clientId: clientId,
      titel: titel ?? this.titel,
      beschreibung: beschreibung ?? this.beschreibung,
      spezifisch: spezifisch ?? this.spezifisch,
      messbar: messbar ?? this.messbar,
      attraktiv: attraktiv ?? this.attraktiv,
      realistisch: realistisch ?? this.realistisch,
      terminiert: terminiert ?? this.terminiert,
      icfBereich: icfBereich ?? this.icfBereich,
      icfKategorie: icfKategorie ?? this.icfKategorie,
      kategorie: kategorie ?? this.kategorie,
      status: status ?? this.status,
      prioritaet: prioritaet ?? this.prioritaet,
      erstelltAm: erstelltAm,
      geaendertAm: geaendertAm ?? DateTime.now(),
      erreichtAm: erreichtAm ?? this.erreichtAm,
      parentZielId: parentZielId ?? this.parentZielId,
      erstelltVon: erstelltVon,
    );
  }

  /// Ist das Ziel in der Vergangenheit (Termin ueberschritten)?
  bool get istUeberfaellig {
    if (terminiert == null) return false;
    if (status == TeilhabezielStatus.erreicht) return false;
    return DateTime.now().isAfter(terminiert!);
  }

  /// Anzeige-Name der Kategorie
  String get kategorieDisplayName {
    switch (kategorie) {
      case TeilhabezielKategorie.leitziel: return 'Leitziel';
      case TeilhabezielKategorie.teilziel: return 'Teilhabeziel';
      case TeilhabezielKategorie.handlungsziel: return 'Handlungsziel';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case TeilhabezielStatus.aktiv: return 'Aktiv';
      case TeilhabezielStatus.erreicht: return 'Erreicht';
      case TeilhabezielStatus.pausiert: return 'Pausiert';
      case TeilhabezielStatus.abgebrochen: return 'Abgebrochen';
    }
  }
}
