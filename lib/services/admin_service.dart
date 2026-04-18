import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:fegh_crypto/fegh_crypto.dart' as shared;
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/app_settings.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';
import 'file_logger.dart';
import 'totp_service.dart';

/// Zentraler Service für Admin-Operationen:
/// Team-Verwaltung, Mitarbeiter-Einladung, Rollen, Health Checks.
class AdminService {
  final CryptoStorage crypto;
  final HiDriveBusinessSync adminSync;
  final AppSettings settings;

  AdminService({
    required this.crypto,
    required this.adminSync,
    required this.settings,
  });

  // ── Team-Verwaltung ──────────────────────────────────────────────

  /// Erstellt ein neues Team. Funktioniert mit und ohne HiDrive.
  ///
  /// - Ohne HiDrive-Config: Team + Key nur lokal (verschluesselt via CryptoStorage)
  /// - Mit HiDrive-Config: Lokal + Upload auf HiDrive (fuer Team-Sync)
  Future<bool> createTeam(Team team) async {
    final hasHidrive = settings.hidriveUsername.isNotEmpty &&
        settings.hidrivePassword.isNotEmpty;

    try {
      // 1. Team-Key generieren (32 Byte AES) - immer
      final teamKey = _generateSecureRandomBytes(32);

      // 2. Immer lokal speichern (Team-Info + Team-Key)
      final teamJson = jsonEncode(team.toJson());
      final encryptedInfo = await crypto.encryptRecord(
        plaintext: utf8.encode(teamJson),
        aad: {'type': 'team-info', 'teamId': team.id},
      );
      await crypto.saveJsonEncrypted('team-info', {
        'teamId': team.id,
        'record': encryptedInfo,
      });

      final encryptedKey = await crypto.encryptRecord(
        plaintext: teamKey,
        aad: {'type': 'team-key', 'teamId': team.id},
      );
      await crypto.saveJsonEncrypted('team-key', {
        'teamId': team.id,
        'record': encryptedKey,
      });

      // 3. Wenn HiDrive konfiguriert: zusaetzlich hochladen
      bool cloudOk = false;
      if (hasHidrive) {
        try {
          final teamSync = HiDriveBusinessSync.forTeam(
            username: settings.hidriveUsername,
            password: settings.hidrivePassword,
            organizationId: settings.organizationId,
            teamId: team.id,
            rootSubdirectory: settings.rootSubdirectory.isNotEmpty
                ? settings.rootSubdirectory
                : null,
          );
          final setupResult = await teamSync.setupRemoteDirectory();
          if (!setupResult.isSuccess) {
            await FileLogger().log(
                '⚠️ HiDrive-Ordner-Setup fehlgeschlagen: ${setupResult.error}');
          } else {
            final keyOk = await _uploadTeamKey(team.id, teamKey);
            final encBytes =
                Uint8List.fromList(utf8.encode(jsonEncode(encryptedInfo)));
            final infoResult = await adminSync.uploadOrgScopedRecord(
              'teams/${team.id}',
              'team-info',
              encBytes,
            );
            cloudOk = keyOk && infoResult.isSuccess;
            if (!keyOk) {
              await FileLogger().log(
                  '⚠️ Team-Key-Upload fehlgeschlagen fuer ${team.id}');
            }
            if (!infoResult.isSuccess) {
              await FileLogger().log(
                  '⚠️ Team-Info-Upload fehlgeschlagen: ${infoResult.error}');
            }
          }
        } catch (e) {
          await FileLogger().log('⚠️ HiDrive-Upload Exception: $e');
        }
      }

      await FileLogger().log(
          '✅ Team erstellt: ${team.name} (${team.id}) '
          '${cloudOk ? "+ HiDrive" : hasHidrive ? "[NUR LOKAL - HiDrive schlug fehl]" : "[lokal]"}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] createTeam error: $e');
      await FileLogger().log('❌ Team-Erstellung fehlgeschlagen: $e');
      return false;
    }
  }

  /// Laedt nur lokal gespeicherte Teams (ohne HiDrive).
  Future<List<Team>> listTeamsLocal() async {
    final teams = <Team>[];
    try {
      final manifest = await crypto.loadManifest();
      for (final entry in manifest.entries.where((e) => e.schema == 'team-info')) {
        try {
          final data = await crypto.loadJsonDecrypted(entry.uuid);
          final rec = data['record'] as Map<String, dynamic>;
          final clearBytes = await crypto.decryptRecord(rec);
          teams.add(Team.fromJson(jsonDecode(utf8.decode(clearBytes))));
        } catch (_) {}
      }
    } catch (_) {}
    return teams;
  }

  /// Laedt nur Teams aus HiDrive (ohne lokalen Store).
  /// Liefert null wenn HiDrive nicht konfiguriert oder nicht erreichbar.
  Future<List<Team>?> listTeamsCloud() async {
    if (settings.hidriveUsername.isEmpty || settings.hidrivePassword.isEmpty) {
      return null;
    }
    try {
      final result = await adminSync.listOrgScopedDirectories('teams');
      if (!result.isSuccess || result.data == null) return null;
      final teams = <Team>[];
      for (final teamDir in result.data!) {
        try {
          final infoResult = await adminSync.downloadOrgScopedRecord(
            'teams/$teamDir',
            'team-info',
          );
          if (infoResult.isSuccess && infoResult.data != null) {
            final encJson = jsonDecode(utf8.decode(infoResult.data!));
            final clearBytes = await crypto.decryptRecord(encJson);
            teams.add(Team.fromJson(jsonDecode(utf8.decode(clearBytes))));
          }
        } catch (_) {}
      }
      return teams;
    } catch (_) {
      return null;
    }
  }

  /// Lädt alle Teams aus der Organisation (lokal + Cloud, gemergt).
  Future<List<Team>> listTeams() async {
    final teamsById = <String, Team>{};

    // 1. Lokale Teams laden (Quelle der Wahrheit)
    try {
      final manifest = await crypto.loadManifest();
      for (final entry in manifest.entries.where((e) => e.schema == 'team-info')) {
        try {
          final data = await crypto.loadJsonDecrypted(entry.uuid);
          final rec = data['record'] as Map<String, dynamic>;
          final clearBytes = await crypto.decryptRecord(rec);
          final teamJson = jsonDecode(utf8.decode(clearBytes));
          final t = Team.fromJson(teamJson);
          teamsById[t.id] = t;
        } catch (e) {
          debugPrint('[ADMIN] Lokales Team-Entry kaputt: $e');
        }
      }
      debugPrint('[ADMIN] listTeams lokal: ${teamsById.length} Teams');
    } catch (e) {
      debugPrint('[ADMIN] listTeams lokal Fehler: $e');
    }

    // 2. Zusaetzlich HiDrive wenn konfiguriert
    final hasHidrive = settings.hidriveUsername.isNotEmpty &&
        settings.hidrivePassword.isNotEmpty;
    if (hasHidrive) {
      try {
        final result = await adminSync.listOrgScopedDirectories('teams');
        if (result.isSuccess && result.data != null) {
          for (final teamDir in result.data!) {
            try {
              final infoResult = await adminSync.downloadOrgScopedRecord(
                'teams/$teamDir',
                'team-info',
              );
              if (infoResult.isSuccess && infoResult.data != null) {
                final encJson = jsonDecode(utf8.decode(infoResult.data!));
                final clearBytes = await crypto.decryptRecord(encJson);
                final teamJson = jsonDecode(utf8.decode(clearBytes));
                final t = Team.fromJson(teamJson);
                // Cloud-Version ueberschreibt nur wenn neuer (updatedAt)
                final existing = teamsById[t.id];
                if (existing == null || t.updatedAt.isAfter(existing.updatedAt)) {
                  teamsById[t.id] = t;
                }
              }
            } catch (e) {
              debugPrint('[ADMIN] Team $teamDir von Cloud FEHLER: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[ADMIN] listTeams Cloud-Fehler (ignoriert): $e');
      }
    }

    return teamsById.values.toList();
  }

  /// Aktualisiert Team-Info auf HiDrive.
  Future<bool> updateTeam(Team team) async {
    try {
      final teamJson = jsonEncode(team.toJson());
      final encrypted = await crypto.encryptRecord(
        plaintext: utf8.encode(teamJson),
        aad: {'type': 'team-info', 'teamId': team.id},
      );
      final encBytes = Uint8List.fromList(utf8.encode(jsonEncode(encrypted)));
      final result = await adminSync.uploadOrgScopedRecord(
        'teams/${team.id}',
        'team-info',
        encBytes,
      );
      return result.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] updateTeam error: $e');
      return false;
    }
  }

  // ── Team-Key-Verwaltung ──────────────────────────────────────────

  Future<bool> _uploadTeamKey(String teamId, Uint8List key) async {
    try {
      final payload = {
        'teamKey': base64Encode(key),
        'ts': DateTime.now().toIso8601String(),
      };
      final encrypted = await crypto.encryptRecord(
        plaintext: utf8.encode(jsonEncode(payload)),
        aad: {'type': 'team-key', 'teamId': teamId},
      );
      final encBytes = Uint8List.fromList(utf8.encode(jsonEncode(encrypted)));
      final result = await adminSync.uploadOrgScopedRecord(
        'administration/teams/$teamId',
        'team-key',
        encBytes,
      );
      return result.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] _uploadTeamKey error: $e');
      return false;
    }
  }

  /// Lädt einen Team-Key als Base64-String.
  Future<String?> fetchTeamKeyBase64(String teamId) async {
    try {
      final result = await adminSync.downloadOrgScopedRecord(
        'administration/teams/$teamId',
        'team-key',
      );
      if (!result.isSuccess || result.data == null) return null;
      final encJson = jsonDecode(utf8.decode(result.data!));
      final clearBytes = await crypto.decryptRecord(encJson);
      final obj = jsonDecode(utf8.decode(clearBytes));
      return obj['teamKey'] as String?;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] fetchTeamKeyBase64 error: $e');
      return null;
    }
  }

  // ── Provisioning-Token ───────────────────────────────────────────

  /// Generiert ein Provisioning-Token fuer einen Mitarbeiter.
  /// Delegiert ans Shared-Package `fegh_crypto` - Format kompatibel
  /// zur FEGH-Verwaltung.
  Future<String?> generateProvisioningToken({
    required String employeeEmail,
    required String role,
    required List<String> teamIds,
    required String pin,
  }) async {
    try {
      final teamKeys = <String, String>{};
      for (final teamId in teamIds) {
        final keyB64 = await fetchTeamKeyBase64(teamId);
        if (keyB64 != null) {
          teamKeys[teamId] = keyB64;
        }
      }

      final totpSecret = TotpService.generateSecret();
      final totpSecretB32 = TotpService.secretToBase32(totpSecret);

      final token = shared.ProvisioningToken(
        org: settings.organizationId,
        user: employeeEmail,
        role: role,
        teams: teamIds,
        teamKeys: teamKeys,
        totp: totpSecretB32,
        hidrive: shared.HidriveCredentials(
          username: settings.hidriveUsername,
          appPassword: settings.hidrivePassword,
        ),
        flags: const {
          'managed': true,
          'forceInitialSync': true,
        },
        ts: DateTime.now().toUtc(),
      );
      return await token.encryptWithPin(pin);
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] generateProvisioningToken error: $e');
      return null;
    }
  }

  /// Entschluesselt ein Provisioning-Token mit PIN.
  /// Delegiert ans Shared-Package.
  static Future<Map<String, dynamic>?> decryptProvisioningToken(
    String tokenB64,
    String pin,
  ) async {
    final token = await shared.ProvisioningToken.decryptWithPin(tokenB64, pin);
    return token?.toJson();
  }

  // ── Rollen-Verwaltung (roles.json) ───────────────────────────────

  /// Lädt roles.json von HiDrive.
  Future<Map<String, dynamic>> loadRolesPolicy() async {
    try {
      final result = await adminSync.downloadOrgScopedRecord(
        'administration/users',
        'roles',
      );
      if (!result.isSuccess || result.data == null) {
        return {'users': []};
      }
      // roles.json ist unverschlüsselt (Klartext JSON)
      return jsonDecode(utf8.decode(result.data!));
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] loadRolesPolicy error: $e');
      return {'users': []};
    }
  }

  /// Speichert roles.json auf HiDrive.
  Future<bool> saveRolesPolicy(Map<String, dynamic> policy) async {
    try {
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(policy)));
      // roles.json als .bin speichern (Konvention des WebDAV-Clients)
      final result = await adminSync.uploadOrgScopedRecord(
        'administration/users',
        'roles',
        bytes,
      );
      return result.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] saveRolesPolicy error: $e');
      return false;
    }
  }

  /// Fügt eine Rolle für einen User hinzu oder aktualisiert sie.
  Future<bool> setUserRole({
    required String userId,
    required String role,
    required List<String> teams,
  }) async {
    final policy = await loadRolesPolicy();
    final users = List<Map<String, dynamic>>.from(policy['users'] ?? []);
    users.removeWhere((u) => u['id'] == userId);
    users.add({
      'id': userId,
      'role': role,
      'teams': teams,
    });
    policy['users'] = users;
    return saveRolesPolicy(policy);
  }

  /// Entfernt eine Rolle für einen User.
  Future<bool> removeUserRole(String userId) async {
    final policy = await loadRolesPolicy();
    final users = List<Map<String, dynamic>>.from(policy['users'] ?? []);
    users.removeWhere((u) => u['id'] == userId);
    policy['users'] = users;
    return saveRolesPolicy(policy);
  }

  // ── Health Checks ────────────────────────────────────────────────

  /// Prüft den Zustand der HiDrive-Ordnerstruktur.
  Future<Map<String, bool>> runHealthChecks() async {
    final results = <String, bool>{};

    // 1. Verbindung testen
    final conn = await adminSync.testConnection();
    results['connection'] = conn.isSuccess;
    if (!conn.isSuccess) return results;

    // 2. Admin-Ordner prüfen
    final adminDir = await adminSync.listOrgScopedRecords('administration');
    results['adminFolder'] = adminDir.isSuccess;

    // 3. Teams-Ordner prüfen
    final teamsDir = await adminSync.listOrgScopedRecords('teams');
    results['teamsFolder'] = teamsDir.isSuccess;

    // 4. roles.json prüfen
    final roles = await adminSync.downloadOrgScopedRecord(
      'administration/users',
      'roles',
    );
    results['rolesPolicy'] = roles.isSuccess;

    // 5. Schreibtest
    try {
      final testData = Uint8List.fromList(utf8.encode('health-check'));
      final writeResult = await adminSync.uploadOrgScopedRecord(
        'administration',
        '.health-test',
        testData,
      );
      results['writeAccess'] = writeResult.isSuccess;
      if (writeResult.isSuccess) {
        await adminSync.deleteOrgScopedRecord('administration', '.health-test');
      }
    } catch (_) {
      results['writeAccess'] = false;
    }

    return results;
  }

  // ── Org-Struktur initialisieren ──────────────────────────────────

  /// Erstellt die komplette Organisationsstruktur auf HiDrive.
  Future<bool> initializeOrganizationStructure() async {
    try {
      // Admin-Ordnerstruktur erstellen
      final result = await adminSync.setupRemoteDirectory();
      if (!result.isSuccess) {
        await FileLogger().log('❌ Org-Struktur Setup fehlgeschlagen: ${result.error}');
        return false;
      }

      // Initiale roles.json erstellen
      final rolesPolicy = {
        'users': [
          {
            'id': settings.hidriveUsername,
            'role': 'org_admin',
            'teams': <String>[],
          }
        ],
        'createdAt': DateTime.now().toIso8601String(),
      };
      await saveRolesPolicy(rolesPolicy);

      await FileLogger().log('✅ Org-Struktur initialisiert für ${settings.organizationId}');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] initializeOrganizationStructure error: $e');
      return false;
    }
  }

  // ── Klienten-Zuweisung ──────────────────────────────────────────

  /// Weist einen Klienten einem Team zu (kopiert/verlinkt den Record).
  Future<bool> assignClientToTeam({
    required String clientId,
    required String teamId,
    required Uint8List encryptedClientData,
  }) async {
    try {
      final result = await adminSync.uploadOrgScopedRecord(
        'teams/$teamId/clients',
        clientId,
        encryptedClientData,
      );
      return result.isSuccess;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] assignClientToTeam error: $e');
      return false;
    }
  }

  // ── Hilfsfunktionen ─────────────────────────────────────────────

  static Uint8List _generateSecureRandomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(
      List<int>.generate(length, (_) => random.nextInt(256)),
    );
  }
}
