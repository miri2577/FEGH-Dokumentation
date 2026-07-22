import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../models/arbeitszeit.dart';
import '../models/mitarbeiter.dart';
import '../models/freizeit_antrag.dart';
import '../models/standort.dart';
import '../models/fahrweg.dart';
import '../models/strecken_cache.dart';
import '../config/developer_mode.dart';
import 'crypto_storage.dart';
import 'hidrive_webdav_client.dart';
import 'file_logger.dart';
import 'team_key_service.dart';
import 'app_logger.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  late final CryptoStorage _cryptoStorage;
  HiDriveBusinessSync? _cloudSync;
  SharedPreferences? _legacyPrefs;
  bool _migrationCompleted = false;

  // UUID-Index: entityId → storage-uuid (vermeidet sequentielles Entschlüsseln beim Update/Delete)
  final Map<String, String> _clientIdToUuid = {};
  final Map<String, String> _appointmentIdToUuid = {};
  final Map<String, String> _arbeitszeitIdToUuid = {};
  final Map<String, String> _mitarbeiterIdToUuid = {};
  final Map<String, String> _standortIdToUuid = {};
  final Map<String, String> _fahrwegIdToUuid = {};
  final Map<String, String> _streckenCacheIdToUuid = {};

  Future<void> initialize({
    String? hidriveUsername,
    String? hidrivePassword,
  }) async {
    // Initialize file logger early for macOS debug visibility
    try {
      await FileLogger().initialize();
      await FileLogger().log('🛠️ SecureStorageService.initialize()');
    } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }
    AppLogger.info('Storage', 'SecureStorageService: Initialisierung startet...');
    AppLogger.info('Storage', 'DeveloperMode.isActive: ${DeveloperMode.isActive}');
    AppLogger.info('Storage', 'DeveloperMode.useKeychain: ${DeveloperMode.useKeychain}');

    if (DeveloperMode.allowSecurityDebugLogs) {
      AppLogger.info('Storage', 'DEV: Entwicklermodus ist AKTIV!');
      AppLogger.info('Storage', 'DEV: Keychain wird ${DeveloperMode.useKeychain ? "verwendet" : "ÜBERSPRUNGEN"}');
    }

    _cryptoStorage = CryptoStorage();

    // Versuche Sync-Passphrase früh zu laden (aus Secure Storage oder Fallback-Datei)
    try {
      final pass = await _loadPersistedSyncPassphrase();
      if (pass != null && pass.isNotEmpty) {
        _cryptoStorage.setExternalPassphrase(pass);
        await FileLogger().log('🔐 Sync-Passphrase geladen');
      }
    } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }

    if (hidriveUsername != null && hidrivePassword != null) {
      // Legacy-Init ohne Orga/Team – nutzt optional Root-Unterordner
      final curr = await loadSettings();
      _cloudSync = HiDriveBusinessSync.legacy(
        username: hidriveUsername,
        password: hidrivePassword,
        rootSubdirectory: curr.rootSubdirectory.isNotEmpty ? curr.rootSubdirectory : null,
      );
    } else {
      _cloudSync = null;
    }

    _legacyPrefs = await SharedPreferences.getInstance();

    if (!_migrationCompleted) {
      await _migrateLegacyData();
      _migrationCompleted = true;
    }
  }

  // ===== Sync-Passphrase Verwaltung =====
  Future<void> setSyncPassphrase(String passphrase, {bool rotateAndResync = true}) async {
    try {
      // Setze Passphrase im CryptoStorage
      _cryptoStorage.setExternalPassphrase(passphrase);
      await _persistSyncPassphrase(passphrase);
      await FileLogger().log('🔐 Sync-Passphrase gesetzt');

      if (rotateAndResync) {
        // Rewrap aller Dateien mit neuer MEK
        await _cryptoStorage.rotateMEK();
        await FileLogger().log('🔐 MEK rotiert (Passphrase aktiv)');

        // Vollständiger Re-Upload aller Records
        await _resyncAllToCloud();
        await FileLogger().log('☁️ Reupload nach Passphrase-Wechsel abgeschlossen');
      }
    } catch (e) {
      await FileLogger().log('❌ Fehler beim Setzen der Sync-Passphrase: $e');
      rethrow;
    }
  }

  Future<void> clearSyncPassphrase() async {
    try {
      _cryptoStorage.setExternalPassphrase(null);
      await _persistSyncPassphrase('');
      await FileLogger().log('🔐 Sync-Passphrase entfernt');
    } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }
  }

  Future<void> _persistSyncPassphrase(String pass) async {
    try {
      // Bevorzugt Secure Storage
      await _cryptoStorage.secure.write(key: 'sync_passphrase', value: pass);
    } catch (e) {
      // Fallback auf Datei im secure-Verzeichnis (nur Dev)
      final dir = await _getSecureDataDir();
      final f = File('${dir.path}/.sync_passphrase');
      await f.writeAsString(pass, flush: true);
    }
  }

  Future<String?> _loadPersistedSyncPassphrase() async {
    try {
      final v = await _cryptoStorage.secure.read(key: 'sync_passphrase');
      if (v != null && v.isNotEmpty) return v;
    } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }
    try {
      final dir = await _getSecureDataDir();
      final f = File('${dir.path}/.sync_passphrase');
      if (await f.exists()) {
        return await f.readAsString();
      }
    } catch (e) { if (kDebugMode) debugPrint("Fehler: $e"); }
    return null;
  }

  Future<void> _migrateLegacyData() async {
    if (_legacyPrefs == null) return;

    // Prüfen ob Migration bereits durchgeführt wurde
    final migrationCompleted = _legacyPrefs?.getBool('migration_completed') ?? false;
    if (migrationCompleted) {
      AppLogger.info('Storage', 'Migration bereits abgeschlossen');
      return;
    }

    // DEBUG: Prüfen was noch in SharedPreferences vorhanden ist
    final clientsJson = _legacyPrefs?.getString('clients');
    final appointmentsJson = _legacyPrefs?.getString('appointments');
    AppLogger.info('Storage', 'DEBUG: Legacy-Klienten: ${clientsJson != null ? "VORHANDEN" : "LEER"}');
    AppLogger.info('Storage', 'DEBUG: Legacy-Termine: ${appointmentsJson != null ? "VORHANDEN" : "LEER"}');

    if (clientsJson != null) {
      final clientsList = json.decode(clientsJson);
      AppLogger.info('Storage', 'DEBUG: ${clientsList.length} Klienten in SharedPreferences gefunden');
    }

    if (appointmentsJson != null) {
      final appointmentsList = json.decode(appointmentsJson);
      AppLogger.info('Storage', 'DEBUG: ${appointmentsList.length} Termine in SharedPreferences gefunden');
    }

    try {
      await _migrateClients();
      await _migrateAppointments();
      await _migrateArbeitszeiten();
      await _migrateSettings();

      // NUR wenn alles erfolgreich war, Legacy-Daten löschen
      await _legacyPrefs?.setBool('migration_completed', true);
      AppLogger.info('Storage', 'Migration zu verschluesselter Speicherung abgeschlossen');

      // Legacy-Daten erst nach erfolgreicher Migration löschen
      await Future.delayed(Duration(seconds: 1));
      await _cleanupLegacyData();

    } catch (e) {
      AppLogger.error('Storage', 'Migration fehlgeschlagen', e);
      AppLogger.warning('Storage', 'Legacy-Daten bleiben erhalten fuer erneuten Versuch');
    }
  }

  Future<void> _migrateClients() async {
    final clientsJson = _legacyPrefs?.getString('clients');
    if (clientsJson == null) {
      AppLogger.info('Storage', 'Keine Legacy-Klienten gefunden');
      return;
    }

    try {
      final List<dynamic> clientsList = json.decode(clientsJson);
      for (final clientJson in clientsList) {
        final client = Client.fromJson(clientJson);

        // Fallback: Bei Keychain-Fehler direkt in Dateisystem speichern
        try {
          await _cryptoStorage.saveJsonEncrypted('client', client.toJson());
        } catch (keystoreError) {
          AppLogger.warning('Storage', 'Keychain-Fehler bei ${client.name}, verwende Fallback');
          // TODO: Fallback-Speicherung ohne Keychain
          await _saveFallbackClient(client);
        }
      }
      AppLogger.info('Storage', '${clientsList.length} Klienten migriert');
    } catch (e) {
      AppLogger.error('Storage', 'Klienten-Migration fehlgeschlagen', e);
      rethrow;
    }
  }

  // Temporärer Fallback ohne Keychain
  Future<void> _saveFallbackClient(Client client) async {
    final dir = await getApplicationSupportDirectory();
    final fallbackDir = Directory('${dir.path}/fallback_data');
    if (!await fallbackDir.exists()) {
      await fallbackDir.create(recursive: true);
    }

    final file = File('${fallbackDir.path}/client_${client.id}.json');
    await file.writeAsString(jsonEncode(client.toJson()));
    AppLogger.info('Storage', 'Fallback-Speicherung: ${client.name}');
  }

  Future<void> _migrateAppointments() async {
    final appointmentsJson = _legacyPrefs?.getString('appointments');
    if (appointmentsJson == null) return;

    try {
      final List<dynamic> appointmentsList = json.decode(appointmentsJson);
      for (final appointmentJson in appointmentsList) {
        final appointment = Appointment.fromJson(appointmentJson);
        await _cryptoStorage.saveJsonEncrypted('appointment', appointment.toJson());
      }
      AppLogger.info('Storage', '${appointmentsList.length} Termine migriert');
    } catch (e) {
      AppLogger.error('Storage', 'Termine-Migration fehlgeschlagen', e);
    }
  }

  Future<void> _migrateArbeitszeiten() async {
    final arbeitszeitenJson = _legacyPrefs?.getString('arbeitszeiten');
    if (arbeitszeitenJson == null) return;

    try {
      final List<dynamic> arbeitszeitenList = json.decode(arbeitszeitenJson);
      for (final arbeitszeitJson in arbeitszeitenList) {
        final arbeitszeit = Arbeitszeit.fromJson(arbeitszeitJson);
        await _cryptoStorage.saveJsonEncrypted('arbeitszeit', arbeitszeit.toJson());
      }
      AppLogger.info('Storage', '${arbeitszeitenList.length} Arbeitszeiten migriert');
    } catch (e) {
      AppLogger.error('Storage', 'Arbeitszeiten-Migration fehlgeschlagen', e);
    }
  }

  Future<void> _migrateSettings() async {
    final settingsJson = _legacyPrefs?.getString('app_settings');
    if (settingsJson == null) return;

    try {
      final settings = AppSettings.fromJson(json.decode(settingsJson));
      await _cryptoStorage.saveJsonEncrypted('settings', settings.toJson());
      AppLogger.info('Storage', 'Einstellungen migriert');
    } catch (e) {
      AppLogger.error('Storage', 'Einstellungen-Migration fehlgeschlagen', e);
    }
  }

  Future<void> _cleanupLegacyData() async {
    if (_legacyPrefs == null) return;

    try {
      await _legacyPrefs?.remove('clients');
      await _legacyPrefs?.remove('appointments');
      await _legacyPrefs?.remove('arbeitszeiten');
      await _legacyPrefs?.remove('app_settings');
      await _legacyPrefs?.remove('email_targets');
      AppLogger.info('Storage', 'Legacy-Daten bereinigt');
    } catch (e) {
      AppLogger.warning('Storage', 'Legacy-Bereinigung teilweise fehlgeschlagen: $e');
    }
  }

  // Clients
  Future<List<Client>> loadClients() async {
    try {
      AppLogger.info('Storage', 'loadClients() startet...');
      final manifest = await _cryptoStorage.loadManifest();
      AppLogger.info('Storage', 'Manifest geladen, ${manifest.entries.length} Eintraege total');

      final clientEntries = manifest.entries.where((e) => e.schema == 'client').toList();
      AppLogger.info('Storage', '${clientEntries.length} Klienten-Eintraege gefunden');

      final clients = <Client>[];
      _clientIdToUuid.clear();
      for (final entry in clientEntries) {
        try {
          AppLogger.info('Storage', 'Lade Klient ${entry.title} (${entry.uuid})');
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          if (data['_deleted'] == true) continue; // geloeschter Record (Tombstone)
          final client = Client.fromJson(data);
          clients.add(client);
          _clientIdToUuid[client.id] = entry.uuid;
          AppLogger.info('Storage', 'Klient geladen: ${client.name}');
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Klient ${entry.uuid}', e);
        }
      }

      AppLogger.info('Storage', '${clients.length} Klienten geladen (verschluesselt)');
      return clients;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Klienten', e);
      return [];
    }
  }

  Future<bool> addClient(Client client) async {
    return await saveClient(client);
  }

  Future<bool> saveClient(Client client, {String? existingUuid}) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('client', client.toJson(),
          existingUuid: existingUuid);
      _clientIdToUuid[client.id] = uuid;

      // Cloud-Sync non-blocking
      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); await _maybeUpdateClientsIndexInCloudAdd(uuid, client); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync Client (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Klient gespeichert (verschluesselt): ${client.name}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des Klienten', e);
      return false;
    }
  }

  Future<bool> updateClient(Client updatedClient) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _clientIdToUuid[updatedClient.id];
      if (targetUuid == null) {
        // Fallback: Scan (nur wenn Index nicht befüllt)
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'client')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final client = Client.fromJson(data);
            if (client.id == updatedClient.id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Noch kein Record vorhanden -> als neuen anlegen.
      if (targetUuid == null) {
        return await saveClient(updatedClient);
      }

      // Denselben Record unter DERSELBEN UUID ueberschreiben statt loeschen+neu
      // anlegen. So bleibt die Identitaet stabil und es entstehen beim Sync auf
      // anderen Geraeten keine Duplikate/„Zombies" (alter Record blieb sonst in
      // der Cloud und wurde dort additiv wieder eingelesen).
      return await saveClient(updatedClient, existingUuid: targetUuid);
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Aktualisieren des Klienten', e);
      return false;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _clientIdToUuid[clientId];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        final clientEntries = manifest.entries.where((e) => e.schema == 'client');
        for (final entry in clientEntries) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final client = Client.fromJson(data);
            if (client.id == clientId) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        // Tombstone statt hartem Delete: Record durch einen Loesch-Marker unter
        // DERSELBEN UUID ersetzen. Propagiert ueber den updatedAt-Sync; auf anderen
        // Geraeten wird der Datensatz beim Laden herausgefiltert (kein „Zombie").
        await _cryptoStorage.saveJsonEncrypted('client', _tombstone(clientId, 'client'),
            existingUuid: targetUuid);
        _clientIdToUuid.remove(clientId);

        // Cloud: den (Tombstone-)Record hochladen statt zu loeschen.
        if (_cloudSync != null) {
          final uuidToSync = targetUuid;
          try { await _syncToCloud(uuidToSync); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Sync Tombstone Client (async) fehlgeschlagen: $e');
          }
        }

        await _deleteClientAppointments(clientId);

        AppLogger.info('Storage', 'Klient geloescht (Tombstone): $clientId');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen des Klienten', e);
      return false;
    }
  }

  // Appointments
  Future<List<Appointment>> loadAppointments() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final appointmentEntries = manifest.entries.where((e) => e.schema == 'appointment').toList();

      final appointments = <Appointment>[];
      _appointmentIdToUuid.clear();
      for (final entry in appointmentEntries) {
        try {
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          if (data['_deleted'] == true) continue; // geloeschter Record (Tombstone)
          final appointment = Appointment.fromJson(data);
          appointments.add(appointment);
          _appointmentIdToUuid[appointment.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Termin ${entry.uuid}', e);
        }
      }

      appointments.sort((a, b) => b.date.compareTo(a.date));
      AppLogger.info('Storage', '${appointments.length} Termine geladen (verschluesselt)');
      return appointments;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Termine', e);
      return [];
    }
  }

  Future<bool> addAppointment(Appointment appointment) async {
    return await saveAppointment(appointment);
  }

  Future<bool> saveAppointment(Appointment appointment, {String? existingUuid}) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('appointment', appointment.toJson(),
          existingUuid: existingUuid);
      _appointmentIdToUuid[appointment.id] = uuid;

      // Cloud-Sync non-blocking: nicht auf Netzwerk warten
      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Termin gespeichert (verschluesselt): ${appointment.clientName}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des Termins', e);
      return false;
    }
  }

  Future<bool> updateAppointment(Appointment updatedAppointment) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _appointmentIdToUuid[updatedAppointment.id];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'appointment')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final appointment = Appointment.fromJson(data);
            if (appointment.id == updatedAppointment.id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Denselben Record unter DERSELBEN UUID ueberschreiben statt loeschen+neu
      // anlegen -> keine Duplikate/„Zombies" beim Mehrgeraete-Sync. (targetUuid
      // null = noch nicht gespeichert -> neuer Record.)
      return await saveAppointment(updatedAppointment, existingUuid: targetUuid);
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Aktualisieren des Termins', e);
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _appointmentIdToUuid[appointmentId];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'appointment')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final appointment = Appointment.fromJson(data);
            if (appointment.id == appointmentId) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        // Tombstone statt hartem Delete (siehe deleteClient).
        await _cryptoStorage.saveJsonEncrypted('appointment', _tombstone(appointmentId, 'appointment'),
            existingUuid: targetUuid);
        _appointmentIdToUuid.remove(appointmentId);

        if (_cloudSync != null) {
          final uuidToSync = targetUuid;
          try { await _syncToCloud(uuidToSync); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Sync Tombstone Termin (async) fehlgeschlagen: $e');
          }
        }

        AppLogger.info('Storage', 'Termin geloescht (Tombstone): $appointmentId');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen des Termins', e);
      return false;
    }
  }

  Future<void> _deleteClientAppointments(String clientId) async {
    final appointments = await loadAppointments();
    final clientAppointments = appointments.where((a) => a.clientId == clientId);

    for (final appointment in clientAppointments) {
      await deleteAppointment(appointment.id);
    }
  }

  // Arbeitszeiten
  Future<List<Arbeitszeit>> loadArbeitszeiten() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final arbeitszeitEntries = manifest.entries.where((e) => e.schema == 'arbeitszeit').toList();

      final arbeitszeiten = <Arbeitszeit>[];
      _arbeitszeitIdToUuid.clear();
      for (final entry in arbeitszeitEntries) {
        try {
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          if (data['_deleted'] == true) continue; // geloeschter Record (Tombstone)
          final arbeitszeit = Arbeitszeit.fromJson(data);
          arbeitszeiten.add(arbeitszeit);
          _arbeitszeitIdToUuid[arbeitszeit.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Arbeitszeit ${entry.uuid}', e);
        }
      }

      AppLogger.info('Storage', '${arbeitszeiten.length} Arbeitszeiten geladen (verschluesselt)');
      return arbeitszeiten;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Arbeitszeiten', e);
      return [];
    }
  }

  Future<bool> addArbeitszeit(Arbeitszeit arbeitszeit, {String? existingUuid}) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('arbeitszeit', arbeitszeit.toJson(),
          existingUuid: existingUuid);
      _arbeitszeitIdToUuid[arbeitszeit.id] = uuid;

      // Cloud-Sync non-blocking
      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync Arbeitszeit (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Arbeitszeit gespeichert (verschluesselt)');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern der Arbeitszeit', e);
      return false;
    }
  }

  // Settings
  Future<AppSettings> loadSettings() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final settingsEntry = manifest.entries.where((e) => e.schema == 'settings').firstOrNull;

      if (settingsEntry != null) {
        final data = await _cryptoStorage.loadJsonDecrypted(settingsEntry.uuid);
        AppLogger.info('Storage', 'Einstellungen geladen (verschluesselt)');
        return AppSettings.fromJson(data);
      } else {
        final defaultSettings = AppSettings.defaultSettings();
        await saveSettings(defaultSettings);
        return defaultSettings;
      }
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Einstellungen', e);
      final defaultSettings = AppSettings.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    }
  }

  Future<bool> saveClients(List<Client> clients) async {
    try {
      AppLogger.info('Storage', 'saveClients() startet mit ${clients.length} Klienten');
      for (final client in clients) {
        AppLogger.info('Storage', 'Speichere Klient: ${client.name}');
        await saveClient(client);
      }
      AppLogger.info('Storage', 'saveClients() erfolgreich abgeschlossen');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'saveClients() Fehler', e);
      return false;
    }
  }

  Future<bool> saveAppointments(List<Appointment> appointments) async {
    try {
      for (final appointment in appointments) {
        await saveAppointment(appointment);
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<String>> loadEmailTargets() async {
    // Aktuell nicht implementiert - später aus Settings
    return [];
  }

  Future<bool> saveEmailTargets(List<String> targets) async {
    // Aktuell nicht implementiert - später in Settings
    return true;
  }

  Future<bool> createArbeitszeitFromAppointment(Appointment appointment) async {
    try {
      final arbeitszeiten = await loadArbeitszeiten();
      final exists = arbeitszeiten.any((az) =>
        az.datum.day == appointment.date.day &&
        az.datum.month == appointment.date.month &&
        az.datum.year == appointment.date.year &&
        az.startzeit.hour == appointment.startTime.hour &&
        az.startzeit.minute == appointment.startTime.minute
      );

      if (exists) {
        return true;
      }

      final arbeitszeit = Arbeitszeit.create(
        datum: appointment.date,
        startzeit: appointment.startTime,
        endzeit: appointment.endTime,
        taetigkeit: 'Kliententermin: ${appointment.clientName}',
        notizen: 'Automatisch erstellt aus Termin\nICF-Bereiche: ${appointment.icfBereiche.join(", ")}\nNotizen: ${appointment.notes}',
      );

      return await addArbeitszeit(arbeitszeit);
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateArbeitszeit(Arbeitszeit arbeitszeit) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _arbeitszeitIdToUuid[arbeitszeit.id];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'arbeitszeit')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final existingArbeitszeit = Arbeitszeit.fromJson(data);
            if (existingArbeitszeit.id == arbeitszeit.id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      // Denselben Record unter DERSELBEN UUID ueberschreiben statt loeschen+neu
      // anlegen -> keine Duplikate/„Zombies" beim Mehrgeraete-Sync.
      return await addArbeitszeit(arbeitszeit, existingUuid: targetUuid);
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteArbeitszeit(String id) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _arbeitszeitIdToUuid[id];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'arbeitszeit')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final arbeitszeit = Arbeitszeit.fromJson(data);
            if (arbeitszeit.id == id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        // Tombstone statt hartem Delete (siehe deleteClient).
        await _cryptoStorage.saveJsonEncrypted('arbeitszeit', _tombstone(id, 'arbeitszeit'),
            existingUuid: targetUuid);
        _arbeitszeitIdToUuid.remove(id);

        if (_cloudSync != null) {
          final uuidToSync = targetUuid;
          try { await _syncToCloud(uuidToSync); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Sync Tombstone Arbeitszeit (async) fehlgeschlagen: $e');
          }
        }

        return true;
      }

      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      AppLogger.info('Storage', 'importAllData() startet...');
      AppLogger.info('Storage', 'Backup-Daten enthalten: ${data.keys.toList()}');

      if (data['clients'] != null) {
        final List<Client> clients = (data['clients'] as List)
            .map((json) => Client.fromJson(json))
            .toList();
        AppLogger.info('Storage', '${clients.length} Klienten aus Backup gefunden');
        await saveClients(clients);
        AppLogger.info('Storage', 'Klienten erfolgreich gespeichert');
      }

      if (data['appointments'] != null) {
        final List<Appointment> appointments = (data['appointments'] as List)
            .map((json) => Appointment.fromJson(json))
            .toList();
        AppLogger.info('Storage', '${appointments.length} Termine aus Backup gefunden');
        await saveAppointments(appointments);
        AppLogger.info('Storage', 'Termine erfolgreich gespeichert');
      }

      if (data['settings'] != null) {
        final AppSettings settings = AppSettings.fromJson(data['settings']);
        await saveSettings(settings);
        AppLogger.info('Storage', 'Einstellungen erfolgreich gespeichert');
      }

      AppLogger.info('Storage', 'importAllData() erfolgreich abgeschlossen');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'importAllData() Fehler', e);
      return false;
    }
  }

  Future<bool> saveSettings(AppSettings settings) async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final existingSettingsEntry = manifest.entries.where((e) => e.schema == 'settings').firstOrNull;

      if (existingSettingsEntry != null) {
        await _cryptoStorage.deleteRecord(existingSettingsEntry.uuid);
      }

      final uuid = await _cryptoStorage.saveJsonEncrypted('settings', settings.toJson());

      // Cloud-Sync non-blocking
      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync Settings (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Einstellungen gespeichert (verschluesselt)');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern der Einstellungen', e);
      return false;
    }
  }

  Future<void> _syncToCloud(String uuid) async {
    if (_cloudSync == null) return;

    try {
      final encryptedData = await _readEncryptedRecord(uuid);

      // Team-basierte Ablage verwenden, falls konfiguriert
      final settings = await loadSettings();
      final hasOrg = settings.organizationId.isNotEmpty;
      final hasTeam = hasOrg && settings.teamId.isNotEmpty;

      if (hasTeam) {
        // Bestimme Datentyp-Verzeichnis anhand des Schemas
        final entry = await _cryptoStorage.getManifestEntry(uuid);
        final dataType = entry != null ? _schemaToDataType(entry.schema) : null;

        if (dataType != null) {
          await _cloudSync!.uploadTeamRecord(dataType, uuid, encryptedData);
          // Clients-Index (Org) aus Team-Perspektive pflegen
          if (entry?.schema == 'client') {
            final json = await _cryptoStorage.loadJsonDecrypted(uuid);
            await _maybeUpdateClientsIndexInCloudAdd(uuid, Client.fromJson(json));
          }
        } else {
          // Fallback auf Legacy-Ablage
          await _cloudSync!.uploadEncryptedRecord(uuid, encryptedData);
        }
      } else if (hasOrg) {
        // Admin/Organisationsebene ohne Team
        final entry = await _cryptoStorage.getManifestEntry(uuid);
        if (entry != null) {
          final json = await _cryptoStorage.loadJsonDecrypted(uuid);
          final scopedDir = _orgScopedDirFor(entry.schema, json);
          if (scopedDir != null) {
            await _cloudSync!.uploadOrgScopedRecord(scopedDir, uuid, encryptedData);
            // Falls Admin Clients ändern sollte (selten), Index pflegen
            if (entry.schema == 'client') {
              final settings = await loadSettings();
              final teamId = settings.teamId;
              final cli = Client.fromJson(json);
              if (teamId.isNotEmpty) {
                await _maybeUpdateClientsIndexInCloudAdd(uuid, cli);
              }
            }
          } else {
            // Fallback: pauschal in administration
            await _cloudSync!.uploadOrgRecord('administration', uuid, encryptedData);
          }
        } else {
          await _cloudSync!.uploadEncryptedRecord(uuid, encryptedData);
        }
      } else {
        // Legacy/ohne Team: direkt in den Sync-Root
        await _cloudSync!.uploadEncryptedRecord(uuid, encryptedData);
      }
    } catch (e) {
      AppLogger.warning('Storage', 'Cloud-Sync fehlgeschlagen fuer $uuid: $e');
    }
  }

  Future<Uint8List> _readEncryptedRecord(String uuid) async {
    final dir = await _getSecureDataDir();
    final file = File('${dir.path}/$uuid.bin');
    return file.readAsBytes();
  }

  Future<Directory> _getSecureDataDir() async {
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/secure');
    if (!(await d.exists())) await d.create(recursive: true);
    return d;
  }

  Future<bool> syncFromCloud() async {
    if (_cloudSync == null) return false;

    try {
      final settings = await loadSettings();
      final hasOrg = settings.organizationId.isNotEmpty;
      final hasTeam = hasOrg && settings.teamId.isNotEmpty;

      List<String> remoteUuids = [];
      final Map<String, String> orgDownloadDirs = {}; // uuid -> scoped dir
      if (hasTeam) {
        final types = <String>['clients', 'schedules', 'worktime'];
        for (final t in types) {
          final list = await _cloudSync!.listTeamRecords(t);
          if (list.isSuccess && list.data != null) {
            remoteUuids.addAll(list.data!);
          }
        }
        // Eindeutig machen
        remoteUuids = remoteUuids.toSet().toList();
      } else if (hasOrg) {
        // 1) Administration (ungescoped)
        final adminList = await _cloudSync!.listOrgRecords('administration');
        if (adminList.isSuccess && adminList.data != null) {
          for (final id in adminList.data!) {
            remoteUuids.add(id);
            orgDownloadDirs[id] = 'administration';
          }
        }

        // 2) Employees: Kombination aus lokal bekannten IDs, Index und Cloud-Discovery (Shallow)
        final mitarbeiter = await loadMitarbeiter();
        final empIds = mitarbeiter.map((m) => m.id).toSet();

        final remoteEmpDirs = await _cloudSync!.listOrgDirectories('employees');
        if (remoteEmpDirs.isSuccess && remoteEmpDirs.data != null) {
          empIds.addAll(remoteEmpDirs.data!);
        }

        final indexIds = await _loadEmployeesIndexFromCloud();
        empIds.addAll(indexIds);

        for (final empId in empIds) {
          // profile
          final profileList = await _cloudSync!.listOrgScopedRecords('employees/$empId/profile');
          if (profileList.isSuccess && profileList.data != null) {
            for (final id in profileList.data!) {
              remoteUuids.add(id);
              orgDownloadDirs[id] = 'employees/$empId/profile';
            }
          }
          // vacation
          final vacList = await _cloudSync!.listOrgScopedRecords('employees/$empId/vacation');
          if (vacList.isSuccess && vacList.data != null) {
            for (final id in vacList.data!) {
              remoteUuids.add(id);
              orgDownloadDirs[id] = 'employees/$empId/vacation';
            }
          }
        }

        // 3) Clients: aus Clients-Index (enthält uuid und teamId)
        final clientsIndex = await _loadClientsIndexFromCloud();
        final clientEntries = (clientsIndex['entries'] as List?)?.cast<Map<String, dynamic>>() ?? const <Map<String, dynamic>>[];
        for (final e in clientEntries) {
          final cuid = e['uuid'] as String?;
          final teamId = e['teamId'] as String?;
          if (cuid != null && cuid.isNotEmpty && teamId != null && teamId.isNotEmpty) {
            remoteUuids.add(cuid);
            orgDownloadDirs[cuid] = 'teams/$teamId/clients';
          }
        }
        remoteUuids = remoteUuids.toSet().toList();
      } else {
        final result = await _cloudSync!.listRemoteRecords();
        if (!result.isSuccess) return false;
        remoteUuids = result.data ?? [];
      }
      final localManifest = await _cryptoStorage.loadManifest();
      final localUuids = localManifest.entries.map((e) => e.uuid).toSet();

      int syncedCount = 0;

      for (final uuid in remoteUuids) {
        try {
          // Wähle Download-Methode: Team-basiert / Orga-basiert wenn möglich
          var downloadResult = await _cloudSync!.downloadEncryptedRecord(uuid);
          if (hasTeam) {
            // Datentyp hier noch unbekannt – in den bekannten Typ-Ordnern versuchen
            for (final t in const ['clients', 'schedules', 'worktime']) {
              final tryRes = await _cloudSync!.downloadTeamRecord(t, uuid);
              if (tryRes.isSuccess && tryRes.data != null) {
                downloadResult = tryRes;
                break;
              }
            }
          } else if (hasOrg) {
            final scoped = orgDownloadDirs[uuid];
            if (scoped != null) {
              final tryRes = await _cloudSync!.downloadOrgScopedRecord(scoped, uuid);
              if (tryRes.isSuccess && tryRes.data != null) downloadResult = tryRes;
            } else {
              final tryRes = await _cloudSync!.downloadOrgRecord('administration', uuid);
              if (tryRes.isSuccess && tryRes.data != null) downloadResult = tryRes;
            }
          }
          if (!(downloadResult.isSuccess && downloadResult.data != null)) continue;

          // Remote-Record entschluesseln OHNE die lokale Datei zu ueberschreiben,
          // damit vor dem Schreiben geprueft werden kann, ob der Remote neuer ist.
          final Map<String, dynamic> remoteData;
          try {
            remoteData = await _cryptoStorage.decryptJsonFromBytes(downloadResult.data!);
          } catch (e) {
            continue; // korrupt oder mit fremdem Schluessel verschluesselt
          }
          final schema = _determineSchema(remoteData);
          final remoteTs = _recordUpdatedAt(remoteData);

          // Entscheiden: neu, geaendert (Remote strikt neuer) oder ueberspringen.
          final isNew = !localUuids.contains(uuid);
          bool isNewer = false;
          if (!isNew && remoteTs != null) {
            try {
              final localTs = _recordUpdatedAt(await _cryptoStorage.loadJsonDecrypted(uuid));
              isNewer = localTs == null || remoteTs.isAfter(localTs);
            } catch (_) {
              isNewer = true; // lokal nicht lesbar -> Remote uebernehmen
            }
          }
          if (!isNew && !isNewer) continue; // lokal ist aktuell/neuer -> behalten

          final dir = await _getSecureDataDir();
          await File('${dir.path}/$uuid.bin').writeAsBytes(downloadResult.data!);

          await _updateManifest((m) {
            final entry = ManifestEntry(
              uuid: uuid,
              schema: schema,
              title: _extractTitle(remoteData, schema),
              updatedAt: remoteTs ?? DateTime.now().toUtc(),
            );
            final idx = m.entries.indexWhere((e) => e.uuid == uuid);
            if (idx >= 0) { m.entries[idx] = entry; } else { m.entries.add(entry); }
          });
          // ID->UUID-Index pflegen, damit spaetere Updates den Record wiederfinden.
          _reindexAfterSync(schema, remoteData, uuid);
          syncedCount++;
        } catch (e) {
          AppLogger.warning('Storage', 'Sync fehlgeschlagen fuer $uuid: $e');
        }
      }

      AppLogger.info('Storage', '$syncedCount Datensaetze von Cloud synchronisiert');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Cloud-Sync fehlgeschlagen', e);
      return false;
    }
  }

  /// Record-Zeitstempel (updatedAt) aus dem entschluesselten JSON – fuer den
  /// Aenderungs-Abgleich beim Sync. Null, wenn nicht vorhanden/parsebar.
  DateTime? _recordUpdatedAt(Map<String, dynamic> data) {
    final v = data['updatedAt'];
    return v is String ? DateTime.tryParse(v) : null;
  }

  /// Loesch-Marker (Tombstone): ersetzt beim Loeschen den Record-Inhalt, damit die
  /// Loeschung ueber den updatedAt-Sync propagiert und auf anderen Geraeten beim
  /// Laden herausgefiltert wird. Enthaelt KEINE personenbezogenen Daten mehr.
  Map<String, dynamic> _tombstone(String id, String schema) => {
        'id': id,
        '_schema': schema, // damit der Pull den Tombstone dem richtigen Typ zuordnet
        '_deleted': true,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };

  /// Haelt den ID->UUID-Index nach einem Sync aktuell, damit spaetere Update-/
  /// Delete-Aufrufe den frisch geladenen Record ohne Voll-Scan wiederfinden.
  void _reindexAfterSync(String schema, Map<String, dynamic> data, String uuid) {
    if (data['_deleted'] == true) return; // Tombstone nicht in den aktiven Index
    final id = data['id'] as String?;
    if (id == null) return;
    switch (schema) {
      case 'client':
        _clientIdToUuid[id] = uuid;
        break;
      case 'appointment':
        _appointmentIdToUuid[id] = uuid;
        break;
      case 'arbeitszeit':
        _arbeitszeitIdToUuid[id] = uuid;
        break;
    }
  }

  String? _schemaToDataType(String schema) {
    switch (schema) {
      case 'client':
        return 'clients';
      case 'appointment':
        return 'schedules';
      case 'arbeitszeit':
        return 'worktime';
      // Folgende Schemas werden vorerst im Root (Legacy) abgelegt
      case 'mitarbeiter':
      case 'freizeit_antrag':
      case 'settings':
      default:
        return null;
    }
  }

  String? _schemaToOrgDataType(String schema) {
    switch (schema) {
      case 'mitarbeiter':
        return 'employees';
      case 'freizeit_antrag':
        // Urlaubs-/Freizeit-Anträge werden organisatorisch i. d. R. dem Mitarbeiterbereich zugeordnet
        return 'employees';
      case 'settings':
        return 'administration';
      default:
        return null;
    }
  }

  /// Ermittelt den Organisations-Unterordner für ein Objekt basierend auf Schema und JSON-Inhalt
  /// Beispiel:
  ///  - mitarbeiter -> employees/<id>/profile
  ///  - freizeit_antrag -> employees/<mitarbeiterId>/vacation
  ///  - settings -> administration
  String? _orgScopedDirFor(String schema, Map<String, dynamic> json) {
    switch (schema) {
      case 'mitarbeiter':
        final id = json['id'] as String?;
        if (id == null || id.isEmpty) return null;
        return 'employees/$id/profile';
      case 'freizeit_antrag':
        final empId = json['mitarbeiterId'] as String?;
        if (empId == null || empId.isEmpty) return null;
        return 'employees/$empId/vacation';
      case 'settings':
        return 'administration';
      default:
        return null;
    }
  }

  String _determineSchema(Map<String, dynamic> data) {
    if (data['_schema'] is String) return data['_schema'] as String; // Tombstone/expliziter Marker
    if (data.containsKey('name') && data.containsKey('berufsgruppe')) return 'client';
    if (data.containsKey('clientId') && data.containsKey('date')) return 'appointment';
    if (data.containsKey('datum') && data.containsKey('startzeit')) return 'arbeitszeit';
    return 'unknown';
  }

  String _extractTitle(Map<String, dynamic> obj, String schema) {
    switch (schema) {
      case 'client':
        return obj['name'] ?? 'Unbekannter Klient';
      case 'appointment':
        return '${obj['clientName']} - ${obj['date']}';
      case 'arbeitszeit':
        return obj['taetigkeit'] ?? 'Arbeitszeit';
      default:
        return obj['title'] ?? obj['name'] ?? 'Unbekannt';
    }
  }

  Future<void> _updateManifest(void Function(Manifest) updateFn) async {
    final manifest = await _cryptoStorage.loadManifest();
    updateFn(manifest);
    await _saveManifest(manifest);
  }

  Future<void> _saveManifest(Manifest manifest) async {
    final jsonStr = jsonEncode(manifest.toJson());
    final rec = await _cryptoStorage.encryptRecord(
      plaintext: utf8.encode(jsonStr),
      aad: {'type': 'manifest', 'version': 1}
    );

    final dir = await _getSecureDataDir();
    final manifestFile = File('${dir.path}/manifest.json.enc');
    await manifestFile.writeAsString(jsonEncode(rec), flush: true);
  }

  Future<bool> clearAllData() async {
    try {
      // 1. Crypto-Erasure: MEK + verschlüsselte Dateien löschen
      await _cryptoStorage.cryptoErasure();

      // 2. UUID-Index-Maps leeren (sonst bleiben stale Referenzen)
      _clientIdToUuid.clear();
      _appointmentIdToUuid.clear();
      _arbeitszeitIdToUuid.clear();
      _mitarbeiterIdToUuid.clear();
      _standortIdToUuid.clear();
      _fahrwegIdToUuid.clear();
      _streckenCacheIdToUuid.clear();

      // 3. Legacy SharedPreferences komplett leeren (verhindert Re-Migration)
      if (_legacyPrefs != null) {
        await _legacyPrefs!.clear();
      }
      _migrationCompleted = true; // Keine Re-Migration nach Löschung

      // 4. Cloud-Daten löschen
      if (_cloudSync != null) {
        try {
          final result = await _cloudSync!.listRemoteRecords();
          if (result.isSuccess && result.data != null) {
            for (final uuid in result.data!) {
              await _cloudSync!.deleteRemoteRecord(uuid);
            }
          }
        } catch (cloudError) {
          AppLogger.warning('Storage', 'Cloud-Löschung fehlgeschlagen: $cloudError');
        }
      }

      AppLogger.info('Storage', 'Alle Daten geloescht (Crypto-Erasure + SharedPrefs + UUID-Maps)');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen aller Daten', e);
      return false;
    }
  }

  Future<void> rotateMasterKey() async {
    try {
      await _cryptoStorage.rotateMEK();

      if (_cloudSync != null) {
        await _resyncAllToCloud();
      }

      AppLogger.info('Storage', 'Master Key rotiert');
    } catch (e) {
      AppLogger.error('Storage', 'Key-Rotation fehlgeschlagen', e);
      rethrow;
    }
  }

  Future<void> _resyncAllToCloud() async {
    if (_cloudSync == null) return;

    final manifest = await _cryptoStorage.loadManifest();
    for (final entry in manifest.entries) {
      await _syncToCloud(entry.uuid);
    }
  }

  Future<Map<String, dynamic>> exportAllData() async {
    final clients = await loadClients();
    final appointments = await loadAppointments();
    final arbeitszeiten = await loadArbeitszeiten();
    final settings = await loadSettings();

    return {
      'clients': clients.map((c) => c.toJson()).toList(),
      'appointments': appointments.map((a) => a.toJson()).toList(),
      'arbeitszeiten': arbeitszeiten.map((a) => a.toJson()).toList(),
      'settings': settings.toJson(),
      'exportDate': DateTime.now().toIso8601String(),
      'version': '3.0.0',
      'encrypted': true,
    };
  }

  // Mitarbeiter Methods
  Future<List<Mitarbeiter>> loadMitarbeiter() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final mitarbeiterEntries = manifest.entries.where((e) => e.schema == 'mitarbeiter').toList();
      final List<Mitarbeiter> mitarbeiter = [];
      _mitarbeiterIdToUuid.clear();

      for (final entry in mitarbeiterEntries) {
        try {
          final json = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          final m = Mitarbeiter.fromJson(json);
          mitarbeiter.add(m);
          _mitarbeiterIdToUuid[m.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Mitarbeiter ${entry.uuid}', e);
        }
      }

      AppLogger.info('Storage', '${mitarbeiter.length} Mitarbeiter geladen');
      return mitarbeiter;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Mitarbeiter', e);
      return [];
    }
  }

  Future<bool> addMitarbeiter(Mitarbeiter mitarbeiter) async {
    return await saveMitarbeiter(mitarbeiter);
  }

  Future<bool> saveMitarbeiter(Mitarbeiter mitarbeiter) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('mitarbeiter', mitarbeiter.toJson());
      _mitarbeiterIdToUuid[mitarbeiter.id] = uuid;
      AppLogger.info('Storage', 'Mitarbeiter ${mitarbeiter.vollstaendigerName} gespeichert');
      await _maybeUpdateEmployeesIndexInCloud();
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern von Mitarbeiter', e);
      return false;
    }
  }

  Future<bool> updateMitarbeiter(Mitarbeiter updatedMitarbeiter) async {
    return await saveMitarbeiter(updatedMitarbeiter);
  }

  Future<bool> deleteMitarbeiter(String mitarbeiterId) async {
    try {
      // UUID-Index nutzen statt sequentielles Scannen
      String? targetUuid = _mitarbeiterIdToUuid[mitarbeiterId];
      if (targetUuid == null) {
        // Fallback: Scan
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'mitarbeiter')) {
          try {
            final json = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final mitarbeiter = Mitarbeiter.fromJson(json);
            if (mitarbeiter.id == mitarbeiterId) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        _mitarbeiterIdToUuid.remove(mitarbeiterId);
        AppLogger.info('Storage', 'Mitarbeiter $mitarbeiterId geloescht');
        await _maybeUpdateEmployeesIndexInCloud();
        return true;
      }

      AppLogger.error('Storage', 'Mitarbeiter $mitarbeiterId nicht gefunden');
      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen von Mitarbeiter', e);
      return false;
    }
  }

  Future<void> _maybeUpdateEmployeesIndexInCloud() async {
    if (_cloudSync == null) return;
    try {
      final settings = await loadSettings();
      final isAdminMode = settings.organizationId.isNotEmpty && settings.teamId.isEmpty;
      if (!isAdminMode) return;

      // Sammle alle bekannten Mitarbeiter-IDs
      final mitarbeiter = await loadMitarbeiter();
      final ids = mitarbeiter.map((m) => m.id).toSet().toList()..sort();

      final indexJson = {
        'version': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'employees': ids,
      };

      final rec = await _cryptoStorage.encryptRecord(
        plaintext: utf8.encode(jsonEncode(indexJson)),
        aad: {'type': 'employees-index', 'version': 1},
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rec)));
      await _cloudSync!.uploadOrgRecord('administration', 'employees-index', bytes);
      AppLogger.info('Storage', 'Employees-Index in Cloud aktualisiert (${ids.length} IDs)');
    } catch (e) {
      AppLogger.warning('Storage', 'Konnte Employees-Index nicht aktualisieren: $e');
    }
  }

  Future<Set<String>> _loadEmployeesIndexFromCloud() async {
    final result = <String>{};
    if (_cloudSync == null) return result;
    try {
      final dl = await _cloudSync!.downloadOrgRecord('administration', 'employees-index');
      if (!dl.isSuccess || dl.data == null) return result;

      final rec = jsonDecode(utf8.decode(dl.data!)) as Map<String, dynamic>;
      final pt = await _cryptoStorage.decryptRecord(rec);
      final map = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
      final list = (map['employees'] as List?)?.cast<String>() ?? const <String>[];
      result.addAll(list);
      AppLogger.info('Storage', 'Employees-Index geladen (${result.length} IDs)');
    } catch (e) {
      AppLogger.warning('Storage', 'Employees-Index konnte nicht geladen werden: $e');
    }
    return result;
  }

  // ===== Clients-Index (Admin Discovery über Teams) =====
  Future<void> _maybeUpdateClientsIndexInCloudAdd(String uuid, Client client) async {
    if (_cloudSync == null) return;
    try {
      final settings = await loadSettings();
      final isTeamMode = settings.organizationId.isNotEmpty && settings.teamId.isNotEmpty;
      if (!isTeamMode) return; // Index wird aus Team-Perspektive gepflegt

      final index = await _loadClientsIndexFromCloud();
      final entries = (index['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];

      final existingIdx = entries.indexWhere((e) => e['uuid'] == uuid);
      final entry = {
        'uuid': uuid,
        'clientId': client.id,
        'teamId': settings.teamId,
        'title': client.name,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
      };
      if (existingIdx >= 0) {
        entries[existingIdx] = entry;
      } else {
        entries.add(entry);
      }

      final newIndex = {
        'version': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'entries': entries,
      };

      final rec = await _cryptoStorage.encryptRecord(
        plaintext: utf8.encode(jsonEncode(newIndex)),
        aad: {'type': 'clients-index', 'version': 1},
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rec)));
      await _cloudSync!.uploadOrgRecord('administration', 'clients-index', bytes);
      AppLogger.info('Storage', 'Clients-Index aktualisiert (Add/Update): ${client.name}');
    } catch (e) {
      AppLogger.warning('Storage', 'Clients-Index Update fehlgeschlagen: $e');
    }
  }

  Future<void> _clientsIndexRemove(String uuid) async {
    if (_cloudSync == null) return;
    try {
      final index = await _loadClientsIndexFromCloud();
      final entries = (index['entries'] as List?)?.cast<Map<String, dynamic>>() ?? <Map<String, dynamic>>[];
      final filtered = entries.where((e) => e['uuid'] != uuid).toList();

      final newIndex = {
        'version': 1,
        'updatedAt': DateTime.now().toUtc().toIso8601String(),
        'entries': filtered,
      };

      final rec = await _cryptoStorage.encryptRecord(
        plaintext: utf8.encode(jsonEncode(newIndex)),
        aad: {'type': 'clients-index', 'version': 1},
      );
      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(rec)));
      await _cloudSync!.uploadOrgRecord('administration', 'clients-index', bytes);
      AppLogger.info('Storage', 'Clients-Index aktualisiert (Remove): $uuid');
    } catch (e) {
      AppLogger.warning('Storage', 'Clients-Index Remove fehlgeschlagen: $e');
    }
  }

  Future<Map<String, dynamic>> _loadClientsIndexFromCloud() async {
    final empty = {'version': 1, 'updatedAt': null, 'entries': <Map<String, dynamic>>[]};
    if (_cloudSync == null) return empty;
    try {
      final dl = await _cloudSync!.downloadOrgRecord('administration', 'clients-index');
      if (!dl.isSuccess || dl.data == null) return empty;
      final rec = jsonDecode(utf8.decode(dl.data!)) as Map<String, dynamic>;
      final pt = await _cryptoStorage.decryptRecord(rec);
      final map = jsonDecode(utf8.decode(pt)) as Map<String, dynamic>;
      return map;
    } catch (e) {
      return empty;
    }
  }

  // FreizeitAntrag Methods
  Future<List<FreizeitAntrag>> loadFreizeitAntraege() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final antragEntries = manifest.entries.where((e) => e.schema == 'freizeit_antrag').toList();
      final List<FreizeitAntrag> antraege = [];

      for (final entry in antragEntries) {
        try {
          final json = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          antraege.add(FreizeitAntrag.fromJson(json));
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von FreizeitAntrag ${entry.uuid}', e);
        }
      }

      AppLogger.info('Storage', '${antraege.length} FreizeitAntraege geladen');
      return antraege;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der FreizeitAntraege', e);
      return [];
    }
  }

  Future<bool> addFreizeitAntrag(FreizeitAntrag antrag) async {
    return await saveFreizeitAntrag(antrag);
  }

  Future<bool> saveFreizeitAntrag(FreizeitAntrag antrag) async {
    try {
      await _cryptoStorage.saveJsonEncrypted('freizeit_antrag', antrag.toJson());
      AppLogger.info('Storage', 'FreizeitAntrag ${antrag.typDisplayName} gespeichert');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern von FreizeitAntrag', e);
      return false;
    }
  }

  Future<bool> updateFreizeitAntrag(FreizeitAntrag updatedAntrag) async {
    return await saveFreizeitAntrag(updatedAntrag);
  }

  Future<bool> deleteFreizeitAntrag(String antragId) async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final antragEntries = manifest.entries.where((e) => e.schema == 'freizeit_antrag');

      String? targetUuid;
      for (final entry in antragEntries) {
        try {
          final json = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          final antrag = FreizeitAntrag.fromJson(json);
          if (antrag.id == antragId) {
            targetUuid = entry.uuid;
            break;
          }
        } catch (e) {
          continue;
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        AppLogger.info('Storage', 'FreizeitAntrag $antragId geloescht');
        return true;
      }

      AppLogger.error('Storage', 'FreizeitAntrag $antragId nicht gefunden');
      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen von FreizeitAntrag', e);
      return false;
    }
  }

  // Current User Methods
  Future<bool> saveCurrentUser(Mitarbeiter user) async {
    try {
      await _cryptoStorage.saveJsonEncrypted('current_user', user.toJson());
      AppLogger.info('Storage', 'Benutzerprofil gespeichert: ${user.vollstaendigerName}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des Benutzerprofils', e);
      return false;
    }
  }

  Future<Mitarbeiter?> loadCurrentUser() async {
    try {
      final json = await _cryptoStorage.loadJsonDecrypted('current_user');
      final user = Mitarbeiter.fromJson(json);
      AppLogger.info('Storage', 'Benutzerprofil geladen: ${user.vollstaendigerName}');
      return user;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden des Benutzerprofils', e);
      return null;
    }
  }

  // Cloud-Sync Verwaltung
  Future<void> initializeCloudSync(String username, String password) async {
    _cloudSync?.dispose();
    if (username.isNotEmpty && password.isNotEmpty) {
      final s = await loadSettings();
      final newCloudSync = HiDriveBusinessSync.legacy(
        username: username,
        password: password,
        rootSubdirectory: s.rootSubdirectory.isNotEmpty ? s.rootSubdirectory : null,
      );

      // Test connection before setting
      final testResult = await newCloudSync.testConnection();
      if (testResult.isSuccess) {
        _cloudSync = newCloudSync;
        AppLogger.info('Storage', 'Cloud-Sync initialisiert fuer: $username (Legacy)');
      } else {
        newCloudSync.dispose();
        throw Exception('HiDrive-Verbindung fehlgeschlagen: ${testResult.error}');
      }
    }
  }

  // Neue Multi-Team Cloud-Sync Initialisierung
  Future<void> initializeMultiTeamCloudSync(AppSettings settings) async {
    _cloudSync?.dispose();

    final username = settings.hidriveUsername;
    final password = settings.hidrivePassword;
    final organizationId = settings.organizationId;
    final teamId = settings.teamId;

    if (username.isNotEmpty && password.isNotEmpty && organizationId.isNotEmpty) {
      HiDriveBusinessSync newCloudSync;

      if (teamId.isNotEmpty) {
        // Team-spezifischer Zugriff
        newCloudSync = HiDriveBusinessSync.forTeam(
          username: username,
          password: password,
          organizationId: organizationId,
          teamId: teamId,
          rootSubdirectory: settings.rootSubdirectory.isNotEmpty ? settings.rootSubdirectory : null,
        );
        AppLogger.info('Storage', 'Initialisiere Team-Sync fuer Organisation: $organizationId, Team: $teamId');
        await FileLogger().log('☁️ 🏗️ Init Team-Sync org=$organizationId team=$teamId');
      } else {
        // Admin-Zugriff (alle Teams der Organisation)
        newCloudSync = HiDriveBusinessSync.forAdmin(
          username: username,
          password: password,
          organizationId: organizationId,
          rootSubdirectory: settings.rootSubdirectory.isNotEmpty ? settings.rootSubdirectory : null,
        );
        AppLogger.info('Storage', 'Initialisiere Admin-Sync fuer Organisation: $organizationId');
        await FileLogger().log('☁️ 👑 Init Admin-Sync org=$organizationId');
      }

      // Test connection before setting
      final testResult = await newCloudSync.testConnection();
      if (testResult.isSuccess) {
        _cloudSync = newCloudSync;

        // Setup Multi-Team Ordnerstruktur
        final setupResult = await newCloudSync.setupRemoteDirectory();
        if (setupResult.isSuccess) {
          AppLogger.info('Storage', 'Multi-Team Cloud-Sync erfolgreich initialisiert fuer: $username');
          await FileLogger().log('☁️ ✅ Cloud-Sync initialisiert und Ordnerstruktur bereit');
          if (teamId.isNotEmpty) {
            AppLogger.info('Storage', 'Team-Ordnerstruktur bereit: /organizations/$organizationId/teams/$teamId/');
            await FileLogger().log('☁️ 📁 Team-Ordner bereit: organizations/$organizationId/teams/$teamId');
          } else {
            AppLogger.info('Storage', 'Admin-Ordnerstruktur bereit: /organizations/$organizationId/');
            await FileLogger().log('☁️ 📁 Admin-Ordner bereit: organizations/$organizationId');
          }
        } else {
          AppLogger.warning('Storage', 'Ordner-Setup fehlgeschlagen: ${setupResult.error}');
          await FileLogger().log('☁️ ⚠️ Ordner-Setup fehlgeschlagen: ${setupResult.error}');
        }
      } else {
        newCloudSync.dispose();
        throw Exception('HiDrive-Verbindung fehlgeschlagen: ${testResult.error}');
      }

      // Rollen‑Policy aus HiDrive laden und ggf. Team erzwingen
      try {
        await _applyRolesPolicy(username, password, organizationId);
      } catch (e) {
        await FileLogger().log('⚠️ Rollen‑Policy konnte nicht angewendet werden: $e');
      }

      // Falls Team-Modus aktiv: Versuche Team-Key zu laden und anzuwenden
      if (teamId.isNotEmpty) {
        try {
          final loaded = await TeamKeyService(_cloudSync!, _cryptoStorage).loadAndApplyTeamKey(teamId);
          await FileLogger().log(loaded
              ? '🔐 Team-Key geladen und angewendet'
              : 'ℹ️ Kein Team-Key gefunden/angewendet');
        } catch (e) {
          await FileLogger().log('⚠️ Team-Key Fehler: $e');
        }
      }
    } else if (username.isNotEmpty && password.isNotEmpty) {
      // Fallback auf Legacy-Modus wenn Organisation nicht konfiguriert
      await initializeCloudSync(username, password);
    }
  }

  Future<void> _applyRolesPolicy(String username, String password, String organizationId) async {
    try {
      // Settings lesen (u. a. Root‑Unterordner)
      final s = await loadSettings();
      final rootSub = s.rootSubdirectory.isNotEmpty ? s.rootSubdirectory : null;
      // WebDAV‑Client direkt verwenden (DeveloperMode kann Pinning umgehen)
      final adminBase = HiDriveConfig.getAdministrationPath(
        username,
        organizationId,
        rootSubdirectory: rootSub,
      );
      final client = HiDriveWebDAVClient(
        baseUrl: adminBase,
        username: username,
        password: password,
        certificatePins: HiDriveConfig.certificatePins,
      );
      final res = await client.get('users/roles.json');
      if (!res.isSuccess || res.data == null) {
        AppLogger.info('Storage', 'Rollen-Policy: keine roles.json gefunden');
        return;
      }
      final jsonStr = utf8.decode(res.data!);
      final obj = jsonDecode(jsonStr) as Map<String, dynamic>;
      final users = (obj['users'] as List?) ?? const [];
      String? role;
      List<String> teams = [];
      for (final u in users) {
        if (u is Map<String, dynamic>) {
          final id = (u['id'] ?? '').toString().trim().toLowerCase();
          if (id == username.toLowerCase()) {
            role = (u['role'] ?? '').toString();
            teams = (u['teams'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
            break;
          }
        }
      }
      if (role == null) {
        AppLogger.info('Storage', 'Rollen-Policy: keine Rolle fuer $username');
        return;
      }
      // Admin‑Rollen dürfen frei wählen
      final isAdmin = ['org_admin', 'pv_admin'].contains(role.toLowerCase());
      if (!isAdmin) {
        if (s.teamId.isEmpty && teams.isNotEmpty) {
          final updated = s.copyWith(teamId: teams.first);
          await saveSettings(updated);
          await FileLogger().log('🔐 Rolle "$role" setzt TeamId=${teams.first}');
        } else if (s.teamId.isNotEmpty && teams.isNotEmpty && !teams.contains(s.teamId)) {
          final updated = s.copyWith(teamId: teams.first);
          await saveSettings(updated);
          await FileLogger().log('🔐 Rolle "$role" korrigiert TeamId auf ${teams.first}');
        }
      }
    } catch (e) {
      AppLogger.error('Storage', 'Rollen-Policy Fehler', e);
    }
  }

  Future<bool> syncToCloud() async {
    if (_cloudSync == null) {
      AppLogger.error('Storage', 'Cloud-Sync nicht initialisiert');
      await FileLogger().log('☁️ ❌ Cloud-Sync nicht initialisiert');
      return false;
    }

    try {
      AppLogger.info('Storage', 'Starte vollstaendige Cloud-Synchronisation...');
      await FileLogger().log('☁️ 🔄 Starte vollständige Cloud-Synchronisation...');

      // Load Settings um korrekte organizationId und teamId zu verwenden
      final settings = await loadSettings();
      final organizationId = settings.organizationId.isNotEmpty ? settings.organizationId : 'default';

      AppLogger.info('Storage', 'Verwende Organization: $organizationId');
      await FileLogger().log('☁️ 📋 Verwende Organization: $organizationId');
      if (settings.teamId.isNotEmpty) {
        AppLogger.info('Storage', 'Verwende Team: ${settings.teamId}');
        await FileLogger().log('☁️ 👥 Verwende Team: ${settings.teamId}');
      }

      // Setup remote directory mit korrekten Settings
      await _cloudSync!.setupRemoteDirectory();

      // Load manifest und sync alle records
      final manifest = await _cryptoStorage.loadManifest();
      int synced = 0;

      for (final entry in manifest.entries) {
        try {
          await _syncToCloud(entry.uuid);
          synced++;
        } catch (e) {
          AppLogger.warning('Storage', 'Fehler beim Sync von ${entry.uuid}: $e');
        }
      }

      AppLogger.info('Storage', 'Cloud-Synchronisation abgeschlossen: $synced/${manifest.entries.length} Datensaetze');
      await FileLogger().log('☁️ ✅ Cloud-Synchronisation abgeschlossen: $synced/${manifest.entries.length}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Cloud-Synchronisation fehlgeschlagen', e);
      await FileLogger().log('☁️ ❌ Cloud-Synchronisation fehlgeschlagen: $e');
      return false;
    }
  }

  // === Standorte ===

  Future<List<Standort>> loadStandorte() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final entries = manifest.entries.where((e) => e.schema == 'standort').toList();

      final standorte = <Standort>[];
      _standortIdToUuid.clear();
      for (final entry in entries) {
        try {
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          final standort = Standort.fromJson(data);
          standorte.add(standort);
          _standortIdToUuid[standort.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Standort ${entry.uuid}', e);
        }
      }

      standorte.sort((a, b) => a.name.compareTo(b.name));
      AppLogger.info('Storage', '${standorte.length} Standorte geladen');
      return standorte;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Standorte', e);
      return [];
    }
  }

  Future<bool> addStandort(Standort standort) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('standort', standort.toJson());
      _standortIdToUuid[standort.id] = uuid;

      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync Standort (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Standort gespeichert: ${standort.name}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des Standorts', e);
      return false;
    }
  }

  Future<bool> updateStandort(Standort updatedStandort) async {
    try {
      String? targetUuid = _standortIdToUuid[updatedStandort.id];
      if (targetUuid == null) {
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'standort')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final standort = Standort.fromJson(data);
            if (standort.id == updatedStandort.id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        _standortIdToUuid.remove(updatedStandort.id);
        if (_cloudSync != null) {
          try { await _cloudSync!.deleteRemoteRecord(targetUuid); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Delete Standort (async) fehlgeschlagen: $e');
          }
        }
      }

      return await addStandort(updatedStandort);
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Aktualisieren des Standorts', e);
      return false;
    }
  }

  Future<bool> deleteStandort(String standortId) async {
    try {
      String? targetUuid = _standortIdToUuid[standortId];
      if (targetUuid == null) {
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'standort')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final standort = Standort.fromJson(data);
            if (standort.id == standortId) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        _standortIdToUuid.remove(standortId);

        if (_cloudSync != null) {
          try { await _cloudSync!.deleteRemoteRecord(targetUuid); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Delete Standort (async) fehlgeschlagen: $e');
          }
        }

        AppLogger.info('Storage', 'Standort geloescht: $standortId');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen des Standorts', e);
      return false;
    }
  }

  // === Fahrwege ===

  Future<List<Fahrweg>> loadFahrwege() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final entries = manifest.entries.where((e) => e.schema == 'fahrweg').toList();

      final fahrwege = <Fahrweg>[];
      _fahrwegIdToUuid.clear();
      for (final entry in entries) {
        try {
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          final fahrweg = Fahrweg.fromJson(data);
          fahrwege.add(fahrweg);
          _fahrwegIdToUuid[fahrweg.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von Fahrweg ${entry.uuid}', e);
        }
      }

      fahrwege.sort((a, b) => b.datum.compareTo(a.datum));
      AppLogger.info('Storage', '${fahrwege.length} Fahrwege geladen');
      return fahrwege;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden der Fahrwege', e);
      return [];
    }
  }

  Future<bool> addFahrweg(Fahrweg fahrweg) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('fahrweg', fahrweg.toJson());
      _fahrwegIdToUuid[fahrweg.id] = uuid;

      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync Fahrweg (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'Fahrweg gespeichert: ${fahrweg.streckenBeschreibung}');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des Fahrwegs', e);
      return false;
    }
  }

  Future<bool> deleteFahrweg(String fahrwegId) async {
    try {
      String? targetUuid = _fahrwegIdToUuid[fahrwegId];
      if (targetUuid == null) {
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'fahrweg')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final fahrweg = Fahrweg.fromJson(data);
            if (fahrweg.id == fahrwegId) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        _fahrwegIdToUuid.remove(fahrwegId);

        if (_cloudSync != null) {
          try { await _cloudSync!.deleteRemoteRecord(targetUuid); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Delete Fahrweg (async) fehlgeschlagen: $e');
          }
        }

        AppLogger.info('Storage', 'Fahrweg geloescht: $fahrwegId');
        return true;
      }

      return false;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Loeschen des Fahrwegs', e);
      return false;
    }
  }

  // === StreckenCache ===

  Future<List<StreckenCache>> loadStreckenCache() async {
    try {
      final manifest = await _cryptoStorage.loadManifest();
      final entries = manifest.entries.where((e) => e.schema == 'streckencache').toList();

      final cache = <StreckenCache>[];
      _streckenCacheIdToUuid.clear();
      for (final entry in entries) {
        try {
          final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
          final strecke = StreckenCache.fromJson(data);
          cache.add(strecke);
          _streckenCacheIdToUuid[strecke.id] = entry.uuid;
        } catch (e) {
          AppLogger.error('Storage', 'Fehler beim Laden von StreckenCache ${entry.uuid}', e);
        }
      }

      AppLogger.info('Storage', '${cache.length} StreckenCache-Eintraege geladen');
      return cache;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Laden des StreckenCaches', e);
      return [];
    }
  }

  Future<bool> addStreckenCacheEntry(StreckenCache strecke) async {
    try {
      final uuid = await _cryptoStorage.saveJsonEncrypted('streckencache', strecke.toJson());
      _streckenCacheIdToUuid[strecke.id] = uuid;

      if (_cloudSync != null) {
        try { await _syncToCloud(uuid); } catch (e) {
          AppLogger.warning('Storage', 'Cloud-Sync StreckenCache (async) fehlgeschlagen: $e');
        }
      }

      AppLogger.info('Storage', 'StreckenCache gespeichert: ${strecke.distanzKm} km');
      return true;
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Speichern des StreckenCache', e);
      return false;
    }
  }

  Future<bool> updateStreckenCacheEntry(StreckenCache updatedStrecke) async {
    try {
      String? targetUuid = _streckenCacheIdToUuid[updatedStrecke.id];
      if (targetUuid == null) {
        final manifest = await _cryptoStorage.loadManifest();
        for (final entry in manifest.entries.where((e) => e.schema == 'streckencache')) {
          try {
            final data = await _cryptoStorage.loadJsonDecrypted(entry.uuid);
            final strecke = StreckenCache.fromJson(data);
            if (strecke.id == updatedStrecke.id) {
              targetUuid = entry.uuid;
              break;
            }
          } catch (e) {
            continue;
          }
        }
      }

      if (targetUuid != null) {
        await _cryptoStorage.deleteRecord(targetUuid);
        _streckenCacheIdToUuid.remove(updatedStrecke.id);
        if (_cloudSync != null) {
          try { await _cloudSync!.deleteRemoteRecord(targetUuid); } catch (e) {
            AppLogger.warning('Storage', 'Cloud-Delete StreckenCache (async) fehlgeschlagen: $e');
          }
        }
      }

      return await addStreckenCacheEntry(updatedStrecke);
    } catch (e) {
      AppLogger.error('Storage', 'Fehler beim Aktualisieren des StreckenCache', e);
      return false;
    }
  }

  // Getter für externe Services
  CryptoStorage get cryptoStorage => _cryptoStorage;
  HiDriveBusinessSync? get cloudSync => _cloudSync;
}
