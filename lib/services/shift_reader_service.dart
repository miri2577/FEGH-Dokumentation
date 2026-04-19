import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/shift.dart';

/// Read-only Zugriff auf die Dienstplan-Daten.
///
/// Die Verwaltung pflegt den Dienstplan (Schichten), die Doku liest
/// ihn nur — damit die Mitarbeiter:in im Feld ihre eigenen Schichten
/// sieht, ohne in die Verwaltung wechseln zu muessen.
///
/// Beide Apps teilen denselben SharedPreferences-Key `shifts.json`
/// und das gemeinsame [Shift]-Schema aus `fegh_core`. Wird die Liste
/// in der Verwaltung geschrieben und ueber Cloud-Sync ausgetauscht,
/// liest die Doku sie 1:1.
class ShiftReaderService {
  static const _key = 'shifts.json';

  Future<List<Shift>> loadAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return [];
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Shift.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[SHIFT] loadAll failed: $e');
      return [];
    }
  }

  /// Alle Schichten fuer einen Mitarbeiter, sortiert nach Startzeit.
  Future<List<Shift>> loadForEmployee(String employeeId) async {
    final all = await loadAll();
    final mine = all.where((s) => s.employeeId == employeeId).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    return mine;
  }

  /// Die naechsten [limit] noch nicht abgeschlossenen Schichten.
  Future<List<Shift>> upcomingForEmployee(
    String employeeId, {
    int limit = 10,
  }) async {
    final now = DateTime.now();
    final all = await loadForEmployee(employeeId);
    return all
        .where((s) =>
            s.status != ShiftStatus.completed &&
            s.status != ShiftStatus.cancelled &&
            s.endTime.isAfter(now))
        .take(limit)
        .toList();
  }

  /// Alle Schichten eines Tages (Mitarbeiter-bezogen).
  Future<List<Shift>> forDay(String employeeId, DateTime day) async {
    final all = await loadForEmployee(employeeId);
    final key = DateTime(day.year, day.month, day.day);
    return all.where((s) {
      final d = DateTime(s.startTime.year, s.startTime.month, s.startTime.day);
      return d == key;
    }).toList();
  }
}
