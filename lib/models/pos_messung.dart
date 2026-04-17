import 'package:json_annotation/json_annotation.dart';

part 'pos_messung.g.dart';

/// Personal Outcomes Scale (POS) - 8 Domaenen der Lebensqualitaet.
/// Entwickelt von Schalock & Verdugo, adaptiert fuer Deutschland.
/// Jede Domaene hat 6 Items, bewertet mit 1-3 Punkten.
/// Max. pro Domaene: 18, Gesamt max: 144.
enum PosDomaene {
  @JsonValue('selbstbestimmung')
  selbstbestimmung,          // Self-Determination
  @JsonValue('sozialeTeilhabe')
  sozialeTeilhabe,           // Social Inclusion
  @JsonValue('interpersonelleBeziehungen')
  interpersonelleBeziehungen, // Interpersonal Relations
  @JsonValue('rechte')
  rechte,                    // Rights
  @JsonValue('emotionalesWohlbefinden')
  emotionalesWohlbefinden,   // Emotional Wellbeing
  @JsonValue('physischesWohlbefinden')
  physischesWohlbefinden,    // Physical Wellbeing
  @JsonValue('materiellesWohlbefinden')
  materiellesWohlbefinden,   // Material Wellbeing
  @JsonValue('persoenlicheEntwicklung')
  persoenlicheEntwicklung,   // Personal Development
}

extension PosDomaeneExtension on PosDomaene {
  String get displayName {
    switch (this) {
      case PosDomaene.selbstbestimmung: return 'Selbstbestimmung';
      case PosDomaene.sozialeTeilhabe: return 'Soziale Teilhabe';
      case PosDomaene.interpersonelleBeziehungen: return 'Interpersonelle Beziehungen';
      case PosDomaene.rechte: return 'Rechte';
      case PosDomaene.emotionalesWohlbefinden: return 'Emotionales Wohlbefinden';
      case PosDomaene.physischesWohlbefinden: return 'Physisches Wohlbefinden';
      case PosDomaene.materiellesWohlbefinden: return 'Materielles Wohlbefinden';
      case PosDomaene.persoenlicheEntwicklung: return 'Persoenliche Entwicklung';
    }
  }

  /// Die 6 Items pro Domaene als Leitfragen.
  List<String> get items {
    switch (this) {
      case PosDomaene.selbstbestimmung:
        return [
          'Treffe ich eigene Entscheidungen?',
          'Kann ich meinen Tagesablauf selbst gestalten?',
          'Kann ich meine Ziele selbst setzen?',
          'Habe ich Wahlmoeglichkeiten?',
          'Kann ich fuer mich selbst sprechen?',
          'Lebe ich so wie ich moechte?',
        ];
      case PosDomaene.sozialeTeilhabe:
        return [
          'Nehme ich an Aktivitaeten in der Gemeinde teil?',
          'Habe ich eine Rolle in der Gesellschaft?',
          'Nutze ich oeffentliche Einrichtungen (Bus, Geschaefte, etc.)?',
          'Fuehle ich mich zugehoerig?',
          'Habe ich Kontakt zu Menschen ohne Behinderung?',
          'Kann ich ueberall hingehen wo ich moechte?',
        ];
      case PosDomaene.interpersonelleBeziehungen:
        return [
          'Habe ich Freundinnen und Freunde?',
          'Habe ich Kontakt zu meiner Familie?',
          'Habe ich eine enge Vertrauensperson?',
          'Habe ich romantische/sexuelle Beziehungen wie ich moechte?',
          'Werde ich von Anderen respektiert?',
          'Fuehle ich mich von Anderen unterstuetzt?',
        ];
      case PosDomaene.rechte:
        return [
          'Werden meine Rechte respektiert?',
          'Werde ich fair behandelt?',
          'Kenne ich meine Rechte?',
          'Habe ich Zugang zu Informationen?',
          'Werden meine Daten geschuetzt (Datenschutz)?',
          'Kann ich rechtliche Hilfe bekommen wenn noetig?',
        ];
      case PosDomaene.emotionalesWohlbefinden:
        return [
          'Bin ich zufrieden mit meinem Leben?',
          'Fuehle ich mich sicher?',
          'Habe ich ein positives Selbstbild?',
          'Bin ich frei von Stress/Angst?',
          'Habe ich Freude am Leben?',
          'Bin ich glueklich?',
        ];
      case PosDomaene.physischesWohlbefinden:
        return [
          'Bin ich koerperlich gesund?',
          'Habe ich ausreichend Energie?',
          'Bin ich mobil und beweglich?',
          'Ernaehre ich mich gut?',
          'Bewege ich mich ausreichend?',
          'Schlafe ich gut?',
        ];
      case PosDomaene.materiellesWohlbefinden:
        return [
          'Habe ich ausreichend Geld zum Leben?',
          'Lebe ich in einer guten Wohnung?',
          'Habe ich eine sinnvolle Beschaeftigung/Arbeit?',
          'Besitze ich persoenliche Dinge die mir wichtig sind?',
          'Kann ich mir Dinge leisten die ich moechte?',
          'Ist mein Wohnumfeld sicher und angenehm?',
        ];
      case PosDomaene.persoenlicheEntwicklung:
        return [
          'Lerne ich neue Dinge?',
          'Entwickle ich mich weiter?',
          'Kann ich meine Faehigkeiten nutzen?',
          'Habe ich Bildungsmoeglichkeiten?',
          'Setze ich neue Ziele fuer mich?',
          'Habe ich Hobbys und Interessen?',
        ];
    }
  }
}

/// POS-Messung - komplette Erfassung aller 48 Items.
@JsonSerializable()
class PosMessung {
  final String id;
  final String clientId;
  final DateTime messdatum;
  final String bewertetVon;
  final DateTime erstelltAm;
  final String? kommentar;

  // Bewertungen: Map<domaene-index, List<int>> mit 6 Items pro Domaene
  // Jedes Item: 1 (trifft nicht zu) bis 3 (trifft voll zu)
  // Speichert alle 48 Bewertungen (8 Domaenen * 6 Items)
  final Map<String, List<int>> bewertungen;

  PosMessung({
    required this.id,
    required this.clientId,
    required this.messdatum,
    required this.bewertetVon,
    required this.erstelltAm,
    required this.bewertungen,
    this.kommentar,
  });

  PosMessung.create({
    required this.clientId,
    required this.messdatum,
    required this.bewertetVon,
    required this.bewertungen,
    this.kommentar,
  })  : id = DateTime.now().microsecondsSinceEpoch.toString(),
        erstelltAm = DateTime.now();

  factory PosMessung.fromJson(Map<String, dynamic> json) => _$PosMessungFromJson(json);
  Map<String, dynamic> toJson() => _$PosMessungToJson(this);

  /// Punktzahl pro Domaene (max 18 = 6 Items * 3 Punkte).
  int domaenePunkte(PosDomaene domaene) {
    final items = bewertungen[domaene.name] ?? [];
    return items.fold<int>(0, (sum, v) => sum + v);
  }

  /// Prozentsatz pro Domaene (0-100%).
  double domaeneProzent(PosDomaene domaene) {
    final punkte = domaenePunkte(domaene);
    return (punkte / 18.0) * 100;
  }

  /// Gesamtpunktzahl (max 144).
  int get gesamtPunkte {
    return PosDomaene.values.fold<int>(0, (sum, d) => sum + domaenePunkte(d));
  }

  /// Gesamtprozent (0-100%).
  double get gesamtProzent {
    return (gesamtPunkte / 144.0) * 100;
  }

  PosMessung copyWith({
    DateTime? messdatum,
    Map<String, List<int>>? bewertungen,
    String? kommentar,
  }) {
    return PosMessung(
      id: id,
      clientId: clientId,
      messdatum: messdatum ?? this.messdatum,
      bewertetVon: bewertetVon,
      erstelltAm: erstelltAm,
      bewertungen: bewertungen ?? this.bewertungen,
      kommentar: kommentar ?? this.kommentar,
    );
  }

  /// Leere POS-Messung (alle Items auf 0/unbewertet).
  static Map<String, List<int>> leereBewertungen() {
    return {
      for (final d in PosDomaene.values) d.name: List.filled(6, 0),
    };
  }
}
