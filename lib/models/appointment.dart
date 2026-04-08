import 'package:json_annotation/json_annotation.dart';

part 'appointment.g.dart';

/// Art des Termins - unterscheidet direkten Klientenkontakt von indirekten Tätigkeiten
enum TerminArt {
  kliententermin,
  buero,
  dokumentation,
  supervision,
  teamsitzung,
  fortbildung,
  fahrtzeit,
  sonstige,
}

extension TerminArtExtension on TerminArt {
  String get displayName {
    switch (this) {
      case TerminArt.kliententermin:
        return 'Kliententermin';
      case TerminArt.buero:
        return 'Büroarbeit';
      case TerminArt.dokumentation:
        return 'Dokumentation';
      case TerminArt.supervision:
        return 'Supervision';
      case TerminArt.teamsitzung:
        return 'Teamsitzung';
      case TerminArt.fortbildung:
        return 'Fortbildung';
      case TerminArt.fahrtzeit:
        return 'Fahrtzeit';
      case TerminArt.sonstige:
        return 'Sonstige';
    }
  }

  bool get isIndirect => this != TerminArt.kliententermin;

  String get icon {
    switch (this) {
      case TerminArt.kliententermin:
        return 'person';
      case TerminArt.buero:
        return 'business';
      case TerminArt.dokumentation:
        return 'description';
      case TerminArt.supervision:
        return 'psychology';
      case TerminArt.teamsitzung:
        return 'groups';
      case TerminArt.fortbildung:
        return 'school';
      case TerminArt.fahrtzeit:
        return 'directions_car';
      case TerminArt.sonstige:
        return 'more_horiz';
    }
  }
}

/// Verteilung von Stunden eines indirekten Termins auf einen Klienten
@JsonSerializable()
class ClientAllocation {
  final String clientId;
  final String clientName;
  final int minuten;

  ClientAllocation({
    required this.clientId,
    required this.clientName,
    required this.minuten,
  });

  double get stunden => minuten / 60.0;

  factory ClientAllocation.fromJson(Map<String, dynamic> json) =>
      _$ClientAllocationFromJson(json);
  Map<String, dynamic> toJson() => _$ClientAllocationToJson(this);
}

@JsonSerializable()
class Appointment {
  final String id;
  final String clientId;
  final String clientName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String notes;
  final String recordedText;
  final String berufsgruppe;
  final String eingliederung;
  final DateTime createdAt;

  // Neue ICF und Fachleistungsstunden Felder
  final List<String> icfBereiche;
  final double fachleistungsstunden;

  // Familienhilfe-spezifische Dokumentationskategorien
  final List<String> familienhilfeKategorien;

  // TIB-Bereiche (Teilhabeinstrument Berlin)
  final List<String> tibBereiche;

  // Individuelle TIB-Ziele mit Zeiterfassung
  final List<String>? selectedTibZiele;
  final Map<String, int>? tibZielMinuten;

  // Fahrweg-Verknüpfung
  final String? fahrwegHinId;
  final String? fahrwegRueckId;

  // Indirekte Termine: Art und Klienten-Verteilung
  final TerminArt? terminArt;
  final List<ClientAllocation>? clientAllocations;

  Appointment({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.notes,
    required this.recordedText,
    required this.berufsgruppe,
    required this.eingliederung,
    required this.createdAt,
    this.icfBereiche = const [],
    this.fachleistungsstunden = 0.0,
    this.familienhilfeKategorien = const [],
    this.tibBereiche = const [],
    this.selectedTibZiele,
    this.tibZielMinuten,
    this.fahrwegHinId,
    this.fahrwegRueckId,
    this.terminArt,
    this.clientAllocations,
  });

  Appointment.create({
    required this.clientId,
    required this.clientName,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.notes,
    required this.recordedText,
    required this.berufsgruppe,
    required this.eingliederung,
    this.icfBereiche = const [],
    this.fachleistungsstunden = 0.0,
    this.familienhilfeKategorien = const [],
    this.tibBereiche = const [],
    this.selectedTibZiele,
    this.tibZielMinuten,
    this.fahrwegHinId,
    this.fahrwegRueckId,
    this.terminArt,
    this.clientAllocations,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       createdAt = DateTime.now();

  factory Appointment.fromJson(Map<String, dynamic> json) => _$AppointmentFromJson(json);
  Map<String, dynamic> toJson() => _$AppointmentToJson(this);

  /// Rückwärtskompatibel: null → kliententermin
  TerminArt get effectiveTerminArt => terminArt ?? TerminArt.kliententermin;

  /// Ob es sich um einen indirekten Termin handelt
  bool get isIndirect => effectiveTerminArt.isIndirect;

  Appointment copyWith({
    String? clientId,
    String? clientName,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    String? notes,
    String? recordedText,
    String? berufsgruppe,
    String? eingliederung,
    List<String>? icfBereiche,
    double? fachleistungsstunden,
    List<String>? familienhilfeKategorien,
    List<String>? tibBereiche,
    List<String>? selectedTibZiele,
    Map<String, int>? tibZielMinuten,
    String? fahrwegHinId,
    String? fahrwegRueckId,
    TerminArt? terminArt,
    List<ClientAllocation>? clientAllocations,
  }) {
    return Appointment(
      id: id,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      notes: notes ?? this.notes,
      recordedText: recordedText ?? this.recordedText,
      berufsgruppe: berufsgruppe ?? this.berufsgruppe,
      eingliederung: eingliederung ?? this.eingliederung,
      createdAt: createdAt,
      icfBereiche: icfBereiche ?? this.icfBereiche,
      fachleistungsstunden: fachleistungsstunden ?? this.fachleistungsstunden,
      familienhilfeKategorien: familienhilfeKategorien ?? this.familienhilfeKategorien,
      tibBereiche: tibBereiche ?? this.tibBereiche,
      selectedTibZiele: selectedTibZiele ?? this.selectedTibZiele,
      tibZielMinuten: tibZielMinuten ?? this.tibZielMinuten,
      fahrwegHinId: fahrwegHinId ?? this.fahrwegHinId,
      fahrwegRueckId: fahrwegRueckId ?? this.fahrwegRueckId,
      terminArt: terminArt ?? this.terminArt,
      clientAllocations: clientAllocations ?? this.clientAllocations,
    );
  }

  Duration get duration => endTime.difference(startTime);

  String get formattedDuration {
    final duration = this.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Appointment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          clientId == other.clientId &&
          date == other.date;

  @override
  int get hashCode => id.hashCode ^ clientId.hashCode ^ date.hashCode;
}
