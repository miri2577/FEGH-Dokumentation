import 'package:json_annotation/json_annotation.dart';

part 'fahrweg.g.dart';

@JsonSerializable()
class Fahrweg {
  final String id;
  final DateTime datum;
  final String startStandortId;
  final String startStandortName; // Denormalisiert für schnelle Anzeige
  final String zielStandortId;
  final String zielStandortName;
  final double distanzKm;
  final String? appointmentId; // Optional: Verknüpfung mit Termin
  final String? clientId;
  final String? notizen; // z.B. "Umweg wegen Baustelle"
  final DateTime createdAt;

  Fahrweg({
    required this.id,
    required this.datum,
    required this.startStandortId,
    required this.startStandortName,
    required this.zielStandortId,
    required this.zielStandortName,
    required this.distanzKm,
    this.appointmentId,
    this.clientId,
    this.notizen,
    required this.createdAt,
  });

  Fahrweg.create({
    required this.datum,
    required this.startStandortId,
    required this.startStandortName,
    required this.zielStandortId,
    required this.zielStandortName,
    required this.distanzKm,
    this.appointmentId,
    this.clientId,
    this.notizen,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();

  factory Fahrweg.fromJson(Map<String, dynamic> json) =>
      _$FahrwegFromJson(json);
  Map<String, dynamic> toJson() => _$FahrwegToJson(this);

  Fahrweg copyWith({
    DateTime? datum,
    String? startStandortId,
    String? startStandortName,
    String? zielStandortId,
    String? zielStandortName,
    double? distanzKm,
    String? appointmentId,
    String? clientId,
    String? notizen,
  }) {
    return Fahrweg(
      id: id,
      datum: datum ?? this.datum,
      startStandortId: startStandortId ?? this.startStandortId,
      startStandortName: startStandortName ?? this.startStandortName,
      zielStandortId: zielStandortId ?? this.zielStandortId,
      zielStandortName: zielStandortName ?? this.zielStandortName,
      distanzKm: distanzKm ?? this.distanzKm,
      appointmentId: appointmentId ?? this.appointmentId,
      clientId: clientId ?? this.clientId,
      notizen: notizen ?? this.notizen,
      createdAt: createdAt,
    );
  }

  String get formatiertesDatum {
    return '${datum.day.toString().padLeft(2, '0')}.${datum.month.toString().padLeft(2, '0')}.${datum.year}';
  }

  String get streckenBeschreibung => '$startStandortName → $zielStandortName';

  String get formatierteDistanz => '${distanzKm.toStringAsFixed(1)} km';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fahrweg &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
