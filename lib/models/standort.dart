import 'package:json_annotation/json_annotation.dart';

part 'standort.g.dart';

@JsonSerializable()
class Standort {
  final String id;
  final String name; // "Büro", "Klient Müller", "Amt Neukölln"
  final StandortTyp typ;
  final String? clientId; // Optional: Verknüpfung mit Klient
  final double? latitude; // Optional: Für Auto-Distanzberechnung
  final double? longitude;
  final DateTime createdAt;

  Standort({
    required this.id,
    required this.name,
    required this.typ,
    this.clientId,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });

  Standort.create({
    required this.name,
    required this.typ,
    this.clientId,
    this.latitude,
    this.longitude,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now();

  bool get hasCoordinates => latitude != null && longitude != null;

  factory Standort.fromJson(Map<String, dynamic> json) =>
      _$StandortFromJson(json);
  Map<String, dynamic> toJson() => _$StandortToJson(this);

  Standort copyWith({
    String? name,
    StandortTyp? typ,
    String? clientId,
    double? latitude,
    double? longitude,
  }) {
    return Standort(
      id: id,
      name: name ?? this.name,
      typ: typ ?? this.typ,
      clientId: clientId ?? this.clientId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Standort &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

enum StandortTyp {
  buero,
  klient,
  amt,
  sonstige,
}

extension StandortTypExtension on StandortTyp {
  String get displayName {
    switch (this) {
      case StandortTyp.buero:
        return 'Büro';
      case StandortTyp.klient:
        return 'Klient';
      case StandortTyp.amt:
        return 'Amt/Behörde';
      case StandortTyp.sonstige:
        return 'Sonstige';
    }
  }
}
