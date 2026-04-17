import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/teilhabeziel.dart';
import '../models/zielmessung.dart';
import '../models/pos_messung.dart';
import 'crypto_storage.dart';
import 'cloud_storage_adapter.dart';

/// Service fuer Wirkungsmessung: Teilhabeziele, GAS-Messungen, POS-Messungen.
///
/// Speichert lokal in SharedPreferences (verschluesselt via App-Keychain).
/// Spaeter koennen die Daten ueber den CloudStorageAdapter synchronisiert werden.
class WirkungsmessungService {
  static const _zieleKey = 'wm_teilhabeziele';
  static const _messungenKey = 'wm_zielmessungen';
  static const _posKey = 'wm_pos_messungen';

  // ── Teilhabeziele ────────────────────────────────────────────────

  Future<List<Teilhabeziel>> loadZiele() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_zieleKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => Teilhabeziel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] loadZiele: $e');
      return [];
    }
  }

  Future<bool> saveZiele(List<Teilhabeziel> ziele) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(ziele.map((z) => z.toJson()).toList());
      await prefs.setString(_zieleKey, json);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] saveZiele: $e');
      return false;
    }
  }

  Future<List<Teilhabeziel>> zieleFuerClient(String clientId) async {
    final alle = await loadZiele();
    return alle.where((z) => z.clientId == clientId).toList();
  }

  Future<bool> addZiel(Teilhabeziel ziel) async {
    final alle = await loadZiele();
    alle.add(ziel);
    return saveZiele(alle);
  }

  Future<bool> updateZiel(Teilhabeziel ziel) async {
    final alle = await loadZiele();
    final idx = alle.indexWhere((z) => z.id == ziel.id);
    if (idx < 0) return false;
    alle[idx] = ziel;
    return saveZiele(alle);
  }

  Future<bool> deleteZiel(String zielId) async {
    final alle = await loadZiele();
    alle.removeWhere((z) => z.id == zielId);
    // Zugehoerige Messungen auch loeschen
    final messungen = await loadMessungen();
    messungen.removeWhere((m) => m.zielId == zielId);
    await saveMessungen(messungen);
    return saveZiele(alle);
  }

  // ── GAS-Messungen ────────────────────────────────────────────────

  Future<List<Zielmessung>> loadMessungen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_messungenKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => Zielmessung.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] loadMessungen: $e');
      return [];
    }
  }

  Future<bool> saveMessungen(List<Zielmessung> messungen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(messungen.map((m) => m.toJson()).toList());
      await prefs.setString(_messungenKey, json);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] saveMessungen: $e');
      return false;
    }
  }

  Future<List<Zielmessung>> messungenFuerZiel(String zielId) async {
    final alle = await loadMessungen();
    final gefiltert = alle.where((m) => m.zielId == zielId).toList();
    gefiltert.sort((a, b) => a.messdatum.compareTo(b.messdatum));
    return gefiltert;
  }

  Future<List<Zielmessung>> messungenFuerClient(String clientId) async {
    final alle = await loadMessungen();
    return alle.where((m) => m.clientId == clientId).toList();
  }

  Future<bool> addMessung(Zielmessung messung) async {
    final alle = await loadMessungen();
    alle.add(messung);
    return saveMessungen(alle);
  }

  Future<bool> deleteMessung(String messungId) async {
    final alle = await loadMessungen();
    alle.removeWhere((m) => m.id == messungId);
    return saveMessungen(alle);
  }

  // ── POS-Messungen ────────────────────────────────────────────────

  Future<List<PosMessung>> loadPosMessungen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_posKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => PosMessung.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] loadPosMessungen: $e');
      return [];
    }
  }

  Future<bool> savePosMessungen(List<PosMessung> messungen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(messungen.map((m) => m.toJson()).toList());
      await prefs.setString(_posKey, json);
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] savePosMessungen: $e');
      return false;
    }
  }

  Future<List<PosMessung>> posMessungenFuerClient(String clientId) async {
    final alle = await loadPosMessungen();
    final gefiltert = alle.where((m) => m.clientId == clientId).toList();
    gefiltert.sort((a, b) => a.messdatum.compareTo(b.messdatum));
    return gefiltert;
  }

  Future<bool> addPosMessung(PosMessung messung) async {
    final alle = await loadPosMessungen();
    alle.add(messung);
    return savePosMessungen(alle);
  }

  Future<bool> updatePosMessung(PosMessung messung) async {
    final alle = await loadPosMessungen();
    final idx = alle.indexWhere((m) => m.id == messung.id);
    if (idx < 0) return false;
    alle[idx] = messung;
    return savePosMessungen(alle);
  }

  Future<bool> deletePosMessung(String messungId) async {
    final alle = await loadPosMessungen();
    alle.removeWhere((m) => m.id == messungId);
    return savePosMessungen(alle);
  }

  // ── Auswertung ──────────────────────────────────────────────────

  /// Durchschnittliche GAS-Bewertung eines Ziels ueber alle Messungen.
  Future<double?> durchschnittGas(String zielId) async {
    final msgs = await messungenFuerZiel(zielId);
    if (msgs.isEmpty) return null;
    final sum = msgs.fold<int>(0, (s, m) => s + m.bewertung.wert);
    return sum / msgs.length;
  }

  /// Prueft ob ein Ziel eine faellige Zwischenmessung braucht (>3 Monate seit letzter).
  Future<bool> zwischenmessungFaellig(String zielId) async {
    final msgs = await messungenFuerZiel(zielId);
    if (msgs.isEmpty) return true; // Keine Messung = Baseline faellig
    final letzte = msgs.last.messdatum;
    final diff = DateTime.now().difference(letzte).inDays;
    return diff > 90;
  }

  // ── Cloud-Sync ──────────────────────────────────────────────────
  //
  // Upload/Download aller Wirkungsdaten als drei verschluesselte Blobs
  // (ziele/gas/pos) in das konfigurierte Cloud-Verzeichnis.
  // Arbeitet mit jedem CloudStorageAdapter (HiDrive, Nextcloud, ...).

  static const _cloudFileZiele = 'wirkung_ziele.bin';
  static const _cloudFileGas = 'wirkung_gas.bin';
  static const _cloudFilePos = 'wirkung_pos.bin';

  /// Verschluesselt und uploadet alle lokalen Wirkungsdaten.
  /// [remoteDir] z.B. `administration/teams/{teamId}/wirkung`.
  Future<bool> syncToCloud({
    required CloudStorageAdapter adapter,
    required String remoteDir,
    CryptoStorage? crypto,
  }) async {
    try {
      final c = crypto ?? CryptoStorage();
      await adapter.createDirectory(remoteDir);

      final ziele = await loadZiele();
      final gas = await loadMessungen();
      final pos = await loadPosMessungen();

      final okZ = await _uploadBlob(adapter, c, '$remoteDir/$_cloudFileZiele',
          'teilhabeziel', {'items': ziele.map((z) => z.toJson()).toList()});
      final okG = await _uploadBlob(adapter, c, '$remoteDir/$_cloudFileGas',
          'zielmessung', {'items': gas.map((m) => m.toJson()).toList()});
      final okP = await _uploadBlob(adapter, c, '$remoteDir/$_cloudFilePos',
          'pos_messung', {'items': pos.map((m) => m.toJson()).toList()});
      return okZ && okG && okP;
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] syncToCloud: $e');
      return false;
    }
  }

  /// Laedt alle Wirkungsdaten aus der Cloud und ersetzt die lokalen.
  /// Strategie: Cloud = Wahrheit (remote wins). Fuer Konflikte koennte
  /// spaeter ein Merge nach `erstelltAm`/`geaendertAm` implementiert werden.
  Future<bool> syncFromCloud({
    required CloudStorageAdapter adapter,
    required String remoteDir,
    CryptoStorage? crypto,
  }) async {
    try {
      final c = crypto ?? CryptoStorage();

      final zJson = await _downloadBlob(adapter, c, '$remoteDir/$_cloudFileZiele');
      if (zJson != null) {
        final list = (zJson['items'] as List)
            .map((e) => Teilhabeziel.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveZiele(list);
      }
      final gJson = await _downloadBlob(adapter, c, '$remoteDir/$_cloudFileGas');
      if (gJson != null) {
        final list = (gJson['items'] as List)
            .map((e) => Zielmessung.fromJson(e as Map<String, dynamic>))
            .toList();
        await saveMessungen(list);
      }
      final pJson = await _downloadBlob(adapter, c, '$remoteDir/$_cloudFilePos');
      if (pJson != null) {
        final list = (pJson['items'] as List)
            .map((e) => PosMessung.fromJson(e as Map<String, dynamic>))
            .toList();
        await savePosMessungen(list);
      }
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[WM] syncFromCloud: $e');
      return false;
    }
  }

  Future<bool> _uploadBlob(
    CloudStorageAdapter adapter,
    CryptoStorage crypto,
    String remotePath,
    String schema,
    Map<String, dynamic> payload,
  ) async {
    final bytes = utf8.encode(jsonEncode(payload));
    final enc = await crypto.encryptRecord(
      plaintext: bytes,
      aad: {'schema': schema, 'kind': 'wirkung-blob'},
    );
    final envelope = Uint8List.fromList(utf8.encode(jsonEncode(enc)));
    return adapter.uploadFile(remotePath, envelope);
  }

  Future<Map<String, dynamic>?> _downloadBlob(
    CloudStorageAdapter adapter,
    CryptoStorage crypto,
    String remotePath,
  ) async {
    final bytes = await adapter.downloadFile(remotePath);
    if (bytes == null) return null;
    final envelope = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    final plain = await crypto.decryptRecord(envelope);
    return jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
  }
}
