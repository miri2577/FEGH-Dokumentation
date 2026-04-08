import 'package:json_annotation/json_annotation.dart';

part 'team.g.dart';

enum TeamStatus {
  @JsonValue('active')
  active,
  @JsonValue('inactive')
  inactive,
  @JsonValue('onHold')
  onHold,
}

@JsonSerializable()
class Team {
  final String id;
  final String name;
  final String description;
  final String? department;
  final String? location;
  final String? teamLeaderId;
  final List<String> memberIds;
  final List<String> clientIds;
  final TeamStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Team({
    required this.id,
    required this.name,
    this.description = '',
    this.department,
    this.location,
    this.teamLeaderId,
    this.memberIds = const [],
    this.clientIds = const [],
    this.status = TeamStatus.active,
    required this.createdAt,
    required this.updatedAt,
  });

  Team.create({
    required this.name,
    this.description = '',
    this.department,
    this.location,
    this.teamLeaderId,
    this.memberIds = const [],
    this.clientIds = const [],
    this.status = TeamStatus.active,
  })  : id = DateTime.now().millisecondsSinceEpoch.toString(),
        createdAt = DateTime.now(),
        updatedAt = DateTime.now();

  factory Team.fromJson(Map<String, dynamic> json) => _$TeamFromJson(json);
  Map<String, dynamic> toJson() => _$TeamToJson(this);

  int get memberCount => memberIds.length;
  int get clientCount => clientIds.length;
  bool get hasTeamLeader => teamLeaderId != null;
  bool get isActive => status == TeamStatus.active;

  Team addMember(String employeeId) {
    if (memberIds.contains(employeeId)) return this;
    return copyWith(memberIds: [...memberIds, employeeId]);
  }

  Team removeMember(String employeeId) {
    return copyWith(
      memberIds: memberIds.where((id) => id != employeeId).toList(),
    );
  }

  Team addClient(String clientId) {
    if (clientIds.contains(clientId)) return this;
    return copyWith(clientIds: [...clientIds, clientId]);
  }

  Team removeClient(String clientId) {
    return copyWith(
      clientIds: clientIds.where((id) => id != clientId).toList(),
    );
  }

  Team copyWith({
    String? name,
    String? description,
    String? department,
    String? location,
    String? teamLeaderId,
    List<String>? memberIds,
    List<String>? clientIds,
    TeamStatus? status,
  }) {
    return Team(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      department: department ?? this.department,
      location: location ?? this.location,
      teamLeaderId: teamLeaderId ?? this.teamLeaderId,
      memberIds: memberIds ?? this.memberIds,
      clientIds: clientIds ?? this.clientIds,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get statusDisplayName {
    switch (status) {
      case TeamStatus.active:
        return 'Aktiv';
      case TeamStatus.inactive:
        return 'Inaktiv';
      case TeamStatus.onHold:
        return 'Pausiert';
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Team && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Team(id: $id, name: $name, members: $memberCount)';
}
