import '../models/app_settings.dart';

/// Rollenbasierte Zugriffskontrolle.
/// Prueft ob ein Nutzer eine bestimmte Aktion ausfuehren darf.
class PermissionService {
  final UserRole role;

  const PermissionService(this.role);

  // ── Klienten ─────────────────────────────────────────────────────

  /// Klienten des eigenen Teams ansehen
  bool get canViewClients => true;

  /// Neuen Klient anlegen
  bool get canCreateClient =>
      role == UserRole.teamLead ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Klient-Stammdaten aendern (Name, Kostenuebernahme, etc.)
  bool get canEditClientMasterData =>
      role == UserRole.teamLead ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Klient-Dokumentation bearbeiten (Termine, Berichte)
  bool get canEditClientDocumentation => role != UserRole.orgAuditor;

  /// Klient loeschen oder archivieren
  bool get canDeleteClient =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Klient einem anderen Team zuweisen
  bool get canReassignClient =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  // ── Termine & Berichte ───────────────────────────────────────────

  /// Termine erstellen und bearbeiten
  bool get canManageAppointments => role != UserRole.orgAuditor;

  /// Berichte schreiben
  bool get canWriteReports => role != UserRole.orgAuditor;

  /// Berichte exportieren
  bool get canExportReports => true;

  // ── Arbeitszeit ──────────────────────────────────────────────────

  /// Eigene Arbeitszeit erfassen
  bool get canTrackWorkTime => role != UserRole.orgAuditor;

  /// Arbeitszeit anderer Mitarbeiter einsehen
  bool get canViewOtherWorkTime =>
      role == UserRole.teamLead ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  // ── Team-Verwaltung ──────────────────────────────────────────────

  /// Teams erstellen und bearbeiten
  bool get canManageTeams =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Mitarbeiter einladen
  bool get canInviteEmployees =>
      role == UserRole.teamLead ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Mitarbeiter-Rollen aendern
  bool get canChangeRoles =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  // ── Organisation ─────────────────────────────────────────────────

  /// Organisationsstruktur verwalten
  bool get canManageOrganization =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Verwaltung-Tab sehen
  bool get canAccessAdmin =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Health Checks und Admin-Tools nutzen
  bool get canUseAdminTools =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  // ── Recovery ─────────────────────────────────────────────────────

  /// Recovery-Token fuer Mitarbeiter generieren
  bool get canGenerateRecoveryToken =>
      role == UserRole.teamLead ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Recovery-Token fuer Teamleitungen generieren
  bool get canRecoverTeamLead =>
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  // ── Audit ────────────────────────────────────────────────────────

  /// Audit-Log einsehen
  bool get canViewAuditLog =>
      role == UserRole.orgAuditor ||
      role == UserRole.orgAdmin ||
      role == UserRole.pvAdmin;

  /// Daten nur lesen (Auditor-Modus)
  bool get isReadOnly => role == UserRole.orgAuditor;

  // ── Hilfsmethoden ────────────────────────────────────────────────

  /// Anzeigename der Rolle
  String get roleDisplayName {
    switch (role) {
      case UserRole.orgAdmin:
        return 'Organisations-Admin';
      case UserRole.pvAdmin:
        return 'Personalverwaltungs-Admin';
      case UserRole.teamLead:
        return 'Teamleitung';
      case UserRole.teamMember:
        return 'Mitarbeiter';
      case UserRole.orgAuditor:
        return 'Pruefer (nur Lesen)';
    }
  }

  /// Beschreibung der Berechtigungen fuer die aktuelle Rolle
  List<String> get permissionSummary {
    final perms = <String>[];
    if (canViewClients) perms.add('Klienten ansehen');
    if (canCreateClient) perms.add('Klienten anlegen');
    if (canEditClientMasterData) perms.add('Stammdaten aendern');
    if (canEditClientDocumentation) perms.add('Dokumentation bearbeiten');
    if (canDeleteClient) perms.add('Klienten loeschen');
    if (canReassignClient) perms.add('Klienten zuweisen');
    if (canManageAppointments) perms.add('Termine verwalten');
    if (canWriteReports) perms.add('Berichte schreiben');
    if (canManageTeams) perms.add('Teams verwalten');
    if (canInviteEmployees) perms.add('Mitarbeiter einladen');
    if (canChangeRoles) perms.add('Rollen aendern');
    if (canManageOrganization) perms.add('Organisation verwalten');
    if (canViewAuditLog) perms.add('Audit-Log einsehen');
    return perms;
  }
}
