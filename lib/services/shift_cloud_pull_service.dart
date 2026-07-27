import 'package:fegh_cloud/fegh_cloud.dart' show FeghPaths;

import '../models/shift.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';

/// Zieht den in der **Verwaltung** gepflegten Dienstplan aus dem kanonischen
/// Cloud-Layout (`FeghPaths.teamSchedulesDir` = `teams/<teamId>/schedules`).
///
/// Read-only: Die Doku schreibt keine Schichten, sie liest nur die eigenen.
/// Gegenstueck zu `TeamShiftSyncService` in der Verwaltung – dieselben Pfade,
/// dasselbe verschluesselte `Shift`-Wire-Format aus `fegh_core`.
class ShiftCloudPullService {
  final HiDriveWebDAVClient webdav;
  final CryptoStorage crypto;
  final FeghPaths paths;

  ShiftCloudPullService({
    required this.webdav,
    required this.crypto,
    required this.paths,
  });

  /// Alle Schichten eines Teams aus der Cloud. Beschaedigte oder fremde Records
  /// werden uebersprungen; bei fehlender/leerer Ablage kommt eine leere Liste.
  Future<List<Shift>> downloadShifts(String teamId) async {
    final dir = paths.teamSchedulesDir(teamId);
    final listRes = await webdav.list(dir);
    if (!listRes.isSuccess || listRes.data == null) return const [];
    final shifts = <Shift>[];
    for (final name in listRes.data!) {
      if (!name.endsWith('.bin')) continue;
      final getRes = await webdav.get('$dir/$name');
      if (!getRes.isSuccess || getRes.data == null) continue;
      try {
        final map = await crypto.decryptJsonFromBytes(getRes.data!);
        shifts.add(Shift.fromJson(map));
      } catch (_) {
        // beschaedigten Record ueberspringen
      }
    }
    return shifts;
  }

  /// Schichten ueber mehrere Teams (Mitarbeiter mit mehreren Team-Zugehoerigkeiten).
  Future<List<Shift>> downloadForTeams(Iterable<String> teamIds) async {
    final all = <Shift>[];
    for (final t in teamIds) {
      if (t.isEmpty) continue;
      all.addAll(await downloadShifts(t));
    }
    return all;
  }
}
