import 'dart:convert';
import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// CRUD-Service fuer Rechnungen und Kostentraeger-Empfaenger.
class RechnungService {
  static const _rechnungenKey = 'rechnungen_v1';
  static const _empfaengerKey = 'rechnung_empfaenger_v1';

  // ── Rechnungen ────────────────────────────────────────────────────

  Future<List<Rechnung>> loadRechnungen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_rechnungenKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list.map((e) => Rechnung.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[RECH] loadRechnungen: $e');
      return [];
    }
  }

  Future<bool> saveRechnungen(List<Rechnung> rechnungen) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_rechnungenKey, jsonEncode(rechnungen.map((r) => r.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[RECH] saveRechnungen: $e');
      return false;
    }
  }

  Future<bool> addRechnung(Rechnung r) async {
    final alle = await loadRechnungen();
    alle.add(r);
    return saveRechnungen(alle);
  }

  Future<bool> updateRechnung(Rechnung r) async {
    final alle = await loadRechnungen();
    final idx = alle.indexWhere((x) => x.id == r.id);
    if (idx < 0) return false;
    alle[idx] = r;
    return saveRechnungen(alle);
  }

  Future<bool> deleteRechnung(String id) async {
    final alle = await loadRechnungen();
    alle.removeWhere((x) => x.id == id);
    return saveRechnungen(alle);
  }

  /// Naechste freie Rechnungsnummer im Format YYYY-NNNN.
  Future<String> naechsteRechnungsnummer() async {
    final alle = await loadRechnungen();
    final jahr = DateTime.now().year;
    int maxNr = 0;
    for (final r in alle) {
      final parts = r.rechnungsnummer.split('-');
      if (parts.length == 2 && parts[0] == '$jahr') {
        final nr = int.tryParse(parts[1]) ?? 0;
        if (nr > maxNr) maxNr = nr;
      }
    }
    return '$jahr-${(maxNr + 1).toString().padLeft(4, '0')}';
  }

  // ── Empfaenger (Kostentraeger-Stammdaten) ─────────────────────────

  Future<List<RechnungEmpfaenger>> loadEmpfaenger() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_empfaengerKey);
      if (json == null) return [];
      final list = jsonDecode(json) as List;
      return list
          .map((e) => RechnungEmpfaenger.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) debugPrint('[RECH] loadEmpfaenger: $e');
      return [];
    }
  }

  Future<bool> saveEmpfaenger(List<RechnungEmpfaenger> liste) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_empfaengerKey, jsonEncode(liste.map((e) => e.toJson()).toList()));
      return true;
    } catch (e) {
      if (kDebugMode) debugPrint('[RECH] saveEmpfaenger: $e');
      return false;
    }
  }

  Future<RechnungEmpfaenger?> getEmpfaenger(String id) async {
    final alle = await loadEmpfaenger();
    for (final e in alle) {
      if (e.id == id) return e;
    }
    return null;
  }

  Future<bool> addEmpfaenger(RechnungEmpfaenger e) async {
    final alle = await loadEmpfaenger();
    alle.add(e);
    return saveEmpfaenger(alle);
  }

  Future<bool> updateEmpfaenger(RechnungEmpfaenger e) async {
    final alle = await loadEmpfaenger();
    final idx = alle.indexWhere((x) => x.id == e.id);
    if (idx < 0) return false;
    alle[idx] = e;
    return saveEmpfaenger(alle);
  }

  Future<bool> deleteEmpfaenger(String id) async {
    final alle = await loadEmpfaenger();
    alle.removeWhere((x) => x.id == id);
    return saveEmpfaenger(alle);
  }
}
