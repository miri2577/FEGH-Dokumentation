import 'package:json_annotation/json_annotation.dart';

part 'strecken_cache.g.dart';

@JsonSerializable()
class StreckenCache {
  final String id;
  final String startStandortId;
  final String zielStandortId;
  final double distanzKm;
  final int nutzungsAnzahl; // Zähler für Sortierung der Vorschläge
  final DateTime zuletztGenutzt;
  final DateTime createdAt;

  StreckenCache({
    required this.id,
    required this.startStandortId,
    required this.zielStandortId,
    required this.distanzKm,
    required this.nutzungsAnzahl,
    required this.zuletztGenutzt,
    required this.createdAt,
  });

  StreckenCache.create({
    required this.startStandortId,
    required this.zielStandortId,
    required this.distanzKm,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        nutzungsAnzahl = 1,
        zuletztGenutzt = DateTime.now(),
        createdAt = DateTime.now();

  factory StreckenCache.fromJson(Map<String, dynamic> json) =>
      _$StreckenCacheFromJson(json);
  Map<String, dynamic> toJson() => _$StreckenCacheToJson(this);

  StreckenCache copyWith({
    double? distanzKm,
    int? nutzungsAnzahl,
    DateTime? zuletztGenutzt,
  }) {
    return StreckenCache(
      id: id,
      startStandortId: startStandortId,
      zielStandortId: zielStandortId,
      distanzKm: distanzKm ?? this.distanzKm,
      nutzungsAnzahl: nutzungsAnzahl ?? this.nutzungsAnzahl,
      zuletztGenutzt: zuletztGenutzt ?? this.zuletztGenutzt,
      createdAt: createdAt,
    );
  }

  /// Prüft ob dieser Cache-Eintrag die Strecke zwischen zwei Standorten beschreibt (bidirektional)
  bool matchesRoute(String standortA, String standortB) {
    return (startStandortId == standortA && zielStandortId == standortB) ||
        (startStandortId == standortB && zielStandortId == standortA);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StreckenCache &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
