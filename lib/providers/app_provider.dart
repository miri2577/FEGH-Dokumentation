import 'package:flutter/material.dart';
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
import '../services/secure_storage_service.dart';
import '../services/authentication_service.dart';
import '../services/web_auth_service.dart';
import '../services/speech_service.dart';
import '../services/message_service.dart';
import '../services/app_logger.dart';
import '../utils/platform_utils.dart';

class AppProvider extends ChangeNotifier {
  final SecureStorageService _storageService = SecureStorageService();
  final AuthenticationService _authService = AuthenticationService();
  final WebAuthService _webAuthService = WebAuthService();
  final SpeechService _speechService = SpeechService();
  final MessageService _messageService = MessageService();


  // Ob App-Passwort als Fallback genutzt wird (Desktop ohne Biometrie/PIN)
  bool _useAppPassword = false;

  /// Ob die App auf App-eigenes Passwort zurückfallen muss
  /// (Web oder Desktop ohne Geräte-Authentifizierung)
  bool get useAppPassword => _useAppPassword || PlatformUtils.isWeb;

  // Authentication State (Platform-aware)
  bool get isAuthenticated {
    if (useAppPassword) {
      return _webAuthService.isAuthenticated;
    }
    return _authService.isAuthenticated;
  }

  bool get canUseBiometry {
    if (useAppPassword) return false;
    return _authService.canUseBiometry;
  }

  bool get canUseDeviceAuth {
    if (useAppPassword) return false;
    return _authService.canUseDeviceAuth;
  }

  String? get authenticationError {
    if (useAppPassword) {
      return _webAuthService.authenticationError;
    }
    return _authService.authenticationError;
  }

  bool get isAuthenticating {
    if (useAppPassword) {
      return _webAuthService.isAuthenticating;
    }
    return _authService.isAuthenticating;
  }

  String get biometryTypeName {
    if (useAppPassword) return "Passwort";
    return _authService.biometryTypeName;
  }

  // Web/Desktop-Passwort properties
  bool get isPasswordSet => useAppPassword ? _webAuthService.isPasswordSet : true;

  // Speech State
  bool get speechEnabled => _speechService.speechEnabled;
  bool get isListening => _speechService.isListening;
  String get recognizedText => _speechService.recognizedText;
  String get speechError => _speechService.lastError;
  double get confidenceLevel => _speechService.confidenceLevel;

  // Message State
  List<dynamic> get messages => _messageService.messages;
  int get unreadMessageCount => _messageService.unreadCount;

  // Data State
  List<Client> _clients = [];
  List<Appointment> _appointments = [];
  List<Arbeitszeit> _arbeitszeiten = [];
  List<Mitarbeiter> _mitarbeiter = [];
  List<FreizeitAntrag> _freizeitAntraege = [];
  AppSettings _settings = AppSettings.defaultSettings();
  List<String> _emailTargets = [];
  Mitarbeiter? _currentUser;

  // Fahrwege State
  List<Standort> _standorte = [];
  List<Fahrweg> _fahrwege = [];
  List<StreckenCache> _streckenCache = [];

  // Loading State
  bool _isLoading = false;
  bool _isDataLoading = false;
  String? _error;

  // Getters
  List<Client> get clients => _clients;
  List<Appointment> get appointments => _appointments;
  List<Arbeitszeit> get arbeitszeiten => _arbeitszeiten;
  List<Mitarbeiter> get mitarbeiter => _mitarbeiter;
  List<FreizeitAntrag> get freizeitAntraege => _freizeitAntraege;
  AppSettings get settings => _settings;
  List<String> get emailTargets => _emailTargets;
  List<Standort> get standorte => _standorte;
  List<Fahrweg> get fahrwege => _fahrwege;
  List<StreckenCache> get streckenCache => _streckenCache;
  bool get isLoading => _isLoading;
  bool get isDataLoading => _isDataLoading;
  String? get error => _error;
  Mitarbeiter? get currentUser => _currentUser;

  // Setup Wizard
  bool get setupCompleted => _settings.setupCompleted;

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
      _setError('Fehler beim Abschliessen der Ersteinrichtung: $e');
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
      _setError('Fehler beim Zuruecksetzen der Einrichtung: $e');
      return false;
    }
  }

  // Statistics
  int get totalClients => _clients.length;
  int get totalAppointments => _appointments.length;
  int get thisMonthAppointments {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final nextMonth = DateTime(now.year, now.month + 1);
    
    return _appointments.where((apt) =>
        apt.date.isAfter(thisMonth.subtract(const Duration(days: 1))) &&
        apt.date.isBefore(nextMonth)
    ).length;
  }

  int get thisWeekAppointments {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 7));
    
    return _appointments.where((apt) =>
        apt.date.isAfter(weekStart.subtract(const Duration(days: 1))) &&
        apt.date.isBefore(weekEnd)
    ).length;
  }

  double get documentationRate {
    if (_appointments.isEmpty) return 0.0;
    final documented = _appointments.where((apt) =>
        apt.notes.isNotEmpty || apt.recordedText.isNotEmpty
    ).length;
    return documented / _appointments.length;
  }

  // Stundenverbrauch Statistics
  double get averageHoursUsage {
    final clientsWithHours = _clients.where((c) => c.fachleistungsstunden != null && c.fachleistungsstunden! > 0);
    if (clientsWithHours.isEmpty) return 0.0;
    return clientsWithHours.map((c) => c.stundenverbrauchProzent).reduce((a, b) => a + b) / clientsWithHours.length;
  }

  int get clientsInRedZone => _clients.where((c) => c.stundenverbrauchProzent >= 90).length;
  int get clientsInYellowZone => _clients.where((c) => c.stundenverbrauchProzent >= 75 && c.stundenverbrauchProzent < 90).length;
  int get clientsInGreenZone => _clients.where((c) => c.stundenverbrauchProzent < 75 && c.fachleistungsstunden != null && c.fachleistungsstunden! > 0).length;

  String get hoursUsageStatus {
    if (clientsInRedZone > 0) return 'critical';
    if (clientsInYellowZone > 0) return 'warning';
    return 'good';
  }

  // Initialization - zweistufig für schnellen App-Start
  Future<void> initialize() async {
    _setLoading(true);
    try {
      // STUFE 1: Essential (blockiert UI kurz)
      await _storageService.initialize();

      if (PlatformUtils.isWeb) {
        _useAppPassword = true;
        await _webAuthService.initialize();
      } else {
        await _authService.checkBiometricAvailability();
        if (PlatformUtils.isDesktopPlatform &&
            !_authService.canUseBiometry &&
            !_authService.canUseDeviceAuth) {
          _useAppPassword = true;
          await _webAuthService.initialize();
        }
      }

      // Settings laden (wird für Auth-Gate und Theme benötigt)
      await _loadSettings();

      _clearError();
    } catch (e) {
      _setError('Initialisierungsfehler: $e');
    } finally {
      _setLoading(false); // UI SOFORT zeigen!
    }

    // STUFE 2: Deferred (non-blocking, im Hintergrund)
    _loadAllDataDeferred();
  }

  Future<void> _loadAllDataDeferred() async {
    _isDataLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadClients(),
        _loadAppointments(),
        _loadArbeitszeiten(),
        _loadMitarbeiter(),
        _loadFreizeitAntraege(),
        _loadEmailTargets(),
        _loadCurrentUser(),
        _loadStandorte(),
        _loadFahrwege(),
        _loadStreckenCache(),
      ]);

      // Speech im Hintergrund initialisieren (fire-and-forget)
      if (PlatformUtils.supportsSpeechToText) {
        _speechService.initializeSpeech();
      }

      // MessageService initialisieren wenn Credentials vorhanden
      _initMessageServiceIfReady();
    } catch (e) {
      AppLogger.error('Provider', 'Fehler beim Laden der Daten im Hintergrund', e);
    } finally {
      _isDataLoading = false;
      notifyListeners();
    }
  }

  void _initMessageServiceIfReady() {
    if (_settings.hidriveUsername.isNotEmpty &&
        _settings.hidrivePassword.isNotEmpty &&
        _settings.userName.isNotEmpty &&
        _settings.organizationId.isNotEmpty) {
      _messageService.initialize(
        hidriveUsername: _settings.hidriveUsername,
        hidrivePassword: _settings.hidrivePassword,
        userId: _settings.userName,
        organizationId: _settings.organizationId,
        rootSubdirectory: _settings.rootSubdirectory.isNotEmpty ? _settings.rootSubdirectory : null,
      ).catchError((e) {
        AppLogger.warning('Messages', 'MessageService konnte nicht initialisiert werden: $e');
      });
    } else {
      AppLogger.info('Messages', 'MessageService übersprungen (fehlender userName/Orga oder HiDrive-Creds)');
    }
  }

  // Authentication Methods
  Future<bool> authenticate([String? password]) async {
    _clearError();
    try {
      bool success;
      if (useAppPassword) {
        if (password != null) {
          success = await _webAuthService.authenticateWithPassword(password);
        } else {
          success = await _webAuthService.authenticateWithoutPassword();
        }
      } else {
        success = await _authService.authenticate();
        // Wenn Geräte-Auth fehlgeschlagen (z.B. Windows ohne PIN/Hello),
        // auf App-Passwort umschalten
        if (!success && !_authService.canUseDeviceAuth) {
          _useAppPassword = true;
          _authService.clearError();
          // WebAuthService auch auf nicht-Web initialisieren
          await _initAppPasswordAuth();
        }
      }
      notifyListeners();
      return success;
    } catch (e) {
      _setError('Authentifizierungsfehler: $e');
      return false;
    }
  }

  Future<bool> authenticateWithPasscode() async {
    _clearError();
    try {
      if (useAppPassword) {
        return await authenticate();
      } else {
        final success = await _authService.requestPasscodeUnlock();
        // Wenn Passcode fehlschlägt weil kein Gerät-Auth verfügbar,
        // auf App-Passwort umschalten
        if (!success && !_authService.canUseDeviceAuth) {
          _useAppPassword = true;
          _authService.clearError();
          await _initAppPasswordAuth();
          notifyListeners();
          return false;
        }
        notifyListeners();
        return success;
      }
    } catch (e) {
      _setError('Passcode-Authentifizierungsfehler: $e');
      return false;
    }
  }

  /// Initialisiert App-Passwort-Auth für Desktop-Plattformen ohne Geräte-Auth
  Future<void> _initAppPasswordAuth() async {
    print("🔒 Fallback auf App-Passwort-Authentifizierung (Gerät unterstützt kein Biometrie/PIN)");
    await _webAuthService.initialize();
  }

  // App-Passwort-Methoden (Web und Desktop-Fallback)
  Future<bool> setPassword(String password) async {
    if (!useAppPassword) return false;

    try {
      final success = await _webAuthService.setPassword(password);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Setzen des Passworts: $e');
      return false;
    }
  }

  Future<bool> setCredentials(String username, String password) async {
    if (!useAppPassword) return false;

    try {
      final success = await _webAuthService.setCredentials(username, password);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Setzen der Anmeldedaten: $e');
      return false;
    }
  }

  Future<bool> authenticateWithCredentials(String username, String password) async {
    if (!useAppPassword) return false;

    try {
      final success = await _webAuthService.authenticateWithCredentials(username, password);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler bei der Authentifizierung: $e');
      return false;
    }
  }

  void logout() {
    if (useAppPassword) {
      _webAuthService.logout();
    } else {
      _authService.logout();
    }
    notifyListeners();
  }

  void clearAuthError() {
    if (useAppPassword) {
      _webAuthService.clearError();
    } else {
      _authService.clearError();
    }
    notifyListeners();
  }

  // Speech Methods
  Future<void> startSpeechRecognition({
    Function(String)? onResult,
    Function(String)? onPartialResult,
  }) async {
    try {
      await _speechService.startListening(
        onResult: onResult,
        onPartialResult: onPartialResult,
      );
      notifyListeners();
    } catch (e) {
      _setError('Spracherkennungsfehler: $e');
    }
  }

  Future<void> stopSpeechRecognition() async {
    await _speechService.stopListening();
    notifyListeners();
  }

  Future<void> cancelSpeechRecognition() async {
    await _speechService.cancelListening();
    notifyListeners();
  }

  String appendSpeechText(String existingText, String newText) {
    return _speechService.appendToText(existingText, newText);
  }

  // Data Loading
  Future<void> _loadAllData() async {
    await Future.wait([
      _loadClients(),
      _loadAppointments(),
      _loadArbeitszeiten(),
      _loadMitarbeiter(),
      _loadFreizeitAntraege(),
      _loadSettings(),
      _loadEmailTargets(),
      _loadCurrentUser(),
      _loadStandorte(),
      _loadFahrwege(),
      _loadStreckenCache(),
    ]);
  }

  Future<void> _loadClients() async {
    _clients = await _storageService.loadClients();
  }

  Future<void> _loadAppointments() async {
    _appointments = await _storageService.loadAppointments();
  }

  static const _setupCompletedKey = 'setup_completed';

  Future<void> _loadSettings() async {
    _settings = await _storageService.loadSettings();
    // setupCompleted aus SharedPreferences als robuste Fallback-Quelle lesen,
    // falls CryptoStorage die Einstellungen nicht korrekt laden konnte
    final prefs = await SharedPreferences.getInstance();
    final setupFromPrefs = prefs.getBool(_setupCompletedKey);
    if (setupFromPrefs == true && !_settings.setupCompleted) {
      _settings = _settings.copyWith(setupCompleted: true);
    }
  }

  Future<void> _loadEmailTargets() async {
    _emailTargets = await _storageService.loadEmailTargets();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await _storageService.loadCurrentUser();
    } catch (e) {
      AppLogger.error('Provider', 'Fehler beim Laden des Benutzerprofils', e);
      _currentUser = null;
    }
  }

  Future<void> _loadArbeitszeiten() async {
    _arbeitszeiten = await _storageService.loadArbeitszeiten();
  }

  Future<void> _loadMitarbeiter() async {
    try {
      _mitarbeiter = await _storageService.loadMitarbeiter();
      if (_mitarbeiter.isEmpty) {
        _mitarbeiter = _createMockupMitarbeiter();
        // Save mockup data
        for (final mitarbeiter in _mitarbeiter) {
          await _storageService.saveMitarbeiter(mitarbeiter);
        }
      }
    } catch (e) {
      _mitarbeiter = _createMockupMitarbeiter();
    }
  }

  List<Mitarbeiter> _createMockupMitarbeiter() {
    return [
      Mitarbeiter.create(
        name: 'Müller',
        vorname: 'Anna',
        email: 'anna.mueller@beispiel.de',
        telefon: '030 12345678',
        teamNummer: 1,
        bereich: MitarbeiterBereich.eingliederungshilfe,
      ),
      Mitarbeiter.create(
        name: 'Schmidt',
        vorname: 'Thomas',
        email: 'thomas.schmidt@beispiel.de',
        telefon: '030 12345679',
        teamNummer: 1,
        bereich: MitarbeiterBereich.eingliederungshilfe,
      ),
      Mitarbeiter.create(
        name: 'Weber',
        vorname: 'Sarah',
        email: 'sarah.weber@beispiel.de',
        telefon: '030 12345680',
        teamNummer: 2,
        bereich: MitarbeiterBereich.familienhilfe,
      ),
      Mitarbeiter.create(
        name: 'Fischer',
        vorname: 'Michael',
        email: 'michael.fischer@beispiel.de',
        telefon: '030 12345681',
        teamNummer: 2,
        bereich: MitarbeiterBereich.jugendhilfe,
      ),
      Mitarbeiter.create(
        name: 'Bauer',
        vorname: 'Lisa',
        email: 'lisa.bauer@beispiel.de',
        telefon: '030 12345682',
        teamNummer: 3,
        bereich: MitarbeiterBereich.sozialhilfe,
      ),
      Mitarbeiter.create(
        name: 'Wagner',
        vorname: 'Peter',
        email: 'peter.wagner@beispiel.de',
        telefon: '030 12345683',
        teamNummer: 3,
        bereich: MitarbeiterBereich.betreuung,
      ),
      Mitarbeiter.create(
        name: 'Schneider',
        vorname: 'Julia',
        email: 'julia.schneider@beispiel.de',
        telefon: '030 12345684',
        teamNummer: 4,
        bereich: MitarbeiterBereich.verwaltung,
      ),
      Mitarbeiter.create(
        name: 'Hoffmann',
        vorname: 'David',
        email: 'david.hoffmann@beispiel.de',
        telefon: '030 12345685',
        teamNummer: 4,
        bereich: MitarbeiterBereich.eingliederungshilfe,
      ),
      Mitarbeiter.create(
        name: 'Klein',
        vorname: 'Emma',
        email: 'emma.klein@beispiel.de',
        telefon: '030 12345686',
        teamNummer: 5,
        bereich: MitarbeiterBereich.familienhilfe,
      ),
      Mitarbeiter.create(
        name: 'Richter',
        vorname: 'Jan',
        email: 'jan.richter@beispiel.de',
        telefon: '030 12345687',
        teamNummer: 5,
        bereich: MitarbeiterBereich.jugendhilfe,
      ),
    ];
  }

  Future<void> _loadFreizeitAntraege() async {
    try {
      _freizeitAntraege = await _storageService.loadFreizeitAntraege();
    } catch (e) {
      _freizeitAntraege = [];
    }
  }

  // Client Methods
  Future<bool> addClient(Client client) async {
    try {
      final success = await _storageService.addClient(client);
      if (success) {
        await _loadClients();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Hinzufügen des Klienten: $e');
      return false;
    }
  }

  Future<bool> updateClient(Client client) async {
    try {
      // 1. UI sofort aktualisieren (optimistisch)
      final index = _clients.indexWhere((c) => c.id == client.id);
      if (index != -1) {
        _clients[index] = client;
        notifyListeners();
      }

      // 2. Im Hintergrund speichern
      final success = await _storageService.updateClient(client);
      if (!success) {
        // Rollback bei Fehler
        await _loadClients();
        notifyListeners();
      } else {
        await _loadAppointments(); // Termine aktualisieren falls Klientenname geändert
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Klienten: $e');
      return false;
    }
  }

  Future<bool> deleteClient(String clientId) async {
    try {
      final success = await _storageService.deleteClient(clientId);
      if (success) {
        await _loadClients();
        await _loadAppointments();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Löschen des Klienten: $e');
      return false;
    }
  }

  Client? getClientById(String clientId) {
    try {
      return _clients.firstWhere((client) => client.id == clientId);
    } catch (e) {
      return null;
    }
  }

  List<Client> searchClients(String query) {
    if (query.isEmpty) return _clients;
    
    final lowerQuery = query.toLowerCase();
    return _clients.where((client) =>
        client.name.toLowerCase().contains(lowerQuery) ||
        (client.berufsgruppe?.toLowerCase().contains(lowerQuery) ?? false) ||
        (client.eingliederung?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  // Mitarbeiter Methods
  Future<bool> addMitarbeiter(Mitarbeiter mitarbeiter) async {
    try {
      final success = await _storageService.addMitarbeiter(mitarbeiter);
      if (success) {
        await _loadMitarbeiter();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Hinzufügen des Mitarbeiters: $e');
      return false;
    }
  }

  Future<bool> updateMitarbeiter(Mitarbeiter mitarbeiter) async {
    try {
      final success = await _storageService.updateMitarbeiter(mitarbeiter);
      if (success) {
        await _loadMitarbeiter();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Mitarbeiters: $e');
      return false;
    }
  }

  Future<bool> deleteMitarbeiter(String mitarbeiterId) async {
    try {
      final success = await _storageService.deleteMitarbeiter(mitarbeiterId);
      if (success) {
        await _loadMitarbeiter();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Löschen des Mitarbeiters: $e');
      return false;
    }
  }

  Mitarbeiter? getMitarbeiterById(String mitarbeiterId) {
    try {
      return _mitarbeiter.firstWhere((m) => m.id == mitarbeiterId);
    } catch (e) {
      return null;
    }
  }

  List<Mitarbeiter> searchMitarbeiter(String query) {
    if (query.isEmpty) return _mitarbeiter;

    final lowerQuery = query.toLowerCase();
    return _mitarbeiter.where((mitarbeiter) =>
        mitarbeiter.name.toLowerCase().contains(lowerQuery) ||
        mitarbeiter.vorname.toLowerCase().contains(lowerQuery) ||
        mitarbeiter.email.toLowerCase().contains(lowerQuery) ||
        mitarbeiter.bereichDisplayName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<Mitarbeiter> get activeMitarbeiter => _mitarbeiter.where((m) => m.isActive).toList();

  // Current User Methods
  Future<bool> updateCurrentUser(Mitarbeiter user) async {
    try {
      final success = await _storageService.saveCurrentUser(user);
      if (success) {
        _currentUser = user;
        // Update settings with user name
        _settings = _settings.copyWith(userName: '${user.vorname} ${user.name}');
        await _storageService.saveSettings(_settings);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Benutzerprofils: $e');
      return false;
    }
  }

  Future<bool> createCurrentUser(Mitarbeiter user) async {
    try {
      final success = await _storageService.saveCurrentUser(user);
      if (success) {
        _currentUser = user;
        // Update settings with user name
        _settings = _settings.copyWith(userName: '${user.vorname} ${user.name}');
        await _storageService.saveSettings(_settings);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Erstellen des Benutzerprofils: $e');
      return false;
    }
  }

  // FreizeitAntrag Methods
  Future<bool> addFreizeitAntrag(FreizeitAntrag antrag) async {
    try {
      final success = await _storageService.addFreizeitAntrag(antrag);
      if (success) {
        await _loadFreizeitAntraege();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Hinzufügen des Freizeit-Antrags: $e');
      return false;
    }
  }

  Future<bool> updateFreizeitAntrag(FreizeitAntrag antrag) async {
    try {
      final success = await _storageService.updateFreizeitAntrag(antrag);
      if (success) {
        await _loadFreizeitAntraege();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Freizeit-Antrags: $e');
      return false;
    }
  }

  Future<bool> deleteFreizeitAntrag(String antragId) async {
    try {
      final success = await _storageService.deleteFreizeitAntrag(antragId);
      if (success) {
        await _loadFreizeitAntraege();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Löschen des Freizeit-Antrags: $e');
      return false;
    }
  }

  FreizeitAntrag? getFreizeitAntragById(String antragId) {
    try {
      return _freizeitAntraege.firstWhere((f) => f.id == antragId);
    } catch (e) {
      return null;
    }
  }

  List<FreizeitAntrag> searchFreizeitAntraege(String query) {
    if (query.isEmpty) return _freizeitAntraege;

    final lowerQuery = query.toLowerCase();
    return _freizeitAntraege.where((antrag) =>
        antrag.grund.toLowerCase().contains(lowerQuery) ||
        antrag.typDisplayName.toLowerCase().contains(lowerQuery) ||
        antrag.statusDisplayName.toLowerCase().contains(lowerQuery)
    ).toList();
  }

  List<FreizeitAntrag> get pendingFreizeitAntraege =>
      _freizeitAntraege.where((f) => f.status == AntragStatus.beantragt).toList();

  // Appointment Methods
  Future<bool> addAppointment(Appointment appointment) async {
    try {
      final success = await _storageService.addAppointment(appointment);
      if (success) {
        // In-Memory Update statt Full-Reload
        _appointments.add(appointment);
        _appointments.sort((a, b) => b.date.compareTo(a.date));

        // Automatische Stundenverbrauch-Aktualisierung
        if (appointment.isIndirect && appointment.clientAllocations != null) {
          // Indirekt: Stunden pro Klient aus Allocations
          for (final alloc in appointment.clientAllocations!) {
            if (alloc.stunden > 0) {
              await updateStundenverbrauch(alloc.clientId, alloc.stunden);
            }
          }
        } else if (appointment.fachleistungsstunden > 0) {
          // Direkt: wie bisher
          await updateStundenverbrauch(appointment.clientId, appointment.fachleistungsstunden);
        }
        // Automatische Arbeitszeit-Erstellung
        if (appointment.isIndirect && appointment.clientAllocations != null) {
          // Indirekt: Pro Klient eine eigene Arbeitszeit mit zugewiesener Zeit
          final azTyp = _mapTerminArtToArbeitszeitTyp(appointment.effectiveTerminArt);
          DateTime laufendeStartzeit = appointment.startTime;

          for (final alloc in appointment.clientAllocations!) {
            if (alloc.minuten <= 0) continue;
            final laufendeEndzeit = laufendeStartzeit.add(Duration(minutes: alloc.minuten));
            // Duplikat-Check pro Klient
            final existsForClient = _arbeitszeiten.any((az) =>
              az.datum.day == appointment.date.day &&
              az.datum.month == appointment.date.month &&
              az.datum.year == appointment.date.year &&
              az.clientId == alloc.clientId &&
              az.appointmentId == appointment.id
            );
            if (!existsForClient) {
              final arbeitszeit = Arbeitszeit.create(
                datum: appointment.date,
                startzeit: laufendeStartzeit,
                endzeit: laufendeEndzeit,
                taetigkeit: '${appointment.effectiveTerminArt.displayName}: ${alloc.clientName}',
                notizen: 'Automatisch erstellt aus indirektem Termin\n${alloc.minuten} Min von ${appointment.fachleistungsstunden.toStringAsFixed(1)}h Gesamt\nNotizen: ${appointment.notes}',
                typ: azTyp,
                clientId: alloc.clientId,
                appointmentId: appointment.id,
              );
              final azSuccess = await _storageService.addArbeitszeit(arbeitszeit);
              if (azSuccess) {
                _arbeitszeiten.add(arbeitszeit);
              }
            }
            laufendeStartzeit = laufendeEndzeit;
          }
        } else {
          // Direkt: Eine Arbeitszeit für den gesamten Termin (wie bisher)
          final exists = _arbeitszeiten.any((az) =>
            az.datum.day == appointment.date.day &&
            az.datum.month == appointment.date.month &&
            az.datum.year == appointment.date.year &&
            az.startzeit.hour == appointment.startTime.hour &&
            az.startzeit.minute == appointment.startTime.minute
          );
          if (!exists) {
            final arbeitszeit = Arbeitszeit.create(
              datum: appointment.date,
              startzeit: appointment.startTime,
              endzeit: appointment.endTime,
              taetigkeit: 'Kliententermin: ${appointment.clientName}',
              notizen: 'Automatisch erstellt aus Termin\nICF-Bereiche: ${appointment.icfBereiche.join(", ")}\nNotizen: ${appointment.notes}',
              clientId: appointment.clientId,
              appointmentId: appointment.id,
            );
            final azSuccess = await _storageService.addArbeitszeit(arbeitszeit);
            if (azSuccess) {
              _arbeitszeiten.add(arbeitszeit);
            }
          }
        }
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Hinzufügen des Termins: $e');
      return false;
    }
  }

  Future<bool> updateAppointment(Appointment appointment) async {
    try {
      final oldAppointment = _appointments.firstWhere((a) => a.id == appointment.id);

      // 1. UI sofort aktualisieren (optimistisch)
      final index = _appointments.indexWhere((a) => a.id == appointment.id);
      if (index != -1) {
        _appointments[index] = appointment;
        notifyListeners();
      }

      // 2. Im Hintergrund speichern
      final success = await _storageService.updateAppointment(appointment);
      if (!success) {
        // Rollback bei Fehler
        await _loadAppointments();
        notifyListeners();
      } else {
        // Alte Stunden zurückrechnen
        if (oldAppointment.isIndirect && oldAppointment.clientAllocations != null) {
          for (final alloc in oldAppointment.clientAllocations!) {
            if (alloc.stunden > 0) {
              await updateStundenverbrauch(alloc.clientId, -alloc.stunden);
            }
          }
        } else if (oldAppointment.fachleistungsstunden > 0) {
          await updateStundenverbrauch(oldAppointment.clientId, -oldAppointment.fachleistungsstunden);
        }
        // Neue Stunden zurechnen
        if (appointment.isIndirect && appointment.clientAllocations != null) {
          for (final alloc in appointment.clientAllocations!) {
            if (alloc.stunden > 0) {
              await updateStundenverbrauch(alloc.clientId, alloc.stunden);
            }
          }
        } else if (appointment.fachleistungsstunden > 0) {
          await updateStundenverbrauch(appointment.clientId, appointment.fachleistungsstunden);
        }
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Termins: $e');
      return false;
    }
  }

  Future<bool> deleteAppointment(String appointmentId) async {
    try {
      // Termin lesen bevor er gelöscht wird (für Stunden-Reversal)
      final appointment = _appointments.cast<Appointment?>().firstWhere(
        (a) => a!.id == appointmentId,
        orElse: () => null,
      );

      final success = await _storageService.deleteAppointment(appointmentId);
      if (success) {
        // Stunden-Reversal
        if (appointment != null) {
          if (appointment.isIndirect && appointment.clientAllocations != null) {
            for (final alloc in appointment.clientAllocations!) {
              if (alloc.stunden > 0) {
                await updateStundenverbrauch(alloc.clientId, -alloc.stunden);
              }
            }
          } else if (appointment.fachleistungsstunden > 0) {
            await updateStundenverbrauch(appointment.clientId, -appointment.fachleistungsstunden);
          }
        }
        // In-Memory Update statt Full-Reload
        _appointments.removeWhere((a) => a.id == appointmentId);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Löschen des Termins: $e');
      return false;
    }
  }

  List<Appointment> getAppointmentsForClient(String clientId) {
    return _appointments.where((apt) =>
      apt.clientId == clientId ||
      (apt.isIndirect && apt.clientAllocations?.any((a) => a.clientId == clientId) == true)
    ).toList();
  }

  /// Gibt die zugewiesenen Stunden für einen Klienten aus einem Termin zurück
  double getAllocatedHoursForClient(Appointment apt, String clientId) {
    if (apt.isIndirect && apt.clientAllocations != null) {
      final alloc = apt.clientAllocations!.cast<ClientAllocation?>().firstWhere(
        (a) => a!.clientId == clientId,
        orElse: () => null,
      );
      return alloc?.stunden ?? 0.0;
    }
    return apt.clientId == clientId ? apt.fachleistungsstunden : 0.0;
  }

  /// Mappt TerminArt auf ArbeitszeitTyp für automatische Arbeitszeit-Erstellung
  ArbeitszeitTyp _mapTerminArtToArbeitszeitTyp(TerminArt terminArt) {
    switch (terminArt) {
      case TerminArt.kliententermin:
        return ArbeitszeitTyp.betreuung;
      case TerminArt.buero:
        return ArbeitszeitTyp.buero;
      case TerminArt.dokumentation:
        return ArbeitszeitTyp.dokumentation;
      case TerminArt.supervision:
        return ArbeitszeitTyp.sonstige;
      case TerminArt.teamsitzung:
        return ArbeitszeitTyp.teambesprechung;
      case TerminArt.fortbildung:
        return ArbeitszeitTyp.fortbildung;
      case TerminArt.fahrtzeit:
        return ArbeitszeitTyp.fahrt;
      case TerminArt.sonstige:
        return ArbeitszeitTyp.sonstige;
    }
  }

  List<Appointment> getAppointmentsForDate(DateTime date) {
    return _appointments.where((apt) =>
        apt.date.year == date.year &&
        apt.date.month == date.month &&
        apt.date.day == date.day
    ).toList();
  }

  List<Appointment> searchAppointments(String query) {
    if (query.isEmpty) return _appointments;
    
    final lowerQuery = query.toLowerCase();
    return _appointments.where((apt) =>
        apt.clientName.toLowerCase().contains(lowerQuery) ||
        apt.notes.toLowerCase().contains(lowerQuery) ||
        apt.recordedText.toLowerCase().contains(lowerQuery) ||
        (apt.berufsgruppe?.toLowerCase().contains(lowerQuery) ?? false) ||
        (apt.eingliederung?.toLowerCase().contains(lowerQuery) ?? false)
    ).toList();
  }

  // Settings Methods
  Future<bool> updateSettings(AppSettings newSettings) async {
    try {
      // Optimistic update: apply immediately so UI reacts live
      final oldSettings = _settings;
      _settings = newSettings;
      notifyListeners();

      final success = await _storageService.saveSettings(newSettings);
      if (!success) {
        // Rollback on save failure
        _settings = oldSettings;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Speichern der Einstellungen: $e');
      return false;
    }
  }

  // Arbeitszeit Methods
  Future<bool> addArbeitszeit(Arbeitszeit arbeitszeit) async {
    try {
      final success = await _storageService.addArbeitszeit(arbeitszeit);
      if (success) {
        // In-Memory Update statt Full-Reload
        _arbeitszeiten.add(arbeitszeit);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Hinzufügen der Arbeitszeit: $e');
      return false;
    }
  }

  Future<bool> updateArbeitszeit(Arbeitszeit arbeitszeit) async {
    try {
      // 1. UI sofort aktualisieren (optimistisch)
      final index = _arbeitszeiten.indexWhere((a) => a.id == arbeitszeit.id);
      if (index != -1) {
        _arbeitszeiten[index] = arbeitszeit;
        notifyListeners();
      }

      // 2. Im Hintergrund speichern
      final success = await _storageService.updateArbeitszeit(arbeitszeit);
      if (!success) {
        // Rollback bei Fehler
        await _loadArbeitszeiten();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Arbeitszeit: $e');
      return false;
    }
  }

  Future<bool> deleteArbeitszeit(String id) async {
    try {
      final success = await _storageService.deleteArbeitszeit(id);
      if (success) {
        // In-Memory Update statt Full-Reload
        _arbeitszeiten.removeWhere((a) => a.id == id);
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Löschen der Arbeitszeit: $e');
      return false;
    }
  }

  List<Arbeitszeit> getArbeitszeitenByDateRange(DateTime start, DateTime end) {
    return _arbeitszeiten.where((arbeitszeit) =>
        arbeitszeit.datum.isAfter(start.subtract(const Duration(days: 1))) &&
        arbeitszeit.datum.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  // FLS-Berechnungshilfen
  double getKalkulationsfaktor(Client c) =>
      c.kalkulationsfaktorOverride ?? _settings.kalkulationsfaktor;

  double getStundensatz(Client c) =>
      c.stundensatzOverride ?? _settings.stundensatz;

  double getGesamtarbeitsstunden(Client c) =>
      c.verbrauchteStunden * getKalkulationsfaktor(c);

  double getAbrechnungsbetrag(Client c) {
    if (c.fachleistungsstunden == null) return 0.0;
    final abrechnbar = c.verbrauchteStunden.clamp(0.0, c.fachleistungsstunden!.toDouble());
    return abrechnbar * getStundensatz(c);
  }

  // Stundenverbrauch Tracking
  Future<bool> updateStundenverbrauch(String clientId, double stundenDifferenz) async {
    try {
      final clientIndex = _clients.indexWhere((c) => c.id == clientId);
      if (clientIndex == -1) return false;

      final client = _clients[clientIndex];
      final neuerVerbrauch = (client.verbrauchteStunden + stundenDifferenz)
          .clamp(0.0, client.fachleistungsstunden?.toDouble() ?? double.infinity);
      final updatedClient = client.copyWith(verbrauchteStunden: neuerVerbrauch);

      final success = await _storageService.updateClient(updatedClient);
      if (success) {
        _clients[clientIndex] = updatedClient;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Stundenverbrauchs: $e');
      return false;
    }
  }

  List<Client> getClientsWithHighUsage({double threshold = 0.8}) {
    return _clients.where((client) => 
        client.fachleistungsstunden != null && 
        client.stundenverbrauchProzent / 100 >= threshold
    ).toList();
  }

  // Email Targets Methods
  Future<bool> updateEmailTargets(List<String> emailTargets) async {
    try {
      final success = await _storageService.saveEmailTargets(emailTargets);
      if (success) {
        _emailTargets = emailTargets;
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Speichern der E-Mail-Ziele: $e');
      return false;
    }
  }

  // Username update method
  Future<bool> updateUsername(String username) async {
    try {
      final newSettings = _settings.copyWith(userName: username);
      return await updateSettings(newSettings);
    } catch (e) {
      _setError('Fehler beim Aktualisieren des Benutzernamens: $e');
      return false;
    }
  }

  // Work hours update method
  Future<bool> updateWorkHours(double hours) async {
    try {
      final newSettings = _settings.copyWith(wochenarbeitszeit: hours);
      return await updateSettings(newSettings);
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Arbeitszeit: $e');
      return false;
    }
  }

  // Vacation days update method
  Future<bool> updateVacationDays(int days) async {
    try {
      final newSettings = _settings.copyWith(urlaubstage: days);
      return await updateSettings(newSettings);
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Urlaubstage: $e');
      return false;
    }
  }

  // Work time statistics methods
  double get hoursWorkedToday {
    final today = DateTime.now();
    final todayEntries = _arbeitszeiten.where((entry) =>
        entry.datum.year == today.year &&
        entry.datum.month == today.month &&
        entry.datum.day == today.day
    );
    return todayEntries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  double get hoursWorkedThisWeek {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    
    final weekEntries = _arbeitszeiten.where((entry) =>
        entry.datum.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
        entry.datum.isBefore(endOfWeek.add(const Duration(days: 1)))
    );
    return weekEntries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  double get hoursWorkedThisMonth {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    
    final monthEntries = _arbeitszeiten.where((entry) =>
        entry.datum.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
        entry.datum.isBefore(endOfMonth.add(const Duration(days: 1)))
    );
    return monthEntries.fold(0.0, (sum, entry) => sum + entry.arbeitszeit.inMinutes / 60.0);
  }

  double get overtimeHours {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final currentDay = today.day;
    
    // Calculate expected hours worked so far this month
    final workDaysInMonth = _getWorkDaysInMonth(today.year, today.month, currentDay);
    final dailyTargetHours = _settings.wochenarbeitszeit / 5; // Assuming 5 work days per week
    final expectedHours = workDaysInMonth * dailyTargetHours;
    
    return hoursWorkedThisMonth - expectedHours;
  }

  int _getWorkDaysInMonth(int year, int month, int upToDay) {
    int workDays = 0;
    for (int day = 1; day <= upToDay; day++) {
      final date = DateTime(year, month, day);
      if (date.weekday >= 1 && date.weekday <= 5) { // Monday to Friday
        workDays++;
      }
    }
    return workDays;
  }

  String formatHours(double hours) {
    if (hours == 0) return '0h';
    if (hours >= 0) {
      return '${hours.toStringAsFixed(1)}h';
    } else {
      return '${hours.toStringAsFixed(1)}h'; // Negative hours will show with minus sign
    }
  }

  String formatOvertimeHours(double hours) {
    if (hours == 0) return '0h';
    if (hours > 0) {
      return '+${hours.toStringAsFixed(1)}h';
    } else {
      return '${hours.toStringAsFixed(1)}h'; // Already has minus sign
    }
  }

  // Restore from backup
  Future<bool> restoreFromBackup(dynamic result) async {
    try {
      _setLoading(true);
      
      // Clear existing data first
      await _storageService.clearAllData();
      
      // Restore clients
      if (result.clients != null && result.clients!.isNotEmpty) {
        await _storageService.saveClients(result.clients!);
        AppLogger.info('Backup', '${result.clients!.length} Klienten aus Backup wiederhergestellt');
      }
      
      // Restore appointments
      if (result.appointments != null && result.appointments!.isNotEmpty) {
        await _storageService.saveAppointments(result.appointments!);
        AppLogger.info('Backup', '${result.appointments!.length} Termine aus Backup wiederhergestellt');
      }
      
      // Restore email targets
      if (result.emailTargets != null) {
        await _storageService.saveEmailTargets(result.emailTargets!);
        AppLogger.info('Backup', '${result.emailTargets!.length} E-Mail-Ziele aus Backup wiederhergestellt');
      }
      
      // Restore settings
      if (result.settings != null) {
        await _storageService.saveSettings(result.settings!);
        AppLogger.info('Backup', 'Einstellungen aus Backup wiederhergestellt');
      } else {
        // Save default settings if none in backup
        await _storageService.saveSettings(AppSettings.defaultSettings());
        AppLogger.info('Backup', 'Standard-Einstellungen gesetzt');
      }
      
      // Reload all data
      await _loadAllData();
      _clearError();
      _setLoading(false);
      notifyListeners();
      
      AppLogger.info('Backup', 'Backup-Wiederherstellung erfolgreich abgeschlossen');
      return true;
    } catch (e) {
      AppLogger.error('Backup', 'Fehler beim Wiederherstellen des Backups', e);
      _setError('Fehler beim Wiederherstellen des Backups: $e');
      _setLoading(false);
      return false;
    }
  }

  // Clear all data - setzt die App komplett auf Null zurück
  Future<bool> clearAllData() async {
    try {
      _setLoading(true);
      await _storageService.clearAllData();
      _clients.clear();
      _appointments.clear();
      _arbeitszeiten.clear();
      _mitarbeiter.clear();
      _freizeitAntraege.clear();
      _standorte.clear();
      _fahrwege.clear();
      _streckenCache.clear();
      _emailTargets.clear();
      _currentUser = null;
      // Setup bleibt als abgeschlossen, damit der Assistent nicht erneut startet
      _settings = AppSettings.defaultSettings().copyWith(setupCompleted: true);
      await _storageService.saveSettings(_settings);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_setupCompletedKey, true);
      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('Fehler beim Löschen aller Daten: $e');
      _setLoading(false);
      return false;
    }
  }

  // Utility Methods
  Future<void> refreshData() async {
    _setLoading(true);
    try {
      await _loadAllData();
      _clearError();
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Daten: $e');
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  // Export/Import Methods
  Future<Map<String, dynamic>> exportAllData() async {
    return await _storageService.exportAllData();
  }

  Future<bool> importAllData(Map<String, dynamic> data) async {
    try {
      final success = await _storageService.importAllData(data);
      if (success) {
        await _loadAllData();
        notifyListeners();
      }
      return success;
    } catch (e) {
      _setError('Fehler beim Importieren der Daten: $e');
      return false;
    }
  }

  // Message Methods
  Future<void> syncMessages() async {
    try {
      await _messageService.syncMessages();
      notifyListeners();
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Synchronisieren der Nachrichten', e);
    }
  }

  Future<void> markMessageAsRead(String messageId) async {
    try {
      await _messageService.markAsRead(messageId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Markieren als gelesen', e);
    }
  }

  Future<void> archiveMessage(String messageId) async {
    try {
      await _messageService.archiveMessage(messageId);
      notifyListeners();
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Archivieren', e);
    }
  }

  // Developer Mode: Send test message
  Future<void> sendTestMessage({
    required String title,
    required String body,
    String priority = 'normal',
    String type = 'info',
  }) async {
    try {
      await _messageService.sendTestMessage(
        title: title,
        body: body,
      );
      notifyListeners();
    } catch (e) {
      AppLogger.error('Messages', 'Fehler beim Senden der Test-Nachricht', e);
    }
  }


  // === Standorte ===

  Future<void> _loadStandorte() async {
    _standorte = await _storageService.loadStandorte();
  }

  Future<bool> addStandort(Standort standort) async {
    final success = await _storageService.addStandort(standort);
    if (success) {
      _standorte.add(standort);
      _standorte.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateStandort(Standort standort) async {
    final index = _standorte.indexWhere((s) => s.id == standort.id);
    if (index != -1) {
      _standorte[index] = standort;
      notifyListeners();
    }
    final success = await _storageService.updateStandort(standort);
    if (!success) {
      await _loadStandorte();
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteStandort(String standortId) async {
    final success = await _storageService.deleteStandort(standortId);
    if (success) {
      _standorte.removeWhere((s) => s.id == standortId);
      notifyListeners();
    }
    return success;
  }

  Standort? getStandortById(String id) {
    try {
      return _standorte.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  Standort? getStandortForClient(String clientId) {
    try {
      return _standorte.firstWhere((s) => s.clientId == clientId);
    } catch (_) {
      return null;
    }
  }

  Standort? get bueroStandort {
    final id = _settings.bueroStandortId;
    if (id == null) return null;
    return getStandortById(id);
  }

  // === Fahrwege ===

  Future<void> _loadFahrwege() async {
    _fahrwege = await _storageService.loadFahrwege();
  }

  Future<bool> addFahrweg(Fahrweg fahrweg) async {
    final success = await _storageService.addFahrweg(fahrweg);
    if (success) {
      _fahrwege.add(fahrweg);
      _fahrwege.sort((a, b) => b.datum.compareTo(a.datum));
      _updateStreckenCacheNutzung(fahrweg.startStandortId, fahrweg.zielStandortId);
      notifyListeners();
    }
    return success;
  }

  Future<bool> deleteFahrweg(String fahrwegId) async {
    final success = await _storageService.deleteFahrweg(fahrwegId);
    if (success) {
      _fahrwege.removeWhere((f) => f.id == fahrwegId);
      notifyListeners();
    }
    return success;
  }

  // === StreckenCache ===

  Future<void> _loadStreckenCache() async {
    _streckenCache = await _storageService.loadStreckenCache();
  }

  double? getCachedDistance(String startId, String zielId) {
    try {
      final entry = _streckenCache.firstWhere(
        (s) => s.matchesRoute(startId, zielId),
      );
      return entry.distanzKm;
    } catch (_) {
      return null;
    }
  }

  Future<bool> addStreckenCacheEntry(StreckenCache strecke) async {
    final success = await _storageService.addStreckenCacheEntry(strecke);
    if (success) {
      _streckenCache.add(strecke);
      notifyListeners();
    }
    return success;
  }

  Future<bool> updateStreckenCacheEntry(StreckenCache strecke) async {
    final index = _streckenCache.indexWhere((s) => s.id == strecke.id);
    if (index != -1) {
      _streckenCache[index] = strecke;
    }
    final success = await _storageService.updateStreckenCacheEntry(strecke);
    if (!success) {
      await _loadStreckenCache();
    }
    notifyListeners();
    return success;
  }

  List<StreckenCache> get haeufigsteStrecken {
    final sorted = List<StreckenCache>.from(_streckenCache);
    sorted.sort((a, b) => b.nutzungsAnzahl.compareTo(a.nutzungsAnzahl));
    return sorted;
  }

  void _updateStreckenCacheNutzung(String startId, String zielId) {
    try {
      final entry = _streckenCache.firstWhere(
        (s) => s.matchesRoute(startId, zielId),
      );
      final updated = entry.copyWith(
        nutzungsAnzahl: entry.nutzungsAnzahl + 1,
        zuletztGenutzt: DateTime.now(),
      );
      updateStreckenCacheEntry(updated);
    } catch (_) {
      // Kein Cache-Eintrag vorhanden - ok
    }
  }

  // === Fahrwege-Statistik ===

  double get kmDrivenToday {
    final today = DateTime.now();
    return _fahrwege
        .where((f) =>
            f.datum.year == today.year &&
            f.datum.month == today.month &&
            f.datum.day == today.day)
        .fold(0.0, (sum, f) => sum + f.distanzKm);
  }

  double get kmDrivenThisWeek {
    final today = DateTime.now();
    final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6));
    return _fahrwege
        .where((f) =>
            f.datum.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
            f.datum.isBefore(endOfWeek.add(const Duration(days: 1))))
        .fold(0.0, (sum, f) => sum + f.distanzKm);
  }

  double get kmDrivenThisMonth {
    final today = DateTime.now();
    final startOfMonth = DateTime(today.year, today.month, 1);
    final endOfMonth = DateTime(today.year, today.month + 1, 0);
    return _fahrwege
        .where((f) =>
            f.datum.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
            f.datum.isBefore(endOfMonth.add(const Duration(days: 1))))
        .fold(0.0, (sum, f) => sum + f.distanzKm);
  }

  int get totalFahrwege => _fahrwege.length;

  double get totalKmDriven => _fahrwege.fold(0.0, (sum, f) => sum + f.distanzKm);

  Map<String, double> get kmPerClient {
    final result = <String, double>{};
    for (final f in _fahrwege) {
      if (f.clientId != null) {
        final name = f.zielStandortName;
        result[name] = (result[name] ?? 0.0) + f.distanzKm;
      }
    }
    return result;
  }

  List<Fahrweg> getFahrwegeByDateRange(DateTime start, DateTime end) {
    return _fahrwege
        .where((f) =>
            f.datum.isAfter(start.subtract(const Duration(days: 1))) &&
            f.datum.isBefore(end.add(const Duration(days: 1))))
        .toList();
  }

  // Getter für Services
  SecureStorageService get secureStorageService => _storageService;
  MessageService get messageService => _messageService;
}
