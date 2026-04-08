import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/client.dart';
import '../models/appointment.dart';
import '../models/app_settings.dart';
import '../models/arbeitszeit.dart';
import '../models/informationsbericht.dart';
import 'file_logger.dart';

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  final FileLogger _logger = FileLogger();
  Directory? _dataDirectory;

  Future<void> initialize() async {
    try {
      await _logger.initialize();
      await _logger.log("📁 🔄 Initialisiere FileStorageService...");

      final appDir = await getApplicationSupportDirectory();
      _dataDirectory = Directory('${appDir.path}/app_data');

      if (!await _dataDirectory!.exists()) {
        await _dataDirectory!.create(recursive: true);
        await _logger.log("📁 ✅ App-Daten-Verzeichnis erstellt: ${_dataDirectory!.path}");
      } else {
        await _logger.log("📁 ✅ App-Daten-Verzeichnis gefunden: ${_dataDirectory!.path}");
      }
    } catch (e) {
      await _logger.log("📁 ❌ Fehler bei FileStorageService Initialisierung: $e");
      rethrow;
    }
  }

  Future<File> _getDataFile(String filename) async {
    if (_dataDirectory == null) {
      await initialize();
    }
    return File('${_dataDirectory!.path}/$filename.json');
  }

  Future<T?> _readJsonFile<T>(String filename, T Function(Map<String, dynamic>) fromJson) async {
    try {
      final file = await _getDataFile(filename);
      if (!await file.exists()) {
        await _logger.log("📁 Datei nicht gefunden: $filename");
        return null;
      }

      final jsonString = await file.readAsString();
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      await _logger.log("📁 ✅ Datei gelesen: $filename (${jsonString.length} Zeichen)");
      return fromJson(jsonData);
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Lesen von $filename: $e");
      return null;
    }
  }

  Future<bool> _writeJsonFile<T>(String filename, T data, Map<String, dynamic> Function(T) toJson) async {
    try {
      final file = await _getDataFile(filename);
      final jsonData = toJson(data);
      final jsonString = json.encode(jsonData);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ Datei geschrieben: $filename (${jsonString.length} Zeichen)");

      // Verifikation
      if (await file.exists()) {
        final verification = await file.readAsString();
        if (verification.length == jsonString.length) {
          await _logger.log("📁 ✅ Verifikation erfolgreich für $filename");
          return true;
        } else {
          await _logger.log("📁 ❌ Verifikation fehlgeschlagen für $filename: ${verification.length} != ${jsonString.length}");
        }
      }
      return false;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Schreiben von $filename: $e");
      return false;
    }
  }

  // Clients
  Future<List<Client>> loadClients() async {
    try {
      await _logger.log("📁 🔄 Lade Clients aus Datei...");
      final file = await _getDataFile('clients');

      if (!await file.exists()) {
        await _logger.log("📁 Keine Clients-Datei gefunden");
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> clientsList = json.decode(jsonString);
      final List<Client> clients = clientsList
          .map((json) => Client.fromJson(json))
          .toList();

      await _logger.log("📁 ✅ ${clients.length} Clients aus Datei geladen");
      return clients;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Laden der Clients: $e");
      return [];
    }
  }

  Future<bool> saveClients(List<Client> clients) async {
    try {
      await _logger.log("📁 🔄 Speichere ${clients.length} Clients in Datei...");

      final file = await _getDataFile('clients');
      final clientsJson = clients.map((client) => client.toJson()).toList();
      final jsonString = json.encode(clientsJson);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ ${clients.length} Clients in Datei gespeichert (${jsonString.length} Zeichen)");

      // Verifikation
      if (await file.exists()) {
        final verification = await file.readAsString();
        if (verification.isNotEmpty) {
          await _logger.log("📁 ✅ Verifikation erfolgreich: Clients-Datei lesbar");
          return true;
        }
      }
      await _logger.log("📁 ❌ Verifikation fehlgeschlagen: Clients-Datei nicht lesbar");
      return false;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Speichern der Clients: $e");
      return false;
    }
  }

  // Appointments
  Future<List<Appointment>> loadAppointments() async {
    try {
      await _logger.log("📁 🔄 Lade Appointments aus Datei...");
      final file = await _getDataFile('appointments');

      if (!await file.exists()) {
        await _logger.log("📁 Keine Appointments-Datei gefunden");
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> appointmentsList = json.decode(jsonString);
      final List<Appointment> appointments = appointmentsList
          .map((json) => Appointment.fromJson(json))
          .toList();

      await _logger.log("📁 ✅ ${appointments.length} Appointments aus Datei geladen");
      return appointments;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Laden der Appointments: $e");
      return [];
    }
  }

  Future<bool> saveAppointments(List<Appointment> appointments) async {
    try {
      await _logger.log("📁 🔄 Speichere ${appointments.length} Appointments in Datei...");

      final file = await _getDataFile('appointments');
      final appointmentsJson = appointments.map((appointment) => appointment.toJson()).toList();
      final jsonString = json.encode(appointmentsJson);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ ${appointments.length} Appointments in Datei gespeichert");
      return true;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Speichern der Appointments: $e");
      return false;
    }
  }

  // Arbeitszeiten
  Future<List<Arbeitszeit>> loadArbeitszeiten() async {
    try {
      await _logger.log("📁 🔄 Lade Arbeitszeiten aus Datei...");
      final file = await _getDataFile('arbeitszeiten');

      if (!await file.exists()) {
        await _logger.log("📁 Keine Arbeitszeiten-Datei gefunden");
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> arbeitszeitenList = json.decode(jsonString);
      final List<Arbeitszeit> arbeitszeiten = arbeitszeitenList
          .map((json) => Arbeitszeit.fromJson(json))
          .toList();

      await _logger.log("📁 ✅ ${arbeitszeiten.length} Arbeitszeiten aus Datei geladen");
      return arbeitszeiten;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Laden der Arbeitszeiten: $e");
      return [];
    }
  }

  Future<bool> saveArbeitszeiten(List<Arbeitszeit> arbeitszeiten) async {
    try {
      await _logger.log("📁 🔄 Speichere ${arbeitszeiten.length} Arbeitszeiten in Datei...");

      final file = await _getDataFile('arbeitszeiten');
      final arbeitszeitenJson = arbeitszeiten.map((arbeitszeit) => arbeitszeit.toJson()).toList();
      final jsonString = json.encode(arbeitszeitenJson);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ ${arbeitszeiten.length} Arbeitszeiten in Datei gespeichert");
      return true;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Speichern der Arbeitszeiten: $e");
      return false;
    }
  }

  // App Settings (keep using SharedPreferences for settings as they work)
  Future<AppSettings?> loadSettings() async {
    return await _readJsonFile('settings', (json) => AppSettings.fromJson(json));
  }

  Future<bool> saveSettings(AppSettings settings) async {
    return await _writeJsonFile('settings', settings, (settings) => settings.toJson());
  }

  // Email Targets
  Future<List<String>> loadEmailTargets() async {
    try {
      final file = await _getDataFile('email_targets');

      if (!await file.exists()) {
        await _logger.log("📁 Keine Email-Targets-Datei gefunden");
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> emailTargetsList = json.decode(jsonString);
      final List<String> emailTargets = emailTargetsList.cast<String>();

      await _logger.log("📁 ✅ ${emailTargets.length} Email-Targets aus Datei geladen");
      return emailTargets;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Laden der Email-Targets: $e");
      return [];
    }
  }

  Future<bool> saveEmailTargets(List<String> emailTargets) async {
    try {
      final file = await _getDataFile('email_targets');
      final jsonString = json.encode(emailTargets);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ ${emailTargets.length} Email-Targets in Datei gespeichert");
      return true;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Speichern der Email-Targets: $e");
      return false;
    }
  }

  // Informationsberichte (Entwuerfe)
  Future<List<Informationsbericht>> loadBerichte() async {
    try {
      await _logger.log("📁 🔄 Lade Berichte aus Datei...");
      final file = await _getDataFile('berichte');

      if (!await file.exists()) {
        await _logger.log("📁 Keine Berichte-Datei gefunden");
        return [];
      }

      final jsonString = await file.readAsString();
      final List<dynamic> berichteList = json.decode(jsonString);
      final List<Informationsbericht> berichte = berichteList
          .map((json) => Informationsbericht.fromJson(json))
          .toList();

      await _logger.log("📁 ✅ ${berichte.length} Berichte aus Datei geladen");
      return berichte;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Laden der Berichte: $e");
      return [];
    }
  }

  Future<bool> saveBerichte(List<Informationsbericht> berichte) async {
    try {
      await _logger.log("📁 🔄 Speichere ${berichte.length} Berichte in Datei...");

      final file = await _getDataFile('berichte');
      final berichteJson = berichte.map((b) => b.toJson()).toList();
      final jsonString = json.encode(berichteJson);

      await file.writeAsString(jsonString, flush: true);
      await _logger.log("📁 ✅ ${berichte.length} Berichte in Datei gespeichert");
      return true;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Speichern der Berichte: $e");
      return false;
    }
  }

  Future<bool> clearAllData() async {
    try {
      await _logger.log("📁 🔄 Lösche alle App-Daten...");

      final files = ['clients', 'appointments', 'arbeitszeiten', 'settings', 'email_targets', 'berichte'];
      for (final filename in files) {
        final file = await _getDataFile(filename);
        if (await file.exists()) {
          await file.delete();
          await _logger.log("📁 ✅ Datei gelöscht: $filename");
        }
      }

      await _logger.log("📁 ✅ Alle App-Daten gelöscht");
      return true;
    } catch (e) {
      await _logger.log("📁 ❌ Fehler beim Löschen aller Daten: $e");
      return false;
    }
  }
}