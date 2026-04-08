import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart' as aes;
import 'package:crypto/crypto.dart' as hash;
import 'package:flutter/foundation.dart';
import '../models/team.dart';
import '../models/app_settings.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';
import 'file_logger.dart';

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

  /// Erstellt ein neues Team: HiDrive-Ordner + Team-Key generieren + hochladen.
  Future<bool> createTeam(Team team) async {
    try {
      // 1. Team-Ordner auf HiDrive anlegen
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
        await FileLogger().log('❌ Team-Ordner Setup fehlgeschlagen: ${setupResult.error}');
        return false;
      }

      // 2. Team-Key generieren (32 Byte AES)
      final teamKey = _generateSecureRandomBytes(32);
      final keySuccess = await _uploadTeamKey(team.id, teamKey);
      if (!keySuccess) {
        await FileLogger().log('❌ Team-Key Upload fehlgeschlagen für Team ${team.id}');
        return false;
      }

      // 3. Team-Info verschlüsselt hochladen
      final teamJson = jsonEncode(team.toJson());
      final encrypted = await crypto.encryptRecord(
        plaintext: utf8.encode(teamJson),
        aad: {'type': 'team-info', 'teamId': team.id},
      );
      final encBytes = Uint8List.fromList(utf8.encode(jsonEncode(encrypted)));
      final uploadResult = await adminSync.uploadOrgScopedRecord(
        'teams/${team.id}',
        'team-info',
        encBytes,
      );
      if (!uploadResult.isSuccess) {
        await FileLogger().log('❌ Team-Info Upload fehlgeschlagen: ${uploadResult.error}');
        return false;
      }

      await FileLogger().log('✅ Team erstellt: ${team.name} (${team.id})');
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] createTeam error: $e');
      return false;
    }
  }

  /// Lädt alle Teams aus der Organisation.
  Future<List<Team>> listTeams() async {
    try {
      final result = await adminSync.listOrgScopedRecords('teams');
      if (!result.isSuccess || result.data == null) return [];

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
            final teamJson = jsonDecode(utf8.decode(clearBytes));
            teams.add(Team.fromJson(teamJson));
          }
        } catch (e) {
          if (kDebugMode) debugPrint('[ADMIN] Team $teamDir laden fehlgeschlagen: $e');
        }
      }
      return teams;
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] listTeams error: $e');
      return [];
    }
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

  /// Generiert ein Provisioning-Token für einen Mitarbeiter.
  /// Das Token enthält alle Infos zum automatischen Setup.
  /// Wird mit einem PIN verschlüsselt (AES-256-GCM, PBKDF2).
  Future<String?> generateProvisioningToken({
    required String employeeEmail,
    required String role,
    required List<String> teamIds,
    required String pin,
  }) async {
    try {
      // Team-Keys laden
      final teamKeys = <String, String>{};
      for (final teamId in teamIds) {
        final keyB64 = await fetchTeamKeyBase64(teamId);
        if (keyB64 != null) {
          teamKeys[teamId] = keyB64;
        }
      }

      final payload = {
        'type': 'egh-provisioning-v1',
        'org': settings.organizationId,
        'user': employeeEmail,
        'role': role,
        'teams': teamIds,
        'teamKeys': teamKeys,
        'hidrive': {
          'username': settings.hidriveUsername,
          'appPassword': settings.hidrivePassword,
        },
        'flags': {
          'managed': true,
          'forceInitialSync': true,
        },
        'ts': DateTime.now().toIso8601String(),
      };

      // Token mit PIN verschlüsseln
      final payloadBytes = utf8.encode(jsonEncode(payload));
      final pinKey = await _deriveKeyFromPin(pin);
      final encrypted = await _encryptWithKey(payloadBytes, pinKey);
      return base64Encode(utf8.encode(jsonEncode(encrypted)));
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] generateProvisioningToken error: $e');
      return null;
    }
  }

  /// Entschlüsselt ein Provisioning-Token mit PIN.
  static Future<Map<String, dynamic>?> decryptProvisioningToken(
    String tokenB64,
    String pin,
  ) async {
    try {
      final tokenJson = jsonDecode(utf8.decode(base64Decode(tokenB64)));
      final pinKey = await _deriveKeyFromPinStatic(pin);
      final clearBytes = await _decryptWithKeyStatic(tokenJson, pinKey);
      return jsonDecode(utf8.decode(clearBytes));
    } catch (e) {
      if (kDebugMode) debugPrint('[ADMIN] decryptProvisioningToken error: $e');
      return null;
    }
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

  /// PBKDF2-artige Key-Ableitung aus PIN (vereinfacht mit SHA-256 Iterationen).
  Future<Uint8List> _deriveKeyFromPin(String pin) async {
    return _deriveKeyFromPinStatic(pin);
  }

  static Future<Uint8List> _deriveKeyFromPinStatic(String pin) async {
    final salt = utf8.encode('egh-provisioning-salt-v1');
    List<int> key = utf8.encode(pin);
    for (int i = 0; i < 10000; i++) {
      final hmac = hash.Hmac(hash.sha256, salt);
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }

  static Future<Map<String, dynamic>> _encryptWithKey(
    List<int> plaintext,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final nonce = _generateSecureRandomBytes(12);
    final secretKey = aes.SecretKey(key);
    final box = await cipher.encrypt(plaintext, secretKey: secretKey, nonce: nonce);
    return {
      'nonce': base64Encode(nonce),
      'ciphertext': base64Encode(box.cipherText),
      'tag': base64Encode(box.mac.bytes),
    };
  }

  static Future<Uint8List> _decryptWithKeyStatic(
    Map<String, dynamic> record,
    Uint8List key,
  ) async {
    final cipher = aes.AesGcm.with256bits();
    final secretKey = aes.SecretKey(key);
    final box = aes.SecretBox(
      base64Decode(record['ciphertext']),
      nonce: base64Decode(record['nonce']),
      mac: aes.Mac(base64Decode(record['tag'])),
    );
    final clearBytes = await cipher.decrypt(box, secretKey: secretKey);
    return Uint8List.fromList(clearBytes);
  }
}
