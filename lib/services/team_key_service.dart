import 'dart:convert';
import 'dart:typed_data';
import 'package:eingliederungshilfe_flutter/services/hidrive_webdav_client.dart';
import 'package:eingliederungshilfe_flutter/services/crypto_storage.dart';

/// Verantwortlich für das Laden eines Team-Keys aus HiDrive.
/// Erwarteter Pfad: administration/teams/<teamId>/team-key.bin (verschlüsselt mit Org-MEK)
class TeamKeyService {
  final HiDriveBusinessSync _sync;
  final CryptoStorage _crypto;

  TeamKeyService(this._sync, this._crypto);

  /// Lädt und entschlüsselt den Team-Key. Gibt true zurück, wenn MEK gesetzt wurde.
  Future<bool> loadAndApplyTeamKey(String teamId) async {
    try {
      final path = 'administration/teams/$teamId/team-key.bin';
      final res = await _sync.downloadOrgScopedRecord('administration/teams/$teamId', 'team-key');
      if (!res.isSuccess || res.data == null) {
        return false;
      }

      // Entschlüssele Team-Key (als EncryptedRecord JSON)
      final rec = jsonDecode(utf8.decode(res.data!)) as Map<String, dynamic>;
      final clear = await _crypto.decryptRecord(rec);
      final obj = jsonDecode(utf8.decode(clear)) as Map<String, dynamic>;
      final keyB64 = obj['teamKey'] as String?;
      if (keyB64 == null) return false;
      final key = base64Decode(keyB64);
      if (key.length != 32) return false;

      // Setze externen MEK auf Team-Key
      _crypto.setExternalMEK(key);
      return true;
    } catch (_) {
      return false;
    }
  }
}

