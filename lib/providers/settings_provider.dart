import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../services/secure_storage_service.dart';

/// Spezialisierter Provider fuer App-Einstellungen.
class SettingsProvider extends ChangeNotifier {
  final SecureStorageService _storage;
  AppSettings _settings = AppSettings.defaultSettings();
  static const _setupCompletedKey = 'setup_completed';

  SettingsProvider(this._storage);

  AppSettings get settings => _settings;
  bool get setupCompleted => _settings.setupCompleted;

  Future<void> loadSettings() async {
    _settings = await _storage.loadSettings();
    final prefs = await SharedPreferences.getInstance();
    final setupFromPrefs = prefs.getBool(_setupCompletedKey);
    if (setupFromPrefs == true && !_settings.setupCompleted) {
      _settings = _settings.copyWith(setupCompleted: true);
    }
    // Migration: orgId + kein Team → orgAdmin
    if (_settings.organizationId.isNotEmpty &&
        _settings.teamId.isEmpty &&
        _settings.userRole == UserRole.teamMember &&
        _settings.setupCompleted) {
      _settings = _settings.copyWith(userRole: UserRole.orgAdmin);
      _storage.saveSettings(_settings);
    }
    notifyListeners();
  }

  Future<bool> updateSettings(AppSettings newSettings) async {
    try {
      await _storage.saveSettings(newSettings);
      _settings = newSettings;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('[SettingsProvider] updateSettings error: $e');
      return false;
    }
  }

  Future<bool> completeSetup() async {
    try {
      final newSettings = _settings.copyWith(setupCompleted: true);
      final result = await updateSettings(newSettings);
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_setupCompletedKey, true);
      }
      return result;
    } catch (e) {
      debugPrint('[SettingsProvider] completeSetup error: $e');
      return false;
    }
  }

  Future<bool> resetSetup() async {
    try {
      final newSettings = _settings.copyWith(setupCompleted: false);
      final result = await updateSettings(newSettings);
      if (result) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_setupCompletedKey, false);
      }
      return result;
    } catch (e) {
      debugPrint('[SettingsProvider] resetSetup error: $e');
      return false;
    }
  }
}
