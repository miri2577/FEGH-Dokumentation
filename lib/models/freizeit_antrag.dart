import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

part 'freizeit_antrag.g.dart';

enum FreizeitTyp {
  @JsonValue('urlaub')
  urlaub,
  @JsonValue('freizeitausgleich')
  freizeitausgleich,
  @JsonValue('sonderurlaub')
  sonderurlaub,
  @JsonValue('fortbildung')
  fortbildung,
  @JsonValue('krankmeldung')
  krankmeldung,
  @JsonValue('unbezahlt')
  unbezahlt
}

enum AntragStatus {
  @JsonValue('beantragt')
  beantragt,
  @JsonValue('genehmigt')
  genehmigt,
  @JsonValue('abgelehnt')
  abgelehnt,
  @JsonValue('zurueckgezogen')
  zurueckgezogen
}

@JsonSerializable()
class FreizeitAntrag {
  final String id;
  final String mitarbeiterId;
  final FreizeitTyp typ;
  final DateTime vonDatum;
  final DateTime bisDatum;
  final String grund;
  final String? bemerkung;
  final AntragStatus status;
  final DateTime antragsDatum;
  final DateTime? genehmigungsDatum;
  final String? genehmigungsNotiz;
  final double? stunden; // Für Freizeitausgleich

  FreizeitAntrag({
    required this.id,
    required this.mitarbeiterId,
    required this.typ,
    required this.vonDatum,
    required this.bisDatum,
    required this.grund,
    this.bemerkung,
    this.status = AntragStatus.beantragt,
    required this.antragsDatum,
    this.genehmigungsDatum,
    this.genehmigungsNotiz,
    this.stunden,
  });

  FreizeitAntrag.create({
    required this.mitarbeiterId,
    required this.typ,
    required this.vonDatum,
    required this.bisDatum,
    required this.grund,
    this.bemerkung,
    this.stunden,
  }) : id = DateTime.now().millisecondsSinceEpoch.toString(),
       status = AntragStatus.beantragt,
       antragsDatum = DateTime.now(),
       genehmigungsDatum = null,
       genehmigungsNotiz = null;

  factory FreizeitAntrag.fromJson(Map<String, dynamic> json) => _$FreizeitAntragFromJson(json);
  Map<String, dynamic> toJson() => _$FreizeitAntragToJson(this);

  FreizeitAntrag copyWith({
    String? mitarbeiterId,
    FreizeitTyp? typ,
    DateTime? vonDatum,
    DateTime? bisDatum,
    String? grund,
    String? bemerkung,
    AntragStatus? status,
    DateTime? genehmigungsDatum,
    String? genehmigungsNotiz,
    double? stunden,
  }) {
    return FreizeitAntrag(
      id: id,
      mitarbeiterId: mitarbeiterId ?? this.mitarbeiterId,
      typ: typ ?? this.typ,
      vonDatum: vonDatum ?? this.vonDatum,
      bisDatum: bisDatum ?? this.bisDatum,
      grund: grund ?? this.grund,
      bemerkung: bemerkung ?? this.bemerkung,
      status: status ?? this.status,
      antragsDatum: antragsDatum,
      genehmigungsDatum: genehmigungsDatum ?? this.genehmigungsDatum,
      genehmigungsNotiz: genehmigungsNotiz ?? this.genehmigungsNotiz,
      stunden: stunden ?? this.stunden,
    );
  }

  String get typDisplayName {
    switch (typ) {
      case FreizeitTyp.urlaub:
        return 'Urlaub';
      case FreizeitTyp.freizeitausgleich:
        return 'Freizeitausgleich';
      case FreizeitTyp.sonderurlaub:
        return 'Sonderurlaub';
      case FreizeitTyp.fortbildung:
        return 'Fortbildung';
      case FreizeitTyp.krankmeldung:
        return 'Krankmeldung';
      case FreizeitTyp.unbezahlt:
        return 'Unbezahlter Urlaub';
    }
  }

  String get statusDisplayName {
    switch (status) {
      case AntragStatus.beantragt:
        return 'Beantragt';
      case AntragStatus.genehmigt:
        return 'Genehmigt';
      case AntragStatus.abgelehnt:
        return 'Abgelehnt';
      case AntragStatus.zurueckgezogen:
        return 'Zurückgezogen';
    }
  }

  Color get statusColor {
    switch (status) {
      case AntragStatus.beantragt:
        return Colors.orange;
      case AntragStatus.genehmigt:
        return Colors.green;
      case AntragStatus.abgelehnt:
        return Colors.red;
      case AntragStatus.zurueckgezogen:
        return Colors.grey;
    }
  }

  int get tage {
    return bisDatum.difference(vonDatum).inDays + 1;
  }

  String get zeitraum {
    if (vonDatum.day == bisDatum.day &&
        vonDatum.month == bisDatum.month &&
        vonDatum.year == bisDatum.year) {
      return '${vonDatum.day}.${vonDatum.month}.${vonDatum.year}';
    }
    return '${vonDatum.day}.${vonDatum.month}.${vonDatum.year} - ${bisDatum.day}.${bisDatum.month}.${bisDatum.year}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FreizeitAntrag &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}