import 'package:json_annotation/json_annotation.dart';

part 'organization.g.dart';

@JsonSerializable()
class Organization {
  final String id;
  final String name;
  final String? description;
  final String address;
  final String? phone;
  final String? email;
  final String? website;
  final String? licenseNumber;
  final OrganizationType type;
  final List<String> services;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> settings;

  Organization({
    required this.id,
    required this.name,
    this.description,
    required this.address,
    this.phone,
    this.email,
    this.website,
    this.licenseNumber,
    required this.type,
    this.services = const [],
    required this.createdAt,
    required this.updatedAt,
    this.settings = const {},
  });

  factory Organization.fromJson(Map<String, dynamic> json) => _$OrganizationFromJson(json);
  Map<String, dynamic> toJson() => _$OrganizationToJson(this);

  Organization copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? phone,
    String? email,
    String? website,
    String? licenseNumber,
    OrganizationType? type,
    List<String>? services,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? settings,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      type: type ?? this.type,
      services: services ?? this.services,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      settings: settings ?? this.settings,
    );
  }

  @override
  String toString() => 'Organization(id: $id, name: $name)';
}

enum OrganizationType {
  @JsonValue('residential')
  residential,      // Wohneinrichtung

  @JsonValue('ambulant')
  ambulant,         // Ambulanter Dienst

  @JsonValue('workshop')
  workshop,         // Werkstatt

  @JsonValue('daycare')
  daycare,          // Tagesstätte

  @JsonValue('counseling')
  counseling,       // Beratungsstelle

  @JsonValue('mixed')
  mixed,            // Gemischte Dienste
}

extension OrganizationTypeExtension on OrganizationType {
  String get displayName {
    switch (this) {
      case OrganizationType.residential:
        return 'Wohneinrichtung';
      case OrganizationType.ambulant:
        return 'Ambulanter Dienst';
      case OrganizationType.workshop:
        return 'Werkstatt für Menschen mit Behinderung';
      case OrganizationType.daycare:
        return 'Tagesstätte';
      case OrganizationType.counseling:
        return 'Beratungsstelle';
      case OrganizationType.mixed:
        return 'Gemischte Dienste';
    }
  }

  List<String> get defaultServices {
    switch (this) {
      case OrganizationType.residential:
        return ['Wohnen', 'Betreuung', 'Pflege', 'Teilhabe'];
      case OrganizationType.ambulant:
        return ['Beratung', 'Begleitung', 'Assistenz'];
      case OrganizationType.workshop:
        return ['Arbeit', 'Bildung', 'Förderung'];
      case OrganizationType.daycare:
        return ['Betreuung', 'Förderung', 'Teilhabe'];
      case OrganizationType.counseling:
        return ['Beratung', 'Information', 'Vermittlung'];
      case OrganizationType.mixed:
        return ['Wohnen', 'Arbeit', 'Beratung', 'Betreuung'];
    }
  }
}