import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../models/arbeitszeit.dart';
import 'file_logger.dart';
import 'file_storage_service.dart';

class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  static const String _clientsKey = 'clients';
  static const String _appointmentsKey = 'appointments';
  static const String _arbeitszeitenKey = 'arbeitszeiten';
  static const String _settingsKey = 'app_settings';
  static const String _emailTargetsKey = 'email_targets';

  SharedPreferences? _prefs;
  final FileLogger _logger = FileLogger();
  final FileStorageService _fileStorage = FileStorageService();

  Future<void> initialize() async {
    if (_prefs == null) {
      try {
        await _logger.initialize();
        await _logger.log("📦 🔄 Initialisiere SharedPreferences...");

        _prefs = await SharedPreferences.getInstance();
        if (_prefs != null) {
          await _logger.log("📦 ✅ SharedPreferences erfolgreich initialisiert");
        } else {
          await _logger.log("📦 ❌ SharedPreferences Initialisierung gab null zurück");
        }
      } catch (e, stackTrace) {
        await _logger.log("📦 ❌ Exception bei SharedPreferences Initialisierung: $e");
        await _logger.log("📦 ❌ StackTrace: $stackTrace");
      }
    }
  }

  // Clients
  Future<List<Client>> loadClients() async {
    await initialize();
    try {
      await _logger.log("📦 🔄 Lade Klienten (mit FileStorage Fallback)...");

      // Use file-based storage directly for better reliability on macOS
      return await _fileStorage.loadClients();
    } catch (e) {
      await _logger.log("📦 ❌ Fehler beim Laden der Klienten: $e");
      return [];
    }
  }

  Future<bool> saveClients(List<Client> clients) async {
    await initialize();
    try {
      await _logger.log("📦 🔄 Speichere ${clients.length} Klienten (mit FileStorage)...");

      // Use file-based storage directly for better reliability on macOS
      final bool success = await _fileStorage.saveClients(clients);

      if (success) {
        await _logger.log("📦 ✅ ${clients.length} Klienten erfolgreich in Dateien gespeichert");
      } else {
        await _logger.log("📦 ❌ Fehler beim Speichern der Klienten in Dateien");
      }
      return success;
    } catch (e, stackTrace) {
      await _logger.log("📦 ❌ Exception beim Speichern der Klienten: $e");
      await _logger.log("📦 ❌ StackTrace: $stackTrace");
      return false;
    }
  }

  Future<bool> addClient(Client client) async {
    await _logger.log("📦 🔄 Füge neuen Klienten hinzu: ${client.name}");
    final clients = await loadClients();
    clients.add(client);
    final success = await saveClients(clients);
    await _logger.log("📦 ${success ? '✅' : '❌'} Klient hinzugefügt: ${client.name}");
    return success;
  }

  Future<bool> updateClient(Client updatedClient) async {
    final clients = await loadClients();
    final index = clients.indexWhere((c) => c.id == updatedClient.id);
    if (index != -1) {
      clients[index] = updatedClient;
      return await saveClients(clients);
    }
    return false;
  }

  Future<bool> deleteClient(String clientId) async {
    final clients = await loadClients();
    clients.removeWhere((c) => c.id == clientId);
    
    // Auch alle Termine des Klienten löschen
    final appointments = await loadAppointments();
    appointments.removeWhere((a) => a.clientId == clientId);
    await saveAppointments(appointments);
    
    return await saveClients(clients);
  }

  // Appointments
  Future<List<Appointment>> loadAppointments() async {
    await initialize();
    try {
      await _logger.log("📅 🔄 Lade Termine (mit FileStorage)...");
      return await _fileStorage.loadAppointments();
    } catch (e) {
      await _logger.log("📅 ❌ Fehler beim Laden der Termine: $e");
      return [];
    }
  }

  Future<bool> saveAppointments(List<Appointment> appointments) async {
    await initialize();
    try {
      await _logger.log("📅 🔄 Speichere ${appointments.length} Termine (mit FileStorage)...");
      return await _fileStorage.saveAppointments(appointments);
    } catch (e) {
      await _logger.log("📅 ❌ Fehler beim Speichern der Termine: $e");
      return false;
    }
  }

  Future<bool> addAppointment(Appointment appointment) async {
    final appointments = await loadAppointments();
    appointments.add(appointment);
    appointments.sort((a, b) => b.date.compareTo(a.date)); // Neueste zuerst
    return await saveAppointments(appointments);
  }

  Future<bool> updateAppointment(Appointment updatedAppointment) async {
    final appointments = await loadAppointments();
    final index = appointments.indexWhere((a) => a.id == updatedAppointment.id);
    if (index != -1) {
      appointments[index] = updatedAppointment;
      appointments.sort((a, b) => b.date.compareTo(a.date)); // Neueste zuerst
      return await saveAppointments(appointments);
    }
    return false;
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    final appointments = await loadAppointments();
    appointments.removeWhere((a) => a.id == appointmentId);
    return await saveAppointments(appointments);
  }

  // App Settings
  Future<AppSettings> loadSettings() async {
    await initialize();
    try {
      final String? settingsJson = _prefs?.getString(_settingsKey);
      if (settingsJson == null || settingsJson.isEmpty) {
        print("⚙️ Keine Einstellungen gefunden - verwende Standard");
        final defaultSettings = AppSettings.defaultSettings();
        await saveSettings(defaultSettings);
        return defaultSettings;
      }

      final AppSettings settings = AppSettings.fromJson(json.decode(settingsJson));
      print("⚙️ Einstellungen geladen");
      return settings;
    } catch (e) {
      print("⚙️ ❌ Fehler beim Laden der Einstellungen: $e");
      final defaultSettings = AppSettings.defaultSettings();
      await saveSettings(defaultSettings);
      return defaultSettings;
    }
  }

  Future<bool> saveSettings(AppSettings settings) async {
    await initialize();
    try {
      final String settingsJson = json.encode(settings.toJson());
      final bool success = await _prefs?.setString(_settingsKey, settingsJson) ?? false;
      
      if (success) {
        print("⚙️ ✅ Einstellungen gespeichert");
      } else {
        print("⚙️ ❌ Fehler beim Speichern der Einstellungen");
      }
      return success;
    } catch (e) {
      print("⚙️ ❌ Fehler beim Speichern der Einstellungen: $e");
      return false;
    }
  }

  // Email Targets
  Future<List<String>> loadEmailTargets() async {
    await initialize();
    try {
      final String? emailTargetsJson = _prefs?.getString(_emailTargetsKey);
      if (emailTargetsJson == null || emailTargetsJson.isEmpty) {
        print("📧 Keine E-Mail-Ziele gefunden");
        return [];
      }

      final List<dynamic> emailTargetsList = json.decode(emailTargetsJson);
      final List<String> emailTargets = emailTargetsList.cast<String>();
      
      print("📧 ${emailTargets.length} E-Mail-Ziele geladen");
      return emailTargets;
    } catch (e) {
      print("📧 ❌ Fehler beim Laden der E-Mail-Ziele: $e");
      return [];
    }
  }

  Future<bool> saveEmailTargets(List<String> emailTargets) async {
    await initialize();
    try {
      final String emailTargetsJson = json.encode(emailTargets);
      final bool success = await _prefs?.setString(_emailTargetsKey, emailTargetsJson) ?? false;
      
      if (success) {
        print("📧 ✅ ${emailTargets.length} E-Mail-Ziele gespeichert");
      } else {
        print("📧 ❌ Fehler beim Speichern der E-Mail-Ziele");
      }
      return success;
    } catch (e) {
      print("📧 ❌ Fehler beim Speichern der E-Mail-Ziele: $e");
      return false;
    }
  }

  // Arbeitszeiten
  Future<List<Arbeitszeit>> loadArbeitszeiten() async {
    await initialize();
    try {
      await _logger.log("⏰ 🔄 Lade Arbeitszeiten (mit FileStorage)...");
      return await _fileStorage.loadArbeitszeiten();
    } catch (e) {
      await _logger.log("⏰ ❌ Fehler beim Laden der Arbeitszeiten: $e");
      return [];
    }
  }

  Future<bool> addArbeitszeit(Arbeitszeit arbeitszeit) async {
    try {
      final arbeitszeiten = await loadArbeitszeiten();
      arbeitszeiten.add(arbeitszeit);
      return await _saveArbeitszeiten(arbeitszeiten);
    } catch (e) {
      print('⏰ ❌ Fehler beim Hinzufügen der Arbeitszeit: $e');
      return false;
    }
  }

  Future<bool> updateArbeitszeit(Arbeitszeit arbeitszeit) async {
    try {
      final arbeitszeiten = await loadArbeitszeiten();
      final index = arbeitszeiten.indexWhere((a) => a.id == arbeitszeit.id);
      
      if (index != -1) {
        arbeitszeiten[index] = arbeitszeit;
        return await _saveArbeitszeiten(arbeitszeiten);
      }
      return false;
    } catch (e) {
      print('⏰ ❌ Fehler beim Aktualisieren der Arbeitszeit: $e');
      return false;
    }
  }

  Future<bool> deleteArbeitszeit(String id) async {
    try {
      final arbeitszeiten = await loadArbeitszeiten();
      arbeitszeiten.removeWhere((arbeitszeit) => arbeitszeit.id == id);
      return await _saveArbeitszeiten(arbeitszeiten);
    } catch (e) {
      print('⏰ ❌ Fehler beim Löschen der Arbeitszeit: $e');
      return false;
    }
  }

  Future<bool> _saveArbeitszeiten(List<Arbeitszeit> arbeitszeiten) async {
    await initialize();
    try {
      await _logger.log("⏰ 🔄 Speichere ${arbeitszeiten.length} Arbeitszeiten (mit FileStorage)...");
      return await _fileStorage.saveArbeitszeiten(arbeitszeiten);
    } catch (e) {
      await _logger.log("⏰ ❌ Fehler beim Speichern der Arbeitszeiten: $e");
      return false;
    }
  }

  // Automatische Arbeitszeit-Erstellung aus Terminen
  Future<bool> createArbeitszeitFromAppointment(Appointment appointment) async {
    try {
      // Prüfen ob bereits eine Arbeitszeit für diesen Termin existiert
      final arbeitszeiten = await loadArbeitszeiten();
      final exists = arbeitszeiten.any((az) => 
        az.datum.day == appointment.date.day &&
        az.datum.month == appointment.date.month &&
        az.datum.year == appointment.date.year &&
        az.startzeit.hour == appointment.startTime.hour &&
        az.startzeit.minute == appointment.startTime.minute
      );
      
      if (exists) {
        print('⏰ Arbeitszeit für Termin existiert bereits');
        return true;
      }
      
      // Neue Arbeitszeit aus Termin erstellen
      final arbeitszeit = Arbeitszeit.create(
        datum: appointment.date,
        startzeit: appointment.startTime,
        endzeit: appointment.endTime,
        taetigkeit: 'Kliententermin: ${appointment.clientName}',
        notizen: 'Automatisch erstellt aus Termin\\nICF-Bereiche: ${appointment.icfBereiche.join(", ")}\\nNotizen: ${appointment.notes}',
      );
      
      return await addArbeitszeit(arbeitszeit);
    } catch (e) {
      print('⏰ ❌ Fehler beim Erstellen der Arbeitszeit aus Termin: $e');
      return false;
    }
  }

  // Clear all data
  Future<bool> clearAllData() async {
    await initialize();
    try {
      await _logger.log("🗑️ 🔄 Lösche alle Daten (mit FileStorage)...");

      // Clear file-based storage
      final fileSuccess = await _fileStorage.clearAllData();

      // Also clear SharedPreferences
      await _prefs?.remove(_clientsKey);
      await _prefs?.remove(_appointmentsKey);
      await _prefs?.remove(_arbeitszeitenKey);
      await _prefs?.remove(_settingsKey);
      await _prefs?.remove(_emailTargetsKey);

      await _logger.log("🗑️ ✅ Alle Daten gelöscht");
      return fileSuccess;
    } catch (e) {
      await _logger.log("🗑️ ❌ Fehler beim Löschen aller Daten: $e");
      return false;
    }
  }

  // File Operations
  Future<Directory> getApplicationDataDirectory() async {
    return await getApplicationSupportDirectory();
  }

  Future<Directory> getBackupDirectory() async {
    final Directory appDir = await getApplicationSupportDirectory();
    final Directory backupDir = Directory('${appDir.path}/backups');
    
    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }
    
    return backupDir;
  }

  // Utility Methods

  Future<Map<String, dynamic>> exportAllData() async {
    final clients = await loadClients();
    final appointments = await loadAppointments();
    final settings = await loadSettings();
    final emailTargets = await loadEmailTargets();

    return {
      'clients': clients.map((c) => c.toJson()).toList(),
      'appointments': appointments.map((a) => a.toJson()).toList(),
      'settings': settings.toJson(),
      'emailTargets': emailTargets,
      'exportDate': DateTime.now().toIso8601String(),
      'version': '2.1.0',
    };
  }

  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      // Clients importieren
      if (data['clients'] != null) {
        final List<Client> clients = (data['clients'] as List)
            .map((json) => Client.fromJson(json))
            .toList();
        await saveClients(clients);
      }

      // Appointments importieren
      if (data['appointments'] != null) {
        final List<Appointment> appointments = (data['appointments'] as List)
            .map((json) => Appointment.fromJson(json))
            .toList();
        await saveAppointments(appointments);
      }

      // Settings importieren
      if (data['settings'] != null) {
        final AppSettings settings = AppSettings.fromJson(data['settings']);
        await saveSettings(settings);
      }

      // Email Targets importieren
      if (data['emailTargets'] != null) {
        final List<String> emailTargets = (data['emailTargets'] as List).cast<String>();
        await saveEmailTargets(emailTargets);
      }

      print("📥 ✅ Datenimport erfolgreich");
      return true;
    } catch (e) {
      print("📥 ❌ Fehler beim Datenimport: $e");
      return false;
    }
  }
}