import 'package:flutter_test/flutter_test.dart';
import 'package:eingliederungshilfe_flutter/models/app_settings.dart';
import 'package:eingliederungshilfe_flutter/services/permission_service.dart';

void main() {
  group('PermissionService', () {
    group('orgAdmin', () {
      final perms = PermissionService(UserRole.orgAdmin);

      test('hat vollen Zugriff', () {
        expect(perms.canViewClients, isTrue);
        expect(perms.canCreateClient, isTrue);
        expect(perms.canEditClientMasterData, isTrue);
        expect(perms.canEditClientDocumentation, isTrue);
        expect(perms.canDeleteClient, isTrue);
        expect(perms.canReassignClient, isTrue);
        expect(perms.canManageTeams, isTrue);
        expect(perms.canInviteEmployees, isTrue);
        expect(perms.canChangeRoles, isTrue);
        expect(perms.canManageOrganization, isTrue);
        expect(perms.canAccessAdmin, isTrue);
        expect(perms.canUseAdminTools, isTrue);
        expect(perms.canViewAuditLog, isTrue);
        expect(perms.isReadOnly, isFalse);
      });

      test('Rollenname ist korrekt', () {
        expect(perms.roleDisplayName, 'Organisations-Admin');
      });
    });

    group('teamMember', () {
      final perms = PermissionService(UserRole.teamMember);

      test('kann dokumentieren', () {
        expect(perms.canViewClients, isTrue);
        expect(perms.canEditClientDocumentation, isTrue);
        expect(perms.canManageAppointments, isTrue);
        expect(perms.canWriteReports, isTrue);
        expect(perms.canTrackWorkTime, isTrue);
        expect(perms.canExportReports, isTrue);
      });

      test('kann keine Klienten anlegen oder loeschen', () {
        expect(perms.canCreateClient, isFalse);
        expect(perms.canDeleteClient, isFalse);
        expect(perms.canEditClientMasterData, isFalse);
        expect(perms.canReassignClient, isFalse);
      });

      test('hat keinen Admin-Zugriff', () {
        expect(perms.canManageTeams, isFalse);
        expect(perms.canChangeRoles, isFalse);
        expect(perms.canManageOrganization, isFalse);
        expect(perms.canAccessAdmin, isFalse);
        expect(perms.canUseAdminTools, isFalse);
        expect(perms.canViewAuditLog, isFalse);
      });

      test('ist nicht read-only', () {
        expect(perms.isReadOnly, isFalse);
      });
    });

    group('teamLead', () {
      final perms = PermissionService(UserRole.teamLead);

      test('kann Klienten anlegen und Stammdaten aendern', () {
        expect(perms.canCreateClient, isTrue);
        expect(perms.canEditClientMasterData, isTrue);
      });

      test('kann nicht loeschen oder Teams verwalten', () {
        expect(perms.canDeleteClient, isFalse);
        expect(perms.canManageTeams, isFalse);
        expect(perms.canChangeRoles, isFalse);
      });

      test('kann Mitarbeiter einladen', () {
        expect(perms.canInviteEmployees, isTrue);
      });

      test('kann Recovery-Token fuer Mitarbeiter generieren', () {
        expect(perms.canGenerateRecoveryToken, isTrue);
        expect(perms.canRecoverTeamLead, isFalse);
      });

      test('kann Arbeitszeit anderer einsehen', () {
        expect(perms.canViewOtherWorkTime, isTrue);
      });
    });

    group('orgAuditor', () {
      final perms = PermissionService(UserRole.orgAuditor);

      test('ist read-only', () {
        expect(perms.isReadOnly, isTrue);
      });

      test('kann Daten ansehen aber nicht bearbeiten', () {
        expect(perms.canViewClients, isTrue);
        expect(perms.canExportReports, isTrue);
        expect(perms.canViewAuditLog, isTrue);
      });

      test('kann nichts bearbeiten', () {
        expect(perms.canEditClientDocumentation, isFalse);
        expect(perms.canManageAppointments, isFalse);
        expect(perms.canWriteReports, isFalse);
        expect(perms.canTrackWorkTime, isFalse);
        expect(perms.canCreateClient, isFalse);
        expect(perms.canDeleteClient, isFalse);
      });
    });

    group('pvAdmin', () {
      final perms = PermissionService(UserRole.pvAdmin);

      test('hat gleiche Rechte wie orgAdmin', () {
        expect(perms.canDeleteClient, isTrue);
        expect(perms.canManageTeams, isTrue);
        expect(perms.canChangeRoles, isTrue);
        expect(perms.canManageOrganization, isTrue);
        expect(perms.canAccessAdmin, isTrue);
        expect(perms.canRecoverTeamLead, isTrue);
      });
    });

    group('permissionSummary', () {
      test('teamMember hat weniger Berechtigungen als orgAdmin', () {
        final member = PermissionService(UserRole.teamMember);
        final admin = PermissionService(UserRole.orgAdmin);
        expect(member.permissionSummary.length, lessThan(admin.permissionSummary.length));
      });

      test('orgAuditor hat am wenigsten Berechtigungen', () {
        final auditor = PermissionService(UserRole.orgAuditor);
        final member = PermissionService(UserRole.teamMember);
        expect(auditor.permissionSummary.length, lessThan(member.permissionSummary.length));
      });
    });
  });
}
